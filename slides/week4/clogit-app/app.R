# ---------------------------------------------------------------------------
# Predicted choice probabilities from the Mazumder and Yan (2024) conditional
# logit.
#
# Build two hypothetical jobs, A and B, from the 19 randomized attributes. The
# model's probability that a respondent picks A is
#
#   Pr(A over B) = logistic((x_A - x_B)' beta)
#
# Salary enters as log(salary) rather than as 27 dummies; the other 18
# attributes are dummies.
#
# with a 95% CI from the delta method on the log-odds scale, using the
# respondent-clustered (CR1) covariance of beta-hat, mapped through the
# logistic function.
#
# beta-hat and V-hat come from prepare_fit.R. Deliberately base R + shiny
# only: every extra package is another wasm download when this runs in the
# browser through shinylive.
# ---------------------------------------------------------------------------

library(shiny)

pw <- read.csv("part_worths.csv", stringsAsFactors = FALSE)
V  <- as.matrix(read.csv("vcov.csv", row.names = 1, check.names = FALSE))
has_term <- pw$term != ""
beta  <- tapply(pw$coef[has_term], pw$term[has_term], `[`, 1)[rownames(V)]
ATTRS <- unique(pw$attribute)
LABEL <- setNames(pw$label[!duplicated(pw$attribute)], ATTRS)
LEVELS <- lapply(setNames(ATTRS, ATTRS), function(a) pw$level[pw$attribute == a])

RED <- "#c5050c"; BLUE <- "#0479A8"

# Starting point: two otherwise identical mid-range jobs that differ only in
# governance, so the first number on screen is a governance effect.
DEFAULT <- setNames(vapply(ATTRS, function(a) LEVELS[[a]][1], ""), ATTRS)
DEFAULT[c("income", "healthcare", "retirement", "sick_leave", "hours", "culture")] <-
  c("$70k", "75%", "50%", "Two weeks", "40", "Somewhat friendly")
START_A <- replace(DEFAULT, "governance", "Workers on the board")
START_B <- DEFAULT

# Each attribute level adds `value` to coefficient `term` (baselines add nothing)
LOOKUP <- split(pw[, c("term", "value")], paste(pw$attribute, pw$level, sep = "\r"))

# Difference in design vectors, x_A - x_B
x_diff <- function(a, b) {
  d <- setNames(numeric(length(beta)), names(beta))
  for (at in ATTRS) {
    if (a[[at]] == b[[at]]) next
    la <- LOOKUP[[paste(at, a[[at]], sep = "\r")]]; lb <- LOOKUP[[paste(at, b[[at]], sep = "\r")]]
    if (nzchar(la$term)) d[la$term] <- d[la$term] + la$value
    if (nzchar(lb$term)) d[lb$term] <- d[lb$term] - lb$value
  }
  d
}

predict_ab <- function(a, b) {
  d  <- x_diff(a, b)
  lo <- sum(d * beta)
  se <- sqrt(drop(t(d) %*% V %*% d))
  list(p = plogis(lo), lo = plogis(lo - 1.96 * se), hi = plogis(lo + 1.96 * se),
       logodds = lo, se = se)
}

# "Salary: $70k vs $40k; Weekly hours: 40 vs 60", or "identical" if nothing differs
describe <- function(a, b) {
  diff <- ATTRS[vapply(ATTRS, function(at) a[[at]] != b[[at]], TRUE)]
  if (!length(diff)) return("Identical jobs")
  paste(vapply(diff, function(at) sprintf("%s: %s vs %s", LABEL[[at]], a[[at]], b[[at]]), ""),
        collapse = "; ")
}

css <- "
@import url('https://fonts.googleapis.com/css2?family=Red+Hat+Display:wght@400;700&family=Red+Hat+Text:wght@400;500;700&display=swap');
html, body { height:100%; }
body { font-family:'Red Hat Text',system-ui,sans-serif; background:#F7F7F7; color:#333;
       margin:0; padding:10px; font-size:13px; box-sizing:border-box; overflow:hidden; }
h4 { font-family:'Red Hat Display',system-ui,sans-serif; margin:0 0 3px 0; font-size:16px; }
body > .container-fluid { height:100%; padding:0; }
.wrap { display:flex; gap:12px; height:100%; }
.card { background:#fff; border:1px solid #e2e2e2; border-radius:8px; padding:10px 12px;
        box-sizing:border-box; display:flex; flex-direction:column; min-width:0; }
.builder { flex:0 0 545px; }
.results { flex:1 1 0; }
.grid { display:grid; grid-template-columns: 160px 1fr 1fr; column-gap:6px; row-gap:1px;
        align-items:center; overflow-y:auto; flex:1 1 auto; min-height:0; }
.grid .hd { font-family:'Red Hat Display',sans-serif; font-weight:700; font-size:13px;
            padding-bottom:2px; border-bottom:1px solid #e2e2e2; }
.grid .hd.a { color:#c5050c; } .grid .hd.b { color:#0479A8; }
.grid .lab { font-size:12px; color:#555; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;
             padding-left:5px; border-left:3px solid transparent; }
.grid .lab.diff { color:#333; font-weight:700; border-left-color:#C77400; }
.grid .form-group { margin:0; }
.grid select.form-control { height:22px; padding:0 4px; font-size:12px; border-radius:4px; }
.btns { display:flex; gap:6px; margin-top:6px; flex:none; }
.btns .btn { font-size:12px; padding:3px 9px; border-radius:4px; }
.now { flex:none; border-bottom:1px solid #e2e2e2; padding-bottom:8px; margin-bottom:6px; }
.now .big { font-family:'Red Hat Display',sans-serif; font-size:30px; font-weight:700; color:#333; }
.now .ci { font-size:15px; color:#555; margin-left:6px; }
.now .sub { font-size:12px; color:#777; margin-top:2px; }
.now .what { font-size:12px; color:#333; margin-top:4px; max-height:52px; overflow-y:auto; }
.plotbox { flex:1 1 auto; min-height:0; }
.note { flex:none; font-size:11px; color:#888; margin-top:4px; }
"

# Shade the label of every attribute on which the two jobs differ. Sent from
# the server so it also tracks the Copy and Swap buttons.
js <- "
Shiny.addCustomMessageHandler('diffs', function(on) {
  document.querySelectorAll('.grid .lab').forEach(function (el) {
    el.classList.toggle('diff', on.indexOf(el.dataset.attr) >= 0);
  });
});
"

row_ui <- function(a) {
  tagList(
    div(class = "lab", `data-attr` = a, title = LABEL[[a]], LABEL[[a]]),
    selectInput(paste0("A_", a), NULL, LEVELS[[a]], START_A[[a]], selectize = FALSE, width = "100%"),
    selectInput(paste0("B_", a), NULL, LEVELS[[a]], START_B[[a]], selectize = FALSE, width = "100%")
  )
}

ui <- fluidPage(
  tags$head(tags$style(HTML(css)), tags$script(HTML(js))),
  div(class = "wrap",
    div(class = "card builder",
      h4("Build two jobs"),
      div(class = "grid",
        div(class = "hd", "Attribute"), div(class = "hd a", "Job A"), div(class = "hd b", "Job B"),
        lapply(ATTRS, row_ui)
      ),
      div(class = "btns",
        actionButton("copy", "Copy A to B"),
        actionButton("swap", "Swap A and B")
      )
    ),
    div(class = "card results",
      uiOutput("now", class = "now"),
      div(class = "plotbox", plotOutput("plot", height = "100%")),
      div(class = "note",
          "95% CIs: delta method on the log-odds scale, respondent-clustered (CR1) covariance. ",
          "Conditional logit (salary as log salary) fit to 3,886 tasks from 993 respondents.")
    )
  )
)

server <- function(input, output, session) {
  job <- function(side) reactive(setNames(
    vapply(ATTRS, function(a) { v <- input[[paste0(side, "_", a)]]; if (is.null(v)) "" else v }, ""), ATTRS))
  jobA <- job("A"); jobB <- job("B")
  ready <- reactive(all(nzchar(jobA())) && all(nzchar(jobB())))

  current <- reactive({
    req(ready())
    c(predict_ab(jobA(), jobB()), what = describe(jobA(), jobB()))
  })

  observe({
    req(ready())
    session$sendCustomMessage("diffs", as.list(ATTRS[jobA() != jobB()]))
  })

  observeEvent(input$copy, for (a in ATTRS) updateSelectInput(session, paste0("B_", a), selected = jobA()[[a]]))
  observeEvent(input$swap, {
    a0 <- jobA(); b0 <- jobB()
    for (a in ATTRS) {
      updateSelectInput(session, paste0("A_", a), selected = b0[[a]])
      updateSelectInput(session, paste0("B_", a), selected = a0[[a]])
    }
  })

  output$now <- renderUI({
    r <- current()
    tagList(
      div(span(class = "big", sprintf("%.2f", r$p)),
          span(class = "ci", sprintf("95%% CI [%.2f, %.2f]", r$lo, r$hi))),
      div(class = "sub", HTML(sprintf(
        "Pr(<b style='color:%s'>Job A</b> chosen over <b style='color:%s'>Job B</b>) &nbsp;·&nbsp; log-odds %.2f (SE %.2f)",
        RED, BLUE, ifelse(abs(r$logodds) < 0.005, 0, r$logodds), r$se))),   # no "-0.00"
      div(class = "what", r$what)
    )
  })

  # Pr(A) and Pr(B) = 1 - Pr(A) as two bars with their 95% CIs
  output$plot <- renderPlot({
    r <- current()
    p  <- c(r$p, 1 - r$p); lo <- c(r$lo, 1 - r$hi); hi <- c(r$hi, 1 - r$lo)
    x <- c(1, 2); w <- 0.32
    par(mar = c(2.2, 4, 0.8, 1), mgp = c(2.4, 0.5, 0), tcl = -0.25, las = 1,
        col.axis = "#555", family = "sans")
    plot(NA, xlim = c(0.4, 2.6), ylim = c(0, 1), xaxt = "n", yaxs = "i",
         xlab = "", ylab = "Probability of being chosen", bty = "l", fg = "#999")
    abline(h = seq(0.1, 0.9, 0.1), col = "#eeeeee", lwd = 0.8)
    abline(h = 0.5, lty = 2, col = "#999")
    rect(x - w, 0, x + w, p, col = c(RED, BLUE), border = NA)
    arrows(x, lo, x, hi, angle = 90, code = 3, length = 0.08, lwd = 2, col = "#333333")
    text(x, pmin(hi + 0.04, 0.97), sprintf("%.2f", p), font = 2, col = "#333333")
    axis(1, at = x, labels = c("Job A", "Job B"), fg = "#999", font = 2, cex.axis = 1.05)
  }, res = 96)
}

shinyApp(ui, server)
