# Build the Wisconsin municipal boundary file used for the maps in the Week 5 slides.
#
# Downloads the Census Bureau's 2022 cartographic boundary file of county subdivisions for Wisconsin
# (state FIPS 55). In Wisconsin these are the cities, villages and towns -- the same units that report
# to the EAVS. Keeps the identifiers we need and writes  wi_municipalities_2022.gpkg
# Sources are documented in README.md. Run from this folder: Rscript make_wi_map.R

library(sf)
library(tidyverse)

url <- "https://www2.census.gov/geo/tiger/GENZ2022/shp/cb_2022_55_cousub_500k.zip"
zip <- tempfile(fileext = ".zip")
download.file(url, zip, mode = "wb")
shp <- unzip(zip, exdir = tempdir())

st_read(shp[grepl("\\.shp$", shp)], quiet = TRUE) %>%
  select(COUNTYFP, NAMELSADCO, COUSUBFP, NAMELSAD) %>%
  st_write("wi_municipalities_2022.gpkg", delete_dsn = TRUE, quiet = TRUE)
