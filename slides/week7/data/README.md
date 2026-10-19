# Week 7 data

All files are built by `make_week7_data.R` (run from this folder; see the top of the script). Downloaded 2026-10-18.

## `ces2016.csv`

One row per respondent (64,600) in the 2016 Cooperative Congressional Election Study (CCES, now the CES).

- **Source:** the 2016 rows of the *Cumulative CES Common Content*, version 12 (Kuriwaki,
  <https://doi.org/10.7910/DVN/II2DB6>, file `cumulative_2006-2025.rds`), which harmonizes the yearly CES files. The
  original 2016 release is Ansolabehere and Schaffner, *CCES Common Content, 2016*, <https://doi.org/10.7910/DVN/GDF6Z0>.
- **Documentation:** the cumulative file's guide (`guide_cumulative_2006-2025.pdf` in the same Dataverse record).
- **Variables:**
  - `case_id`: respondent ID.
  - `state`: two-letter state of residence (`st`).
  - `county_fips`: five-digit county of residence (`county_fips`; the guide says it is imputed from the respondent's
    zip code). Missing for 84 respondents.
  - `female`: 1 if `gender` is Female, 0 if Male.
  - `age`: `age` (age at the time of the survey) cut into 18-24, 25-34, 35-44, 45-64, 65+, the brackets of ACS table B15001.
  - `educ`: `educ` collapsed to four categories: "HS or less" (No HS, High School Graduate), "Some college"
    (Some College, 2-Year), "BA" (4-Year), "Postgrad" (Post-Grad).
  - `voted`: 1 if `vv_turnout_gvm` is "Voted", i.e. the respondent was matched to a 2016 general election vote record in
    the voter file; 0 otherwise ("No Record of Voting" includes respondents who could not be matched).
  - `clinton`: for validated voters (`voted == 1`) who reported voting for Clinton or Trump in the post-election wave
    (`voted_pres_16`), 1 = Clinton, 0 = Trump. Missing for everyone else. 28,462 respondents have a value.

## `county_pres_2012_2016.csv`

One row per county (3,112) with presidential returns in 2012 and 2016.

- **Source:** MIT Election Data and Science Lab, *County Presidential Election Returns 2000-2024*,
  <https://doi.org/10.7910/DVN/VOQCHQ> (file `countypres_2000-2024.tab`; downloading it requires filling out the
  Dataverse guestbook).
- **Variables:** `dem_2012`, `rep_2012`, `dem_2016`, `rep_2016` are the Democratic and Republican candidates' votes
  (`candidatevotes` for `party` DEMOCRAT and REPUBLICAN). `dem_share_2012` and `dem_share_2016` are the Democratic share
  of the two-party vote, `dem / (dem + rep)`.
- **Changes to the source:**
  - Alaska is dropped: it reports results by state house district, not by borough.
  - Kansas City, MO is reported separately from its counties (code 2938000); its votes are added to Jackson County (29095).
    (The Kansas City election board covers the part of the city in Jackson County.)
  - Shannon County, SD (46113) was renamed Oglala Lakota County (46102) in 2015, and Bedford city, VA (51515) merged into
    Bedford County (51019) in 2013. Both are recoded to their current codes so the two years line up and match the ACS.

## `acs2016_county_frame.csv`

The post-stratification frame: the number of adults in each county by sex, age and education.

- **Source:** American Community Survey 2012-2016 5-year estimates, table B15001 ("Sex by Age by Educational
  Attainment for the Population 18 Years and Over"), downloaded from the Census API with `tidycensus`.
- **Variables:** `county_fips`, `state`, `female` (0/1), `age` (the table's five brackets), `educ` (the table's seven
  levels collapsed to the same four categories as the CES: less than 9th grade, 9th-12th grade with no diploma and high
  school graduate are "HS or less"; some college and associate's degree are "Some college"; bachelor's degree is "BA";
  graduate or professional degree is "Postgrad"), and `n`, the estimated number of adults. 3,142 counties (50 states
  and DC); the cells add up to each county's B15001 total.

## `state_predictors.csv`

One row per state (50 and DC) with the two state-level predictors used in the multilevel models.

- `obama_2012`: Obama's share of the two-party vote in 2012, `dem / (dem + rep)` summed over all of the state's rows
  in the MIT county returns (above). Alaska is included here: its house-district rows add up to the state total.
- `college_share`: the share of adults with a bachelor's degree or more ("BA" or "Postgrad"), from the ACS frame above.

## `aspe_hesitancy_2021.csv`

County estimates of COVID-19 vaccine hesitancy published by the Office of the Assistant Secretary for Planning and
Evaluation (ASPE), HHS, in June 2021.

- **Source:** *Vaccine Hesitancy for COVID-19: County and local estimates*, <https://data.cdc.gov/d/q9mh-h2tw>;
  methodology at <https://aspe.hhs.gov/reports/vaccine-hesitancy-covid-19-state-county-local-estimates>.
- **Variables:** `county_fips`, `state`, and `hesitant` ("Estimated hesitant": the estimated share of adults who
  would "probably not" or "definitely not" get a COVID-19 vaccine).
- **How ASPE made the estimates:** a logistic regression of hesitancy in the Household Pulse Survey (May 26 - June 7,
  2021) on age, gender, race/ethnicity, education, marital status, health insurance, household income, state of
  residence and race/ethnicity x college interactions, applied to each adult in the 2019 ACS 1-year microdata
  and averaged within PUMAs, which were then apportioned to counties by 2010 population.
