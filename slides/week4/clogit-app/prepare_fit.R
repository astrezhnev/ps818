# ---------------------------------------------------------------------------
# Fit the Mazumder and Yan (2024) conditional logit and export what the
# widget needs: the part-worths and their respondent-clustered covariance.
#
# The widget runs in the browser through shinylive, where mlogit and sandwich
# would each be another large wasm download. So the model is fit here, once,
# and the app only does linear algebra on beta-hat and V-hat.
#
# Same specification as the week 4 deck's salary slide: 18 attributes as
# dummies plus log(salary) in place of the 27 noisy salary dummies (it fits
# them just as well), no alternative-specific constant, CR1 variance
# clustered by respondent.
#
# Run from this folder after rebuilding the data:  Rscript prepare_fit.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({library(dplyr); library(mlogit); library(sandwich)})

cj <- readRDS("../data/mazumder_yan_conjoint.rds") %>%
  mutate(task_id = paste(rid, task, sep = "_"),
         log_salary = log(as.numeric(gsub("[^0-9]", "", income))))   # salary in $1,000s

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
covariates <- c(setdiff(names(labels), "income"), "log_salary")
fit <- mlogit(as.formula(paste("chosen ~", paste(covariates, collapse = " + "), "| 0")), data = cj_idx)
cluster <- idx(cj_idx)$rid[idx(cj_idx)$profile == 1]   # one respondent per task
V <- vcovCL(fit, cluster = cluster)                    # CR1 by default

# One row per level. A level contributes `value` to the coefficient named
# `term` (which is how the app indexes into beta-hat and V-hat): a dummy level
# is 1 on its own term, a baseline has no term, and every salary level loads on
# the single log_salary term with value log(salary).
pw <- bind_rows(lapply(names(labels), function(a) {
  lv <- levels(cj[[a]])
  if (a == "income") {
    return(data.frame(attribute = a, label = unname(labels[a]), level = lv, term = "log_salary",
                      value = log(as.numeric(gsub("[^0-9]", "", lv)))))
  }
  data.frame(attribute = a, label = unname(labels[a]), level = lv,
             term = ifelse(seq_along(lv) == 1, "", paste0(a, lv)), value = ifelse(seq_along(lv) == 1, 0, 1))
}))
stopifnot(setequal(unique(pw$term[pw$term != ""]), names(coef(fit))))
pw$coef <- ifelse(pw$term == "", 0, coef(fit)[pw$term])

write.csv(pw, "part_worths.csv", row.names = FALSE)
write.csv(signif(V, 8), "vcov.csv")

cat("tasks:", nrow(cj) / 2, " respondents:", length(unique(cluster)),
    " coefficients:", length(coef(fit)), "\n")
