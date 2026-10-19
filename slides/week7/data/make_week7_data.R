# Build the data files used in the Week 7 slides (sources and variable definitions are in README.md).
#
#   CENSUS_API_KEY=<your key> Rscript make_week7_data.R <raw_dir>
#
# Run from this folder. <raw_dir> must contain two downloads (see README.md):
#   cumulative_2006-2025.rds    (CES cumulative file)
#   countypres_2000-2024.tab    (MIT Election Lab county presidential returns)
# The ACS tables are downloaded from the Census API with tidycensus, which needs a free API key.
library(tidyverse)
library(haven)
library(tidycensus)
raw <- commandArgs(trailingOnly = TRUE)[1]

age_cats <- c("18-24", "25-34", "35-44", "45-64", "65+")
educ_cats <- c("HS or less", "Some college", "BA", "Postgrad")

## 1. CES 2016: one row per respondent
ces <- readRDS(file.path(raw, "cumulative_2006-2025.rds")) %>%
  filter(year == 2016) %>%
  mutate(across(where(is.labelled), ~ as.integer(zap_labels(.x)))) %>%
  transmute(case_id, state = st, county_fips,
            female = as.integer(gender == 2),
            age = cut(age, c(17, 24, 34, 44, 64, Inf), labels = age_cats),
            # educ: 1 No HS, 2 HS graduate, 3 Some college, 4 2-year, 5 4-year, 6 Post-grad
            educ = educ_cats[c(1, 1, 2, 2, 3, 4)][educ],
            voted = as.integer(vv_turnout_gvm == "Voted"),  # validated 2016 general election vote record
            # two-party presidential vote, for validated voters only
            clinton = case_when(voted == 1 & voted_pres_16 == "Hilary Clinton" ~ 1L,
                                voted == 1 & voted_pres_16 == "Donald Trump" ~ 0L))
write_csv(ces, "ces2016.csv")

## 2. County presidential returns, 2012 and 2016 (two-party Democratic share)
pres <- read_tsv(file.path(raw, "countypres_2000-2024.tab"), show_col_types = FALSE) %>%
  filter(year %in% c(2012, 2016), state_po != "AK", !is.na(county_fips)) %>%  # Alaska reports by house district
  mutate(county_fips = case_when(county_fips == 2938000 ~ 29095,  # Kansas City (reported separately) -> Jackson County
                                 county_fips == 46113 ~ 46102,    # Shannon County, SD was renamed Oglala Lakota in 2015
                                 county_fips == 51515 ~ 51019,    # Bedford city, VA merged into Bedford County in 2013
                                 .default = county_fips)) %>%
  group_by(year, county_fips) %>%
  summarize(state = state_po[1], dem = sum(candidatevotes[party == "DEMOCRAT"]),
            rep = sum(candidatevotes[party == "REPUBLICAN"]), .groups = "drop") %>%
  mutate(dem_share = dem / (dem + rep), county_fips = str_pad(county_fips, 5, pad = "0")) %>%
  pivot_wider(id_cols = c(county_fips, state), names_from = year, values_from = c(dem, rep, dem_share))
write_csv(pres, "county_pres_2012_2016.csv")

## 3. ACS 2012-2016 5-year, table B15001: sex x age x education among adults, by county
b15001 <- get_acs(geography = "county", table = "B15001", year = 2016, survey = "acs5",
                  key = Sys.getenv("CENSUS_API_KEY"))
# Lines 4-10 are the seven education levels for men 18-24, 12-18 for men 25-34, ..., 77-83 for women 65+
lines <- tibble(line = c(4:10, 12:18, 20:26, 28:34, 36:42, 45:51, 53:59, 61:67, 69:75, 77:83)) %>%
  mutate(female = as.integer(line > 43),
         age = rep(rep(age_cats, each = 7), 2),
         educ = rep(educ_cats[c(1, 1, 1, 2, 2, 3, 4)], 10),
         variable = sprintf("B15001_%03d", line))
frame <- b15001 %>%
  inner_join(lines, by = "variable") %>%
  group_by(county_fips = GEOID, female, age, educ) %>%
  summarize(n = sum(estimate), .groups = "drop") %>%
  mutate(state = fips_codes$state[match(str_sub(county_fips, 1, 2), fips_codes$state_code)]) %>%
  filter(state %in% c(state.abb, "DC"))  # drops Puerto Rico
# the cells should add up to the table total
total <- b15001 %>% filter(variable == "B15001_001")
stopifnot(all(frame %>% group_by(county_fips) %>% summarize(n = sum(n)) %>%
                left_join(total, by = c(county_fips = "GEOID")) %>% with(n == estimate)))
write_csv(frame, "acs2016_county_frame.csv")

## 4. ASPE county estimates of COVID-19 vaccine hesitancy (June 2021), without the boundary polygons
read_csv("https://data.cdc.gov/api/views/q9mh-h2tw/rows.csv?accessType=DOWNLOAD", show_col_types = FALSE) %>%
  transmute(county_fips = str_pad(`FIPS Code`, 5, pad = "0"), state = `State Code`,
            hesitant = `Estimated hesitant`) %>%
  write_csv("aspe_hesitancy_2021.csv")

## 5. State-level predictors: Obama's 2012 two-party share and the share of adults with a 4-year degree
read_tsv(file.path(raw, "countypres_2000-2024.tab"), show_col_types = FALSE) %>%
  filter(year == 2012) %>%  # Alaska included: its house districts add up to the state total
  group_by(state = state_po) %>%
  summarize(obama_2012 = sum(candidatevotes[party == "DEMOCRAT"]) /
              sum(candidatevotes[party %in% c("DEMOCRAT", "REPUBLICAN")])) %>%
  inner_join(frame %>% group_by(state) %>%
               summarize(college_share = sum(n[educ %in% c("BA", "Postgrad")]) / sum(n)), by = "state") %>%
  write_csv("state_predictors.csv")
