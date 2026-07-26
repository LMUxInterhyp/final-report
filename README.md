# Final report

This repository contains the consolidated LaTeX project for the Digital Innovation Lab report, **Self-Improving Evaluation Pipeline for a Multi-Task Chatbot**.

## Current PDF

[![Build and publish report PDF](https://github.com/LMUxInterhyp/final-report/actions/workflows/publish-pdf.yml/badge.svg)](https://github.com/LMUxInterhyp/final-report/actions/workflows/publish-pdf.yml)

[Open the latest successful build](https://lmuxinterhyp.github.io/final-report/final-report.pdf).

GitHub Actions rebuilds the report for every push to `main` and publishes the PDF directly through GitHub Pages. The link opens the browser's native PDF viewer, which also provides the download controls. Pull requests compile the report without updating the published version.

Before the first deployment, select **GitHub Actions** under **Settings → Pages → Build and deployment → Source**.

## Build

The project uses pdfLaTeX, Biber, and `latexmk`.

```sh
make pdf
```

The generated PDF is written to `build/main.pdf`.

## Project structure

- `main.tex` defines the report order and front matter.
- `metadata.tex` contains title-page and PDF metadata.
- `sections/` contains the report chapters and component fragments.
- `frontmatter/` contains the abstract, highlights, and declaration.
- `assets/` contains the consolidated figures and the named signature-image slots.
- `references.bib` is the shared bibliography.
