# Build the Wisconsin extracts of the EAVS used in the Week 5 slides.
#
# Downloads the EAC's public-release CSVs for 2022 and 2024, keeps the Wisconsin rows
# (Wisconsin reports by municipality) and the mail-ballot columns we need, and writes
#   eavs_2022_wi.csv  and  eavs_2024_wi.csv
# Variable definitions are in README.md. Run from this folder: Rscript make_eavs_wi.R

library(tidyverse)

files <- c(
  `2022` = "https://www.eac.gov/sites/default/files/2023-06/2022_EAVS_for_Public_Release_nolabel_V1_CSV.zip",
  `2024` = "https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_for_Public_Release_nolabel_V1_csv.zip"
)

for (yr in names(files)) {
  zip <- tempfile(fileext = ".zip")
  download.file(files[[yr]], zip, mode = "wb")
  csv <- unzip(zip, exdir = tempdir())
  csv <- csv[grepl("\\.csv$", csv)]
  read_csv(csv, col_types = cols(.default = col_character())) %>%
    filter(State_Abbr == "WI") %>%
    select(FIPSCode, Jurisdiction_Name, State_Abbr, C1a, C1b, C8a, C9a) %>%
    write_csv(paste0("eavs_", yr, "_wi.csv"))
}
