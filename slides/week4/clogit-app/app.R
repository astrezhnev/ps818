# ---------------------------------------------------------------------------
# Predicted choice probabilities from the Mazumder and Yan (2024) conditional
# logit.
#
# Build two hypothetical jobs, A and B, from the 19 randomized attributes. The
# model's probability that a respondent picks A is
#
#   Pr(A over B) = logistic((x_A - x_B)' beta)
#
# with a 95% CI from the delta method on the log-odds scale, using the
# respondent-clustered (CR1) covariance of beta-hat, mapped through the
# logistic function. Comparisons can be saved to plot side by side.
#
# beta-hat and V-hat come from prepare_fit.R. Deliberately base R + shiny
# only: every extra package is another wasm download when this runs in the
# browser through shinylive.
# ---------------------------------------------------------------------------

library(shiny)

pw <- read.csv("part_worths.csv", stringsAsFactors = FALSE)
V  <- as.matrix(read.csv("vcov.csv", row.names = 1, check.names = FALSE))
beta  <- setNames(pw$estimate[!pw$baseline], pw$term[!pw$baseline])[rownames(V)]
ATTRS <- unique(pw$attribute)
LABEL <- setNames(pw$label[!duplicated(pw$attribute)], ATTRS)
LEVELS <- lapply(setNames(ATTRS, ATTRS), function(a) pw$level[pw$attribute == a])

RED <- "#c5050c"; BLUE <- "#0479A8"; INK <- "#333333"; MAX_SAVED <- 6

# Starting point: two otherwise identical mid-range jobs that differ only in
# governance, so the first number on screen is a governance effect.
DEFAULT <- setNames(vapply(ATTRS, function(a) LEVELS[[a]][1], ""), ATTRS)
DEFAULT[c("income", "healthcare", "retirement", "sick_leave", "hours", "culture")] <-
  c("$70k", "75%", "50%", "Two weeks", "40", "Somewhat friendly")
START_A <- replace(DEFAULT, "governance", "Workers on the board")
START_B <- DEFAULT

# Difference in design vectors, x_A - x_B, over the non-baseline terms
x_diff <- function(a, b) {
  d <- setNames(numeric(length(beta)), names(beta))
  for (at in ATTRS) {
    if (a[[at]] == b[[at]]) next
    ta <- paste0(at, a[[at]]); tb <- paste0(at, b[[at]])
    if (ta %in% names(d)) d[ta] <- d[ta] + 1
    if (tb %in% names(d)) d[tb] <- d[tb] - 1
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
.btn-save { background:#c5050c; border-color:#c5050c; color:#fff; }
.btn-save:hover { background:#9B0000; border-color:#9B0000; color:#fff; }
.now { flex:none; border-bottom:1px solid #e2e2e2; padding-bottom:8px; margin-bottom:6px; }
.now .big { font-family:'Red Hat Display',sans-serif; font-size:30px; font-weight:700; color:#333; }
.now .ci { font-size:15px; color:#555; margin-left:6px; }
.now .sub { font-size:12px; color:#777; margin-top:2px; }
.now .what { font-size:12px; color:#333; margin-top:4px; max-height:34px; overflow-y:auto; }
.plotbox { flex:1 1 auto; min-height:0; }
.saved { flex:none; font-size:11.5px; color:#555; max-height:92px; overflow-y:auto; margin-top:4px; }
.saved div { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.saved b { color:#0479A8; }
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
        actionButton("save", "Save comparison", class = "btn-save"),
        actionButton("copy", "Copy A to B"),
        actionButton("swap", "Swap A and B"),
        actionButton("clear", "Clear saved")
      )
    ),
    div(class = "card results",
      uiOutput("now", class = "now"),
      div(class = "plotbox", plotOutput("plot", height = "100%")),
      uiOutput("saved", class = "saved"),
      div(class = "note",
          "95% CIs: delta method on the log-odds scale, respondent-clustered (CR1) covariance. ",
          "Conditional logit fit to 3,886 tasks from 993 respondents.")
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

  saved <- reactiveVal(list())

  observe({
    req(ready())
    session$sendCustomMessage("diffs", as.list(ATTRS[jobA() != jobB()]))
  })

  observeEvent(input$save, {
    s <- c(saved(), list(current()))
    saved(tail(s, MAX_SAVED))
  })
  observeEvent(input$clear, saved(list()))
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

  output$plot <- renderPlot({
    rows <- c(list(current()), rev(saved()))
    n <- length(rows)
    labs <- c("Current", if (length(saved())) paste0("#", rev(seq_along(saved()))))
    cols <- c(RED, rep(BLUE, n - 1))
    y <- rev(seq_len(n))
    par(mar = c(3, 5.2, 0.8, 1), mgp = c(1.9, 0.5, 0), tcl = -0.25, las = 1,
        col.axis = "#555", family = "sans")
    plot(NA, xlim = c(0, 1), ylim = c(0.4, max(n, 4) + 0.6), yaxt = "n", xaxs = "i",
         xlab = "Pr(Job A chosen over Job B)", ylab = "", bty = "l", fg = "#999")
    abline(v = 0.5, lty = 2, col = "#999")
    abline(v = seq(0, 1, 0.1), col = "#eeeeee", lwd = 0.8)
    axis(2, at = y, labels = labs, fg = "#999", cex.axis = 0.95)
    for (i in seq_len(n)) {
      segments(rows[[i]]$lo, y[i], rows[[i]]$hi, y[i], col = cols[i], lwd = 3)
      points(rows[[i]]$p, y[i], pch = 21, bg = "#fff", col = cols[i], cex = 1.5, lwd = 2)
    }
  }, res = 96)

  output$saved <- renderUI({
    s <- saved()
    if (!length(s)) return(div("Save a comparison to keep it on the plot (up to 6)."))
    lapply(rev(seq_along(s)), function(i)
      div(title = s[[i]]$what, tags$b(paste0("#", i)),
          sprintf(" %.2f [%.2f, %.2f]  ", s[[i]]$p, s[[i]]$lo, s[[i]]$hi), s[[i]]$what))
  })
}

shinyApp(ui, server)
