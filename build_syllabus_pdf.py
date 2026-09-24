#!/usr/bin/env python3
"""Build ps818-syllabus.pdf from the website sources.

Combines syllabus.qmd, schedule.qmd and assignments.qmd into a single
Quarto document and renders it to PDF outside the website project.

Usage: python3 build_syllabus_pdf.py
"""

import datetime
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "ps818-syllabus.pdf"
SITE = "https://astrezhnev.github.io/ps818/"

TITLE = "Data Analysis with Statistical Models"
SUBTITLE = "Likelihood, Bayesian and Machine Learning methods for description and prediction"
COURSE = "Political Science 818 --- Fall 2026 --- University of Wisconsin-Madison"

INFO = [
    ("Lectures", r"Mondays \& Wednesdays, 9:30am - 10:45am, Sterling Hall 1339"),
    ("Meeting dates", "9/9/2026 - 12/9/2026"),
    ("Instructor", "Anton Strezhnev, North Hall 322D"),
    ("E-mail", r"\href{mailto:strezhnev@wisc.edu}{strezhnev@wisc.edu}"),
    ("Office hours", "Tuesdays 9-11am (or by appointment via email or Slack)"),
    ("Website", r"\url{" + SITE + "}"),
]

# Links between website pages become links within the PDF (or to the site).
LINKS = {
    "schedule.qmd": "#sec-schedule",
    "assignments.qmd": "#sec-assignments",
    "syllabus.qmd": "#sec-replication-project",
    "resources.qmd": SITE + "resources.html",
}


def body(name):
    """Page contents without YAML front matter, horizontal rules or shortcodes."""
    text = (ROOT / name).read_text()
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    text = re.sub(r"^---\s*$", "", text, flags=re.M)
    text = re.sub(r"\{\{< fa brands r-project >\}\}", "R", text)
    for page, target in LINKS.items():
        text = text.replace(f"]({page})", f"]({target})")
    return text.strip() + "\n"


def promote(text):
    """Raise every heading one level (## -> #)."""
    return re.sub(r"^#(#+ )", r"\1", text, flags=re.M)


def syllabus():
    text = promote(body("syllabus.qmd"))
    return re.sub(r"^(## Replication project.*)$", r"\1 {#sec-replication-project}",
                  text, count=1, flags=re.M)


def assignments():
    text = body("assignments.qmd")
    text = text.replace("## Schedule\n", "## Assignment Schedule\n", 1)
    # The per-problem-set links duplicate the schedule table and point at files.
    text = re.sub(r"^### Problem Set \d.*?(?=^## )", "", text, flags=re.S | re.M)
    text = text.replace("Links become active as each problem set is assigned.\n", "")
    return text


def header():
    rows = "\n".join(rf"\textbf{{{k}}} & {v} \\" for k, v in INFO)
    today = datetime.date.today()
    updated = f"{today:%B} {today.day}, {today.year}"
    return rf"""
\begin{{center}}
{{\sffamily\bfseries\LARGE\color{{uwred}} {TITLE}\par}}
\vspace{{0.4em}}
{{\itshape {SUBTITLE}\par}}
\vspace{{1em}}
{{\Large {COURSE}\par}}
\vspace{{1em}}
{{\Large Last updated {updated}\par}}
\end{{center}}
\vspace{{2em}}
\begin{{center}}
\renewcommand{{\arraystretch}}{{1.3}}
\begin{{tabular}}{{@{{}}p{{0.2\textwidth}}p{{0.7\textwidth}}@{{}}}}
\toprule
{rows}
\bottomrule
\end{{tabular}}
\end{{center}}
\vspace{{1em}}
"""


PREAMBLE = r"""
\definecolor{uwred}{HTML}{C5050C}
\addtokomafont{disposition}{\color{uwred}}
\usepackage{booktabs}
\usepackage[headsepline]{scrlayer-scrpage}
\clearpairofpagestyles
\ihead{Political Science 818 \textbullet\ Fall 2026}
\ohead{Data Analysis with Statistical Models}
\cfoot*{\pagemark}
\pagestyle{scrheadings}
\setkomafont{pageheadfoot}{\normalfont\small}
\DeclareTOCStyleEntry[entryformat=\normalfont, pagenumberformat=\normalfont\color{black},
  linefill=\TOCLineLeaderFill, beforeskip=0.2em]{tocline}{section}
"""

YAML = f"""---
title: "{TITLE}"
author: "Political Science 818 — Fall 2026 — University of Wisconsin-Madison"
format:
  pdf:
    documentclass: scrartcl
    papersize: letter
    geometry: margin=1in
    toc: true
    toc-depth: 1
    colorlinks: true
    linkcolor: uwred
    urlcolor: uwred
    toccolor: black
    include-in-header: preamble.tex
    include-before-body: titleblock.tex
    template-partials:
      - before-body.tex
---
"""


def main():
    doc = "\n".join([
        YAML,
        syllabus(),
        "# Schedule {#sec-schedule}\n",
        body("schedule.qmd"),
        "# Assignments {#sec-assignments}\n",
        assignments(),
    ])
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "ps818-syllabus.qmd").write_text(doc)
        (tmp / "preamble.tex").write_text(PREAMBLE)
        (tmp / "titleblock.tex").write_text(header())
        # Suppress Quarto's \maketitle; the title block above replaces it.
        (tmp / "before-body.tex").write_text("")
        subprocess.run(["quarto", "render", "ps818-syllabus.qmd", "--to", "pdf"],
                       cwd=tmp, check=True)
        shutil.copy(tmp / "ps818-syllabus.pdf", OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
