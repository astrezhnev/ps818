# Conditional logit prediction widget (week 4)

An R Shiny app for the Mazumder and Yan (2024) workplace-democracy conjoint.
Build two hypothetical jobs from the 19 randomized attributes and see the
conditional logit's predicted probability that a respondent picks Job A over
Job B, with a 95% confidence interval. Comparisons can be saved and plotted
side by side.

It runs **in the browser** through [shinylive](https://posit-dev.github.io/r-shinylive/),
compiled to WebAssembly, so it works on the static course site.

## Files

| File | Role |
| --- | --- |
| `app.R` | The app itself. **Edit this.** |
| `prepare_fit.R` | Fits the conditional logit with `mlogit` and writes `part_worths.csv` and `vcov.csv`. |
| `part_worths.csv` | One row per attribute level: label, coefficient (0 for baselines) and clustered SE. |
| `vcov.csv` | Respondent-clustered (CR1) covariance of the 73 coefficients. |
| `build_app_qmd.R` | Regenerates `../clogit_app.qmd` from `app.R` and the two CSVs. |

The model is fit once in `prepare_fit.R` rather than in the app because
`mlogit` and `sandwich` would each be another large WebAssembly download. The
app only needs β̂ and V̂:

- Pr(A over B) = logistic((x_A − x_B)′β̂)
- The CI is the delta method on the log-odds scale, mapped through the
  logistic function.

The specification is the same as the week 4 deck's: all 19 attributes as
dummies, no alternative-specific constant, clustered by respondent.

## Workflow

After rebuilding the data (`../data/prepare_mazumder_yan.R`) or editing the app:

```sh
Rscript prepare_fit.R        # only if the data or the model changed
Rscript build_app_qmd.R
quarto render ../clogit_app.qmd
```

`clogit_app.qmd` is **generated**, so don't edit it by hand. Shinylive has no
filesystem, so the app and its data are inlined into that page as `## file:`
blocks.

The week 4 deck frames the rendered page in an `<iframe>` on the
`{.app-slide}` slide. So the widget only appears when the deck is served from
the site (or `quarto preview`), not when the deck's `.html` is opened on its own.
