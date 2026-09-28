# ---------------------------------------------------------------------------
# Build the Mazumder and Yan (2024) conjoint extract used in the week 4 deck
# and the conditional logit widget.
#
# Source: the cleaned YouGov conjoint from the authors' APSR replication
# archive (01-yougov-conjoint/01-data/cleaned/yougov-conjoint-cleaned.rds).
# Point `src` at your copy of that file and run from this folder:
#
#   Rscript prepare_mazumder_yan.R
#
# Writes mazumder_yan_conjoint.rds: one row per respondent-task-profile, the
# 19 randomized job attributes, and the choice indicator. Tasks where the
# respondent picked neither job are dropped, as in the replication.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(dplyr))

src <- "~/Documents/Research/cjoint_replication/Replication/data/mazumder_yan_2024/yougov-conjoint-cleaned.rds"
raw <- readRDS(path.expand(src))

# Readable attribute names, in the order the deck and the widget show them:
# the firm first, then the job.
attributes <- c(
  cje_corporate_gov       = "governance",
  cje_corporate_resp      = "csr",
  cje_firm_size           = "firm_size",
  cje_political_donations = "donations",
  cje_gender_ownership    = "gender_owned",
  cje_race_ownership      = "race_owned",
  cje_union               = "union",
  cje_training            = "training",
  cje_income              = "income",
  cje_healthcare          = "healthcare",
  cje_retirement          = "retirement",
  cje_sick_leave          = "sick_leave",
  cje_parental_leave      = "parental_leave",
  cje_hours               = "hours",
  cje_location            = "location",
  cje_work_from_home      = "remote",
  cje_type_of_work        = "work_type",
  cje_team_work           = "teamwork",
  cje_work_culture        = "culture"
)

# The rows come in task order, two profiles per task.
conjoint <- raw %>%
  arrange(rid, cje_trial) %>%
  mutate(profile = rep(1:2, n() / 2)) %>%
  select(rid, task = cje_trial, profile, chosen = work_binary, all_of(names(attributes))) %>%
  rename(!!!setNames(names(attributes), attributes)) %>%
  group_by(rid, task) %>%
  filter(sum(chosen) == 1) %>%
  ungroup()

# Baselines: the least worker-friendly option where the attribute has an
# obvious one. Governance follows the paper (private, non-worker shareholders);
# training uses "no program" rather than the alphabetically first program.
conjoint <- conjoint %>%
  mutate(governance = relevel(governance, "Privately owned by non-worker shareholders"),
         training   = relevel(training, "No special job training program"),
         chosen     = as.integer(chosen),
         rid        = as.integer(factor(rid)))

# Short level labels for plots and the widget's dropdowns, matched by the
# original wording and listed in each factor's level order.
short <- list(
  governance = c("Privately owned by one individual" = "Private, one owner",
                 "Privately owned by non-worker shareholders" = "Private, non-worker shareholders",
                 "Publicly owned by shareholders" = "Public, shareholders",
                 "Workers are shareholders" = "Workers are shareholders",
                 "Workers sit on the corporate board" = "Workers on the board",
                 "Workers elect their managers" = "Workers elect managers"),
  csr = c("No corporate social responsibility" = "No CSR commitment",
          "Commitment to corporate social responsibility" = "CSR commitment"),
  firm_size = c("50 co-workers" = "50", "250 co-workers" = "250", "500 co-workers" = "500",
                "1,000 co-workers" = "1,000", "5,000 co-workers" = "5,000"),
  donations = c("Donates to both Democrats and Republicans" = "Both parties",
                "Primarily donates to Democrats" = "Mostly Democrats",
                "Primarily donates to Republicans" = "Mostly Republicans"),
  gender_owned = c("Men owned" = "Men", "Majority-men owned" = "Majority men",
                   "Majority-women owned" = "Majority women", "Women owned" = "Women"),
  race_owned = c("All white owned" = "All white", "Majority white owned" = "Majority white",
                 "Majority people of color owned" = "Majority people of color",
                 "All people of color owned" = "All people of color"),
  union = c("Not unionized" = "Not unionized", "Unionized" = "Unionized"),
  training = c("No special job training program" = "None", "Ex-felons training" = "Ex-felons",
               "Veterans training" = "Veterans", "Mentally-disabled training" = "Mentally disabled"),
  income = setNames(paste0("$", seq(30, 300, 10), "k"),
                    paste0("$", formatC(seq(30, 300, 10) * 1000, big.mark = ",", format = "d"), " per year")),
  healthcare = c("Employer pays 50%" = "50%", "Employer pays 75%" = "75%", "Employer pays 100%" = "100%"),
  retirement = setNames(paste0(c(0, 25, 50, 75, 100), "%"),
                        paste0("Matches ", c(0, 25, 50, 75, 100), "% of 401k contributions")),
  sick_leave = c("No paid sick leave" = "None", "Two weeks paid sick leave days" = "Two weeks",
                 "Unlimited paid sick leave days" = "Unlimited"),
  parental_leave = c("No parental leave policy" = "None", "Generous parental leave policy" = "Generous"),
  hours = setNames(as.character(seq(40, 80, 10)), paste(seq(40, 80, 10), "hours")),
  location = c("Located in your city" = "Your city", "Located in a different city" = "Different city",
               "Located in a different city but pays for relocation" = "Different city, pays to relocate"),
  remote = c("Cannot work from home" = "Never", "Sometimes work from home" = "Sometimes",
             "Primarily works from home" = "Primarily"),
  work_type = c("Largely repetitive work" = "Repetitive", "Mix of repetitive and creative work" = "Mix",
                "Largely creative work" = "Creative"),
  teamwork = c("Mostly working alone" = "Mostly alone", "Mix of individual and team work" = "Mix",
               "Mostly team work" = "Mostly team"),
  culture = c("Generally unfriendly and unsupportive" = "Generally unfriendly",
              "Somewhat unfriendly and unsupportive" = "Somewhat unfriendly",
              "Somewhat friendly and supportive" = "Somewhat friendly",
              "Generally friendly and supportive" = "Generally friendly")
)
stopifnot(identical(sort(names(short)), sort(unname(attributes))))
for (a in names(short)) {
  stopifnot(setequal(levels(conjoint[[a]]), names(short[[a]])))
  levels(conjoint[[a]]) <- unname(short[[a]][levels(conjoint[[a]])])
}

stopifnot(all(table(conjoint$rid, conjoint$task)[] %in% c(0, 2)))
saveRDS(conjoint, "mazumder_yan_conjoint.rds")

cat("respondents:", n_distinct(conjoint$rid),
    " tasks:", nrow(conjoint) / 2,
    " attributes:", length(attributes), "\n")
