# Week 5 data

## Absentee ballot application (Beta-Binomial)

### `eavs_2022_wi.csv` and `eavs_2024_wi.csv`

Mail (absentee) ballots by Wisconsin municipality for the November 2024 general election (the main analysis) and the
November 2022 general election (used to check the out-of-sample predictions).
Wisconsin runs elections at the municipal level, so its EAVS data have one row per municipality (1,851 in each year).

- **Source:** U.S. Election Assistance Commission (EAC), *Election Administration and Voting Survey* (EAVS),
  public release V1 for 2022 and 2024, from <https://www.eac.gov/research-and-data/datasets-codebooks-and-surveys>.
  - 2022: <https://www.eac.gov/sites/default/files/2023-06/2022_EAVS_for_Public_Release_nolabel_V1_CSV.zip>
  - 2024: <https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_for_Public_Release_nolabel_V1_csv.zip>
- **How these files were made:** `make_eavs_wi.R` downloads the national files and keeps the Wisconsin rows and
  the columns below, with values unchanged. (The national CSVs are 35-41 MB, too large to keep in the repo.)
  Downloaded 2026-10-04.
- **Documentation:**
  - 2024 codebook: <https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_Codebook.xlsx>
  - 2022 has no separate codebook. Its variable labels are in the labeled Stata release
    (<https://www.eac.gov/sites/default/files/2023-06/2022_EAVS_for_Public_Release_V1_DTA.zip>).
  - Survey questionnaires (exact question wording):
    2022 <https://www.eac.gov/sites/default/files/EAVS%202022/2022_EAVS_FINAL_508c.pdf>,
    2024 <https://www.eac.gov/sites/default/files/2024-04/2024_EAVS_FINAL_508c.pdf>
  - Instructions, including special codes: <https://www.eac.gov/sites/default/files/EAVS%202022/EAVS_Guide_2022_Updates_508c.pdf>
- **Variables** (labels from the codebook and the labeled 2022 release; definitions from the questionnaires):
  - `FIPSCode`, `Jurisdiction_Name`, `State_Abbr`: jurisdiction identifiers. For Wisconsin, `Jurisdiction_Name`
    is the municipality and its county (e.g. "TOWN OF CLEVELAND - TAYLOR COUNTY"); municipalities that span
    counties say "MULTIPLE COUNTIES."
  - `C1a` "Mail Transmitted Total": all mail ballots sent to voters.
  - `C1b` "Mail Returned By Voters Total": mail ballots returned by voters, "both counted and rejected."
  - `C8a`: mail ballots returned and counted.
  - `C9a` "Mail Rejected Total": mail ballots "returned by voters and ... rejected," for any reason.
  - `C9b` "Mail Ballots Rejected Because Late" and `C9m` "Mail Ballots Rejected Because Voter Deceased": two of the
    reasons `C9a` is broken into (C9b-C9t; see the 2024 codebook). Wisconsin's comment in the EAVS notes that late
    ballots are "not counted nor formally rejected in WI" but are included in `C9a` and `C9b`.
  - In both years, `C8a + C9a = C1b` for every Wisconsin municipality.
- **Special codes:** EAVS uses negative values for nonresponse: -88 = "Does not apply," -99 = "Data not available"
  (EAVS Guide). The Wisconsin extracts contain none.
- **Discretionary rejection rate (what the slides use):** `(C9a - C9b - C9m) / (C1b - C9b - C9m)`, i.e.
  rejections other than late ballots and deceased voters, out of ballots returned on time by living voters. Statewide
  it is 0.21% in 2024 (1,196 of 573,630) and 0.52% in 2022, so the slides scale 2024-based predictions up by
  the ratio (about 2.5) before scoring them against 2022. In Wisconsin most of what remains is the state's
  "certification insufficient" category (`C9s`, not included in the extracts), which covers missing voter or witness
  signatures and missing addresses.
- **Overall rejection rate:** `C9a / C1b`, the definition the EAC uses in its state data briefs. Statewide it is
  0.92% in 2022 (3,986 of 431,232) and 0.49% in 2024 (2,823 of 575,257). The 2022 figures match the EAC's
  Wisconsin data brief
  (<https://www.eac.gov/sites/default/files/2023-10/2022_EAVS_Data_Brief_WI_508c.pdf>).
- **Cite:** U.S. Election Assistance Commission. 2023. *Election Administration and Voting Survey 2022*
  (public release dataset, V1); U.S. Election Assistance Commission. 2025. *Election Administration and Voting
  Survey 2024* (public release dataset, V1).

### `wi_municipalities_2024.gpkg`

Boundaries of Wisconsin's municipalities, for the maps.

- **Source:** U.S. Census Bureau, *2024 Cartographic Boundary File, County Subdivision for Wisconsin, 1:500,000*
  (`cb_2024_55_cousub_500k`, published May 2025), from
  <https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_55_cousub_500k.zip>.
  Overview of the files: <https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html>
- **How this file was made:** `make_wi_map.R` downloads the zip, keeps four columns, and writes a GeoPackage.
  Geometries are unchanged. Downloaded 2026-10-04.
- **What the polygons are:** the metadata that ships with the file describes county subdivisions as "legally-recognized minor civil
  divisions (MCDs)," with boundaries "as of January 1, 2024, as reported through the Census Bureau's Boundary
  and Annexation Survey." In Wisconsin the MCDs are the cities, villages and towns. Cartographic boundary files
  are generalized and clipped to the shoreline.
- **Variables:** `COUNTYFP` and `NAMELSADCO` (county), `COUSUBFP` (5-digit county subdivision code), `NAMELSAD`
  (e.g. "Mequon city"). A municipality that spans counties has one polygon per county, all with the same `COUSUBFP`.
- **Matching to the EAVS:** for Wisconsin, the EAVS `FIPSCode` *is* the Census `COUSUBFP`. 1,848 of the 1,851
  municipalities in the 2024 extract match, and the names agree apart from spelling (e.g. "MT. STERLING" vs.
  "Mount Sterling"). The three without a polygon are the Village of Greenleaf (Brown County; 35 ballots), and the
  Towns of Lisbon and Rib Mountain (0 ballots each), all of which appear to postdate the January 1, 2024 boundaries.
- **A quirk in the 2022 EAVS:** it files the Village of Greenville (Outagamie County) under code 31550, which belongs
  to the old Town of Greenville; the 2024 EAVS and the Census file use the village's own code, 31525. This only
  matters when joining 2022 to 2024 (the village has too many ballots to be in the slides' out-of-sample check).
