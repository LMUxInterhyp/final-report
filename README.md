# Self-Improving Evaluation Pipeline

**Final report for the Digital Innovation Lab · LMU × Interhyp**

[Read the latest report](https://lmuxinterhyp.github.io/final-report/final-report.pdf) ·
[View build status](https://github.com/LMUxInterhyp/final-report/actions/workflows/publish-pdf.yml)

[![Report build](https://github.com/LMUxInterhyp/final-report/actions/workflows/publish-pdf.yml/badge.svg)](https://github.com/LMUxInterhyp/final-report/actions/workflows/publish-pdf.yml)

This repository contains the LaTeX source for *Self-Improving Evaluation
Pipeline for a Multi-Task Chatbot*. The report documents the design,
implementation, and evaluation of an adaptive evaluation pipeline.

## Build locally

You need a TeX distribution with pdfLaTeX, Biber, and `latexmk`.

```sh
make pdf
```

The generated report is available at `build/main.pdf`.

| Command | Purpose |
| --- | --- |
| `make pdf` | Build the report |
| `make watch` | Rebuild when source files change |
| `make check` | Check the LaTeX source |
| `make clean` | Remove generated files |

## Repository layout

```text
.
├── main.tex          # Report entry point
├── metadata.tex      # Title page and PDF metadata
├── sections/         # Report chapters
├── frontmatter/      # Abstract and declaration
├── assets/           # Figures and images
└── references.bib    # Bibliography
```

Every push to `main` builds and publishes the latest PDF through GitHub Pages.
Pull requests compile the report without replacing the published version.
