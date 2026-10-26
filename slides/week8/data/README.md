# Week 8 data

## `CCES23_Common_OUTPUT.dta.gz`

The 2023 Cooperative Election Study Common Content, unmodified apart from gzip compression: 24,500 respondents,
320 variables. `haven::read_dta()` reads the `.gz` file directly, and the slides do all of the recoding.

- **Source:** Schaffner, Ansolabehere, Pope, and Shih, *CES Common Content, 2023*, version 2,
  <https://doi.org/10.7910/DVN/JQJTCC>. Downloaded in its original Stata format (Dataverse file 10164312,
  `CCES23_Common_OUTPUT.dta`; the `.tab` version on Dataverse drops the value labels) and compressed with `gzip -9`.
- **Documentation:** `CES 2023 CC Questionnaire.pdf` (Dataverse file 11035458) has the full wording of every item.
- **Policy items used in the slides:** the 24 "support/oppose" questions in `CC23_321`--`CC23_328` (guns and
  policing, immigration, abortion, the environment, and social welfare), coded `1` = Support, `2` = Oppose,
  `8` = skipped, `9` = not asked.

To re-download:

```sh
curl -L -o CCES23_Common_OUTPUT.dta "https://dataverse.harvard.edu/api/access/datafile/10164312?format=original"
gzip -9 CCES23_Common_OUTPUT.dta
```
