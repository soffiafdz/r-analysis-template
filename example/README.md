# Body mass of Palmer penguins by species and sex

A worked example of the project template in the parent folder. It asks how
much heavier male penguins are than females in three species, using the
public Palmer penguins data: means with confidence intervals by species
and sex, differences within each species, and one linear model. The
rendered report and both slide decks are in
[`outputs/reports/`](outputs/reports/).

## Data access

- Source: `datasets::penguins`, shipped with R since 4.5. The data were
  collected at Palmer Station, Antarctica, from 2007 to 2009 (Gorman,
  Williams and Fraser 2014, doi:10.1371/journal.pone.0090081).
- Access: none needed; the data come with R.
- Data dictionary: the help page, `?datasets::penguins`.
- Sharing results: the data are public, so results can be shared freely.

## Setup

From this folder:

```sh
micromamba create -f environment.yml
micromamba activate penguins_example
Rscript -e 'renv::restore()'
```

Conventions: [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md); the look of the
documents: [`docs/STYLE.md`](docs/STYLE.md).

## Pipeline

Run from this folder, in order:

| Script | Purpose |
|---|---|
| `R/scripts/01_prepare_penguins.R` | Check the data against its help page; keep complete records |
| `R/scripts/02_compare_body_mass.R` | Means by species and sex, differences within species, linear model, figure |
| `R/scripts/03_build_summary_env.R` | Gather every number the documents use |

Then render the documents:

```sh
cd reports-src
quarto render summary.qmd --to pdf
quarto render slides.qmd
quarto render slides-pptx.qmd
```

## Project notes

- Rendered reports are tracked in `outputs/reports/`, so they can be read
  without running anything. The data are public, so the reason for keeping
  `outputs/` out of version control does not apply.
- There is no raw data file: script 01 reads the data from R.
- The PowerPoint template `reports-src/slides-reference.pptx` is used as it
  comes from the template, so its build script is not copied.
