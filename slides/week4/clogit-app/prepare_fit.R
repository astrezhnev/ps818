# ---------------------------------------------------------------------------
# Fit the Mazumder and Yan (2024) conditional logit and export what the
# widget needs: the part-worths and their respondent-clustered covariance.
#
# The widget runs in the browser through shinylive, where mlogit and sandwich
# would each be another large wasm download. So the model is fit here, once,
# and the app only does linear algebra on beta-hat and V-hat.
#
# Same specification as the week 4 deck: all 19 attributes as dummies,
# no alternative-specific constant, CR1 variance clustered by respondent.
#
# Run from this folder after rebuilding the data:  Rscript prepare_fit.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({library(dplyr); library(mlogit); library(sandwich)})

cj <- readRDS("../data/mazumder_yan_conjoint.rds") %>%
  mutate(task_id = paste(rid, task, sep = "_"))

# Display names, following the attribute names in the paper's Supplementary
# Tables S10-S11, in the order the widget lists them
labels <- c(governance = "Corporate governance", csr = "Social responsibility", firm_size = "Firm size (co-workers)",
            donations = "Political contributions", gender_owned = "Gender of owners", race_owned = "Race of owners",
            union = "Unionization", training = "Job training program", income = "Salary",
            healthcare = "Health insurance (employer pays)", retirement = "401k matching",
            sick_leave = "Paid sick leave", parental_leave = "Parental leave", hours = "Hours per week",
            location = "Location", remote = "Work from home", work_type = "Type of task",
            teamwork = "Work with others", culture = "Workplace conditions")
stopifnot(setequal(names(labels), names(cj)[5:23]))

cj_idx <- dfidx(cj, idx = list(c("task_id", "rid"), "profile"))
fit <- mlogit(as.formula(paste("chosen ~", paste(names(labels), collapse = " + "), "| 0")), data = cj_idx)
cluster <- idx(cj_idx)$rid[idx(cj_idx)$profile == 1]   # one respondent per task
V <- vcovCL(fit, cluster = cluster)                    # CR1 by default

# One row per level, baselines included with a part-worth of zero. `term` is
# the coefficient name, which is how the app indexes into V.
pw <- bind_rows(lapply(names(labels), function(a) {
  lv <- levels(cj[[a]])
  data.frame(attribute = a, label = unname(labels[a]), level = lv,
             baseline = seq_along(lv) == 1, term = ifelse(seq_along(lv) == 1, "", paste0(a, lv)))
}))
stopifnot(setequal(pw$term[!pw$baseline], names(coef(fit))))
pw$estimate <- ifelse(pw$baseline, 0, coef(fit)[pw$term])
pw$se       <- ifelse(pw$baseline, 0, sqrt(diag(V))[pw$term])

write.csv(pw, "part_worths.csv", row.names = FALSE)
write.csv(signif(V, 8), "vcov.csv")

cat("tasks:", nrow(cj) / 2, " respondents:", length(unique(cluster)),
    " coefficients:", length(coef(fit)), "\n")
