# Week 6 data

## `eavs_2022_wi.csv`

The Wisconsin extract of the 2022 EAVS from Week 5, copied here unchanged. The logistic regression uses each
municipality's 2022 discretionary rejection rate, `100 * (C9a - C9b - C9m) / (C1b - C9b - C9m)` (in percentage points),
as the predictor of its 2024 rejections. The two years are joined on `FIPSCode`. The 2022 file lists the Village of
Greenville (Outagamie County) under 31550, the old Town of Greenville's code, so the slides recode it to 31525 to match
2024 (see the Week 5 README). 1,832 municipalities have returned ballots in both years.

## `eavs_2024_wi.csv`

The same Wisconsin extract of the EAC's 2024 *Election Administration and Voting Survey* (EAVS) used in Week 5,
copied here unchanged so this folder runs on its own. One row per municipality (1,851) with its mail (absentee)
ballot counts for the November 2024 general election.

See [`../../week5/data/README.md`](../../week5/data/README.md) for the source, the script that builds the file
(`make_eavs_wi.R`), the codebook and questionnaire links, and the variable definitions. The slides use the same
**discretionary rejection** counts as Week 5:

- `n = C1b - C9b - C9m`: mail ballots returned on time by living voters
- `y = C9a - C9b - C9m`: of those, the number rejected
