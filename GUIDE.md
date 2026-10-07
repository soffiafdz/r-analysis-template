# R analysis conventions: full guide

Reference for setting up and running R analysis projects, with the reasoning
behind each choice. Projects carry the short version, `docs/CONVENTIONS.md`;
this file stays in the template.

The goal is that anyone who clones a repository can rebuild the exact software
environment, run the pipeline from raw data to manuscript, and trace every
reported number back to the code that produced it.

---

## 1. Principles

- **Every reported number comes from pipeline output.** Numbers in a
  manuscript, report, poster or grant are read from result files written by
  the pipeline scripts. Nothing is typed into prose or code by hand. A number
  that cannot be traced to a file does not get reported.
- **Citations are verified** against Crossref, the DOI or the publisher before
  they enter `references.bib`.
- **Verify before stating.** Compute a number from the files before quoting
  it; read a function before describing what it does.
- **Fail loudly.** A missing input or an empty result stops the run with an
  error. Silent fallbacks (skipping an iteration, printing an empty string)
  are how wrong numbers end up in papers.
- **Participant data never enters version control.** Only code,
  configuration and documentation are tracked.
- **Code follows the documented data.** Variable names, codings, units and
  valid ranges come from the release's data dictionary or from inspecting
  the data, never from assumption. Validation checks cite their source
  (e.g. `# range per data dictionary, 2026-02 release`).
- **Validation thresholds use documented ranges, not observed extremes.**
  In public code, an observed minimum or maximum can identify a participant.
- **Cite the data dictionary, don't copy it.** For restricted releases the
  dictionary itself may fall under the data use agreement.

---

## 2. Software environment

Three layers, each pinned in a tracked file:

| Layer | Tool | Tracked file | Pins |
|---|---|---|---|
| R itself, compilers, system libraries, Quarto | micromamba (conda-forge) | `environment.yml` | R and Quarto versions |
| R packages | renv | `renv.lock` (+ `DESCRIPTION`) | every package and version |
| TeX for PDF rendering | system TeX Live (`xelatex`) | none | n/a |

### 2.1 Why a conda environment and renv

conda-forge provides a specific R version together with the C/C++/Fortran
compilers and system libraries (libcurl, libxml2, fonts) that R packages
compile against. That makes the build independent of whatever R or Homebrew
libraries happen to be installed on a machine. renv then records the exact
version of every R package. The conda environment pins *R*; renv pins *the
packages*. Neither alone is enough.

On macOS, conda-forge's R installs packages from source, which is why the
compilers are part of the environment.

`environment.yml` is a short, hand-written specification (pinned R and Quarto
versions plus build dependencies), not a full export. A full export
(`micromamba env export`) pins platform-specific build strings and cannot be
created on another operating system.

### 2.2 renv settings

- **Repository:** Posit Package Manager, `https://p3m.dev/cran/latest`, set in
  `.Rprofile`. It serves prebuilt Linux binaries, so collaborators on Linux
  restore in minutes instead of compiling.
- **`snapshot.type: implicit`:** `renv::snapshot()` records every package the
  project's code uses (`library()`, `pkg::`), plus everything listed in
  `DESCRIPTION`.
- **`DESCRIPTION`** lists packages the code does not call directly but the
  project needs: `lintr`, `quarto`, `rmarkdown`, and anything installed ahead
  of the code that will use it. Without it, an implicit snapshot would drop
  them.
- **Package cache on** (renv's default). Packages built once are shared
  across projects instead of being recompiled. The lockfile, not the cache,
  is what guarantees reproducibility.
- **Keep `renv::status()` clean.** A project that prints "out-of-sync" on
  every run is not reproducible. After installing or removing a package, run
  `renv::snapshot()` and commit `renv.lock`.

Adding a package:

```r
renv::install("pkg")
# use it in code, or add it to DESCRIPTION if the code won't call it
renv::snapshot()
```

### 2.3 Setup

```sh
micromamba create -f environment.yml
micromamba activate <env-name>     # or let direnv do it (2.4)
Rscript -e 'renv::restore()'
```

### 2.4 Automatic activation (optional)

With [direnv](https://direnv.net), an `.envrc` at the project root activates
the environment on `cd`:

```sh
env_name=<env-name>
if ! micromamba env list | grep -qE "^\s*${env_name}\s"; then
  log_error "micromamba env '${env_name}' not found; run: micromamba create -f environment.yml"
  return 1
fi
eval "$(micromamba shell activate -s bash -n "${env_name}")"
watch_file environment.yml
```

Then run `direnv allow` once. `.envrc` is gitignored because activation is a
personal choice (some people use `conda`, `mamba` or an IDE instead).

renv needs no activation step: `.Rprofile` runs `source("renv/activate.R")`
whenever R starts in the project root.

### 2.5 Paths

All paths are built with `here::here()`, anchored by an empty `.here` file at
the project root. Scripts never call `setwd()` and never contain absolute
paths, so they run the same from any machine and any working directory inside
the project.

---

## 3. Repository layout

```
project/
├── .here                     # empty; anchors here()
├── .Rprofile                 # activates renv, sets the package repository
├── .lintr                    # style rules (section 6)
├── .envrc                    # optional, gitignored (2.4)
├── environment.yml           # conda-forge spec: R, Quarto, toolchain
├── DESCRIPTION               # packages not called directly by code (2.2)
├── renv.lock, renv/
├── README.md                 # overview, data access, setup, pipeline order,
│                             # project notes
├── config/
│   └── pipeline_config.yaml  # every path and parameter (section 4)
├── R/
│   ├── scripts/              # NN_verb_object.R, run in numeric order
│   └── utils/                # sourced helper modules (section 5)
├── reports-src/              # .qmd sources, _quarto.yml, references.bib, CSL;
│                             # .Rprofile points Quarto's R at renv; slide
│                             # theme and PowerPoint template (section 8)
├── docs/                     # this file, audits and their check scripts
├── data/                     # gitignored
│   ├── archive/              # compressed copy of each original release
│   ├── raw/                  # original data as received; read-only
│   ├── external/             # reference data from other sources
│   └── derivatives/          # everything the pipeline derives from raw
├── models/{fits,results,diagnostics}/   # gitignored
├── outputs/{figures,tables,reports}/    # gitignored
├── logs/                     # gitignored; one log file per R process
├── archive/<date>_<label>/   # gitignored; snapshots of results (section 9)
└── submission/               # gitignored; assembled journal package
```

Two things called "archive" serve different purposes:
- `data/archive/` holds the untouched original data releases, compressed
  (`.tar.zst`). It is the copy to restore from if `data/raw/` is damaged.
- `archive/` at the root holds dated snapshots of *results*, taken before
  re-runs that change them.

### 3.1 Raw data

`data/raw/` is read-only (`chmod -R a-w data/raw`). Scripts read from it and
write to `data/derivatives/`. Dated file names of raw releases appear in one
place only: `config/pipeline_config.yaml`.

To archive a release:

```sh
COPYFILE_DISABLE=1 tar --exclude='.DS_Store' -cf - <release_dir> \
  | zstd -19 -T0 -o data/archive/<release_name>.tar.zst
chmod a-w data/archive/<release_name>.tar.zst
# restore:
zstd -dc data/archive/<release_name>.tar.zst | tar -xf -
```

### 3.2 `.gitignore` policy

- `data/`, `models/`, `outputs/`, `logs/` are ignored entirely. The helpers
  create these folders on first write, so no `.gitkeep` files are needed.
- `archive/`, `submission/`.
- R session files, `R CMD build/check` output, `.Rproj.user/`.
- `renv/library/`, `renv/staging/`, `renv/local/`.
- Quarto: `_freeze/`, `*_cache/`, `.quarto/`, and generated `.tex`.
- `.envrc`, `.Renviron` (personal settings, may contain credentials).
- Root-level `/*.pdf`, `/*.png`, `/*.svg` (posters, screenshots).
- Common data formats anywhere (`*.csv`, `*.sas7bdat`, `*.xlsx`, ...), as a
  second line of defence against committing participant data outside `data/`.

`outputs/` is ignored because even aggregate tables can identify participants
when cells are small. Results are shared deliberately, after checking them
against the data use agreement.

---

## 4. Configuration: one YAML file

Everything a script needs to know lives in `config/pipeline_config.yaml`.
Scripts contain no paths and no analysis parameters.

| Section | Holds | Read with |
|---|---|---|
| `general` | `project_name`, `random_seed`, `log_level`, `n_cores` | `get_config("general", ...)`, `set_seed()` |
| `paths` | directory layout | `get_config("paths", ...)` |
| `data` | every input and output file, grouped `raw`, `external`, `derivatives`, `models`, `outputs` | `get_data_path(group, key)` |
| `parameters` | analysis parameters: variable names, labels, thresholds, specification switches | `get_parameter(...)` |
| method sections | estimator and optimizer settings, one section per method | `get_config("<method>", ...)` |
| `output` | table and figure formats, DPI, sizes, journal limits | `get_config("output", ...)` |
| `scripts.force_regenerate` | one flag per script | `get_script_setting("force_regenerate", key, default = FALSE)` |
| `packages` | required and optional packages | `validate_packages()` |

Rules, and why:
- **Dated raw file names live only in the config.** When a new release
  arrives, one line changes.
- **One loader per derived variable.** If several scripts need the same
  variable, one function reads it, with the column name taken from the
  config. Repeated `fread(select = ...)` calls drift apart, and a renamed
  column then has to be found in every one of them.
- **Alternative specifications are config switches**, not code edits, so
  earlier results stay reproducible
  (e.g. `parameters.score.source: recomputed | released`).
- **Every script with a cache check has a key** under
  `scripts.force_regenerate`.
- **To re-run a script:** set its flag to `true`, run it, set it back to
  `false`. Outputs are never deleted to force a re-run: reports and
  manuscripts depend on those files existing.

---

## 5. Helper library (`R/utils/`)

Plain R files loaded with `source(here("R/utils/<file>.R"))`, not a package.
Each module sources its own dependencies (e.g. `data_io.R` sources
`logging.R`), so a script can source just what it needs.

Shared modules, identical across projects:

**`config.R`**
- `load_config(config_file = here("config/pipeline_config.yaml"))` reads the
  YAML into the global `.config`.
- `get_config(..., default = NULL)`: nested lookup; stops on a missing key
  unless a default is given.
- `get_data_path(...)`: `here()` + lookup under `data:`.
- `get_parameter(..., default = NULL)`,
  `get_script_setting(..., default = NULL)`.
- `get_seed()`, `set_seed()`.
- `validate_config(config = NULL)`: requires the sections `general`, `data`,
  `parameters` and `scripts`, plus `general.random_seed` and the `data`
  groups `raw`, `derivatives` and `models`.
- Project-specific lookups (canonical factor levels, timepoint labels) are
  added at the end of a project's copy, reading their values from the config.

**`logging.R`**
- Writes to `logs/pipeline_YYYYMMDD_HHMMSS.log`, one file per R process;
  INFO and above also go to the console.
- `log_debug()`, `log_info()`, `log_warn()`, `log_error()`, `sprintf` style.
- `log_script_start(name)`, `log_script_end(name, success = TRUE)`,
  `log_section(name)`, `log_time(description, expr)`.
- Warnings printed by packages go to the console only. Capture stdout and
  stderr when running long jobs.

**`data_io.R`**
- `check_files_exist(files.v, stop_on_missing = TRUE)`.
- `read_rds_safe(file_path, description = NULL)`,
  `write_rds_safe(object, file_path, description = NULL)` (creates the
  directory and logs the path).
- `read_csv_safe(file_path, ..., description = NULL)` wraps `fread`.
- `needs_regeneration(output_path, input_paths.v = NULL,
  force_regenerate = FALSE)` compares modification times.
- `ensure_directory(dir_path)`, `path_join(...)`.
- `require_output(x, label)` stops if `x` is `NULL`. Use it for anything a
  reported number depends on.

**`validation.R`**
- `validate_columns(data.dt, required_cols.v, data_name)`,
  `validate_not_empty(x, data_name)`.
- `validate_num_range(data.dt, col_name, min_val, max_val,
  na_allowed = TRUE)`: catches unit errors (a proportion stored as a
  percentage).
- `validate_categorical(data.dt, col_name, expected_levels.v,
  allow_extra = FALSE)`.
- `validate_age(...)`, `validate_unique_ids(data.dt, id_cols.v)`,
  `validate_packages(packages.v)`.

Generic base, identical across projects, then extended per project below a
`Project-specific` banner at the end of each file:

**`tables.R`** (gt)
- Styling: `style_manuscript_table(gt_tbl, table_type = "main")` with
  `"main"`, `"supplementary"` or `"compact"` size presets;
  `apply_significance_style(gt_table, sig_col = "SIGN", style_cols = NULL)`
  sets non-significant rows in italics and hides the indicator column.
- Formatters for tables: `format_p` (vectorized, NA-safe), `sig_stars`,
  `format_effect_ci`, `format_ci`, `format_beta_std`,
  `format_mean_sd(values, digits = 1, big_mark = "")`, `bin_ages`,
  `ttest_summary`.
- Helpers for prose: `fmt_p_inline` ("p < 0.001", "p = 0.031"),
  `ci_sig_check.fn` (significant if the bootstrap CI excludes 0),
  `n_of_total.fn` ("four of six", "all six").
- Saving: `save_table(gt_table, filename, output_dir,
  formats = c("html", "tex"), table_type = "main")` writes each format; for
  LaTeX it runs `fix_latex_source_notes()` (font sizes, centred longtables,
  source notes, symbols gt escapes) and `wrap_latex_table()` (a standalone
  `_standalone.tex` that compiles on its own for checking).
  `save_table_dual()` writes HTML and LaTeX to separate directories.
- Documents and slides: `add_title.fn(gt_tbl, title)` (no header when
  `title` is `NULL`, because the caption carries it),
  `style_screen_table.fn()` (larger text for a browser or slides),
  `style_pdf_table.fn(gt_tbl, size = 14)` (text that fits a PDF page).
- One `create_<thing>_table()` per manuscript table.

**`plotting.R`** (ggplot2)
- `manuscript_colors()`: the single named list of colours. Every figure
  takes its colours from it, so a variable has the same colour in every
  figure. Projects add one entry per group, predictor or measure.
- `get_palette(type)`: `"default"` (Okabe-Ito), `"tol_bright"` and
  `"tol_muted"` (Paul Tol, colourblind-safe), `"sex"`, `"sex_md"`.
- `theme_publication(base_size = 10, use_markdown = FALSE)`, based on
  `theme_classic`; `use_markdown = TRUE` renders markdown and HTML
  (`**bold**`, `<sup>`) in titles, axes and strips via ggtext.
- `save_plot(plot, filename, width = 7, height = 7, dpi = 600)`; the
  extension sets the format.
- `wrap_text()` (returns `NULL` for `NULL`), and `plot_comparison()` for
  estimates with CIs by group.
- One `plot_<thing>()` per figure. Its `title`, `subtitle` and `caption`
  arguments accept `NULL`, and it takes `base_size`, so the same function
  draws the slide version: the script builds the plot a second time with
  no title, subtitle or caption at `output.slide_base_size`, and saves it as
  PNG at `output.slide_figure_size` to its own config path
  (`<figure>_slide`). Direct labels that grow with the text may need extra
  room on the axis for the slide version.

**Domain modules:** one file per method or construct (e.g. a score
recomputation, model helpers, a flow diagram).

---

## 6. Code style

Checked with `lintr` (`.lintr` at the project root): `lintr::lint_dir()`.

- **Naming:** `snake_case` with a suffix that states the object's type, so
  code reads correctly without inspecting objects.
  - `.dt` data.table, `.df` data.frame, `.v` vector, `.lst` list,
    `.fn` function, `.fit` fitted model, `.mod` model specification,
    `.res` results object, `.tbl` table, `.plt` plot, `.mat` matrix,
    `.fct` factor, `.path` path, `.subdt` subset of a data.table.
  - UPPERCASE for constants (`COGNITIVE_DOMAINS`, `N_BOOT`).
  - A leading dot marks hidden module state (`.config`, `.log_file`).
  - Regex enforced by `.lintr`:
    `^(\.?[a-z][a-z0-9_]*(\.df|\.dt|\.fct|\.fit|\.fn|\.lst|\.mat|\.mod|\.path|\.plt|\.subdt|\.res|\.tbl|\.v)?|[A-Z][A-Z0-9_]*)$`
- **Lines of 80 characters or fewer.**
- **data.table throughout.**
  - Write `:=` against each table explicitly. Looping over
    `list(a.dt, b.dt)` to add columns by reference does not modify the
    originals reliably.
  - Never give a function argument the same name as a column used inside
    `[`: in `coef.dt[match(sex, coef.dt$sex)]` the column silently wins over
    the argument.
- **Roxygen-style `#'` headers** (parameters, return value) on every helper;
  `# ---` section banners in scripts.
- **Idempotent scripts.** A script that reads a file and writes it back gives
  the same result when run twice. Values are derived from the raw columns
  every time, never from a previously transformed version of themselves.
- **Fail loudly.** `stopifnot()` or `require_output()` on anything a reported
  number depends on.

---

## 7. Pipeline scripts

- Named `NN_verb_object.R`; the number is the execution order. Add-ons take a
  letter suffix (`10b_`).
- Run from the project root: `Rscript R/scripts/NN_verb_object.R`.
- The header documents purpose, model specification, rationale, verified
  references, `INPUTS` and `OUTPUTS`. When a script is renumbered, its header
  is updated too.
- Each script saves its results as one named list: the results, sample sizes,
  methodology notes, the config values used and a timestamp. A result file is
  then self-describing.

Template:

```r
#!/usr/bin/env Rscript
# =============================================================================
# NN_verb_object.R - One-line purpose
# =============================================================================
# What and why; model specification; references (verified).
#
# INPUTS:
#   - data/derivatives/...
# OUTPUTS:
#   - models/results/...
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(data.table)
})

source(here("R/utils/logging.R"))
source(here("R/utils/config.R"))
source(here("R/utils/data_io.R"))
source(here("R/utils/validation.R"))

log_script_start("NN_verb_object.R")
config <- load_config()
validate_config(config)
set_seed()

# --- Cache check ---
FORCE_REGENERATE <- get_script_setting(
  "force_regenerate", "nn_key", default = FALSE
)
output.path <- get_data_path("models", "nn_output")
if (!FORCE_REGENERATE && file.exists(output.path)) {
  log_info("Output exists and force_regenerate=FALSE; skipping")
  log_script_end("NN_verb_object.R", success = TRUE)
  quit(status = 0)
}

# --- Configuration ---
DOMAINS <- get_parameter("domains")

log_section("Part 1: Load data")
# ...
log_section("Part N: Save results")
write_rds_safe(results.lst, output.path, "NN results")
log_script_end("NN_verb_object.R", success = TRUE)
```

---

## 8. From results to manuscript

- **One environment script.** The last pipeline script loads every result
  file, computes every number the text uses and saves a single named list to
  `outputs/<document>_env.rds`. The document does no analysis of its own.
- **Setup chunk.** It starts with `here::i_am("reports-src/<file>.qmd")`:
  run from `reports-src/`, `here()` otherwise stops at the Quarto project
  there instead of the `.here` file. Then it sources the utils, calls
  `load_config()`, and runs
  `invisible(list2env(readRDS(get_data_path("outputs", "<document>_env")),
  environment()))` (`invisible`, or the environment prints in the PDF).
- **renv inside Quarto.** Quarto starts R in `reports-src/`, which has its
  own `.Rprofile` pointing at the project's renv; without it knitr is not
  found.
- **Prose uses inline R only** (`` `r sprintf("%.1f", pct_female)` ``). A new
  number is added to the environment script, not computed in a chunk.
- **Never start a line with inline R that prints a number.** After knitting,
  a line beginning "16) lost" or "7362. Without" is a numbered list item to
  pandoc, inside lists especially. Reflow so the number is mid-line.
- **Captions with numbers** use `#| fig-cap: !expr sprintf(...)` (and
  `tbl-cap`), so they come from the environment like the prose.
- **After any upstream change,** re-run the environment script before
  rendering.
- **`reports-src/_quarto.yml`:** `output-dir: ../outputs/reports`,
  `execute-dir: project`; `echo`, `warning` and `message` all false; an
  explicit render list.
- **Render to PDF:** `cd reports-src && quarto render <file>.qmd --to pdf`
  (xelatex). Word copies for journals are converted from the rendered output.
  `_quarto.yml` sets the PDF defaults: Libertinus fonts (shipped with TeX
  Live, with Greek letters), a table of contents and numbered sections.
- **Tables in the PDF:** pass gt tables through `style_pdf_table.fn()`. If
  one still overflows, shorten its row labels in the document (and say so in
  the source note) rather than shrinking the text further.
- **Captions:** every `tbl-cap` and `fig-cap` starts with a bold title of 3
  to 8 words ending in a full stop, then the details
  (`"**Short title.** Details..."`). The bold part becomes the short caption
  in lists of tables and figures.
- **References:** `references.bib` (Zotero export, abbreviated journal names)
  and the journal's CSL file in `reports-src/`.
- **Prose style:** no em-dashes (use a semicolon, a colon or a new sentence).
  Avoid stock openers such as "Of note" or "It is worth noting".

### Slides

Slides take their numbers from the same environment file as the report. They
exist as two Quarto files, because the HTML cards do not survive conversion
to PowerPoint:

- **`slides.qmd`, the designed deck:** self-contained HTML (revealjs) with
  the theme in `reports-src/slides.scss`.

  ```yaml
  format:
    revealjs:
      embed-resources: true
      theme: [default, slides.scss]
      slide-number: c/t
      menu: false
      width: 1600
      height: 900
      margin: 0.06
  ```

  Number cards are fenced divs: `::: {.cards}` holding one
  `::: {.card .<group>}` per number, with a bold title as the first line
  (shown in dark red), `[value]{.big}` and `[label]{.unit}`. Each group gets
  a `.card.<group>` rule in `slides.scss` with its `manuscript_colors()`
  colour; cards without a group use `.red`, `.blue`, `.green` or `.teal`,
  following the card colour rule in `docs/STYLE.md`. A `::: {.note}` box
  holds a short explanation, and `fig-cap` gives one small grey line under a
  figure. Figures use their slide versions (section 5) with
  `#| fig-align: center`.
- **`slides-pptx.qmd`, the editable copy** for colleagues to adapt: the same
  content with native tables in place of the cards, on the template
  `slides-reference.pptx`.

  ```yaml
  format:
    pptx:
      reference-doc: slides-reference.pptx
      output-file: slides.pptx
  ```

  Pandoc picks a layout per slide from its content, which fixes how a slide
  has to be written:
  - A heading with a table, a list or a figure alone uses Title and Content.
  - A short paragraph followed by one table or figure uses Content with
    Caption: the template puts the paragraph under the table or figure in
    small grey text. Notes and figure captions are written this way, before
    the table or figure, not as `fig-cap` or a table caption.
  - Text after a table or figure goes to a new slide.
  - Column widths follow the dashes in a pipe table's separator line
    (`|----|-----------|`) once a row is longer than 72 characters.

A change to the slides' content is made in both files. Check the PowerPoint
in PowerPoint itself; its layout cannot be judged from the file.

The template is built by `reports-src/build_slides_reference.py` from
pandoc's default (Python with python-pptx, outside renv). Re-run it from
`reports-src/` only to change the template; the `.pptx` is committed.

---

## 9. Provenance and snapshots

- **Seeds** come from the config; `set_seed()` runs at the top of every
  script. Every run writes a log.
- **Snapshot before any re-run that changes results.**
  - Copy `outputs/`, `models/results/` and `data/derivatives/` to
    `archive/<YYYY-MM-DD>_<label>/`, and check the copy with `diff -rq`.
  - Write an `INDEX.md` in the snapshot: purpose, contents, recovery
    commands, related documents and the git branch.
  - The latest snapshot is the "before" state for any comparison.
- **Investigations** are written up in `docs/<topic>_audit.md`, with a
  companion `docs/<topic>_check.R` that reproduces every number in the write-up
  when run from the project root.
- **Derived variables in external releases** (scores, composites) are
  recomputed from their inputs where possible, and a check asserts agreement
  with the released version. Released derived variables can be wrong, and
  this check is how such errors are found.

---

## 10. Long runs and model fitting

- **Checkpoints** (e.g. per-bootstrap-iteration files) record the data and
  specification flags they were produced under, and are reused only when
  those match. When the data or specification changes, either add a flag to
  the validity check, or move the stale checkpoints into a snapshot.
- **Detached runs:** `nohup setsid bash runner.sh > run.log 2>&1 &`. The
  runner writes `START`, `END`, `FAILED` and `ALL_DONE` lines per script to a
  status file and stops at the first failure.
- **Multiple starts.** Optimizers that stop at the first acceptable solution
  can land on a local optimum. Fit from several starting values and keep the
  best log-likelihood. This applies to latent growth, mixture and
  group-based trajectory models alike. A grid search that keeps the best of
  many short runs can still miss, and more starts can even give a worse fit
  for some models. Signs of a missed optimum: a model with a lower
  likelihood than a simpler model nested in it. Before reporting, re-fit
  with more starts and keep only a selected solution that both searches
  reach.
- **Do not edit a script while `Rscript` runs it.** R reads the file as it
  goes, so a long run can pick up half-edited code. Edit a copy and swap it
  in after the run.
- **Check every fit:** convergence status, missing standard errors, and
  whether nested models fitted successfully.
- **Exogenous predictors in SEM** (e.g. OpenMx): never fix their means to 0
  and variances to 1. Fix them at the sample moments (lavaan's `fixed.x`) or
  estimate them, and centre each predictor so latent means describe an
  average participant.
- **Population curves** are drawn from model-implied means, not from averaged
  factor scores.

---

## 11. Git

- One-line, imperative commit messages. One logical change per commit.
- Stage files by name; never `git add -A`. Review staged content before
  committing.
- Branches: `fix/<topic>` for corrections. Findings with consequences outside
  the repository (a submitted paper, a preprint, a data provider) stay on an
  unpushed local branch until their disclosure is decided.
- Never commit data, outputs or credentials (3.2).

---

## 12. Lessons that shaped these rules

| Problem | What prevents it |
|---|---|
| A released derived variable was computed incorrectly by the provider | Recompute from inputs; assert agreement with the release (9) |
| One variable was read in seven places, several with the column name hardcoded | One loader function, column name in the config (4) |
| A script overwrote its own input and gave a different result on a second run | Idempotent scripts (6) |
| Bootstrap checkpoints outlived a data change | Data and specification flags in the checkpoint check (10) |
| Predictor moments fixed at 0 and 1 in an SEM gave a non-convex Hessian and missing SEs | Sample moments and centring (10) |
| A single-start fit missed the optimum | Multiple starts (10) |
| A manuscript chunk silently printed nothing for months | `stopifnot()` on every element a chunk reads (6, 8) |
| A constant derived from results was hardcoded in another script | Load it from the result file it came from (1) |
| Config, code and paper each stated a different value for the same threshold | One source of truth: the config (4) |
| A proportion threshold was checked against a percentage | `validate_num_range()` on inputs (5) |
| Script headers kept old numbers after renumbering | Update headers when renaming (7) |
| A mixture-model grid fitted with 100 starts missed better solutions for some models | Re-fit with more starts; keep a solution both searches reach (10) |
| `quarto render` could not find knitr, then `here()` pointed at `reports-src/` | `reports-src/.Rprofile` for renv; `here::i_am()` in each document (8) |
| A sentence starting with an inline number turned into a numbered list item | Never start a line with inline R that prints a number (8) |
| "APOE ε4" printed with a blank for ε in the PDF | Libertinus fonts in `_quarto.yml` (8) |
| Slides converted to PowerPoint lost their layout | A separate PowerPoint deck on its own template (8) |
| A yellow line label was unreadable on white | 3:1 contrast for coloured text (docs/STYLE.md) |

---

## 13. Starting a new project

Repositories grow with the work. The template is a parts bin, not a skeleton
to copy whole: a file or folder enters a repository the first time code needs
it. A first commit with empty folders, unused helpers and placeholder text
looks generated, and is harder to review.

Copied files belong to the project and may diverge from the template. To
take up a later change to the template, compare the two copies
(`diff -u <template_dir>/<file> <file>`) and apply what fits the project.

1. Create the project with the core files only:

   ```sh
   T=<template_dir>; P=<project_dir>
   mkdir -p $P/docs && cd $P
   cp $T/.gitignore $T/.lintr $T/.here $T/.Rprofile $T/environment.yml \
      $T/DESCRIPTION .
   cp $T/README.project.md README.md
   cp $T/docs/CONVENTIONS.md docs/
   sed -i '' -e 's/ENV_NAME/<env-name>/' environment.yml   # GNU sed: -i
   sed -i '' -e 's/PROJECT_NAME/<name>/' DESCRIPTION          # letters, digits, dots
   ```

2. Create the environment and initialise renv:

   ```sh
   micromamba create -f environment.yml
   micromamba activate <env-name>
   Rscript -e 'install.packages("renv")'
   Rscript -e 'renv::init(bare = TRUE, restart = FALSE)'
   Rscript -e 'renv::install(); renv::snapshot(prompt = FALSE)'
   ```

   `renv::init()` adds `source("renv/activate.R")` to `.Rprofile`. renv is
   installed from CRAN rather than conda-forge because conda-forge builds of
   R packages can lag behind new R releases, and installing one can silently
   downgrade R.

3. Write the README for real: overview, data access, setup. Replace every
   placeholder or delete the section; nothing in angle brackets gets
   committed. `git init`; first commit.

4. As the work needs them:
   - First script: `R/scripts/01_...R` from the template in section 7, plus
     `R/utils/logging.R`, `config.R`, `data_io.R` (and `validation.R` when
     inputs are checked). Copy `config/pipeline_config.yaml` and fill only
     the sections in use.
   - First table or figure: `R/utils/tables.R` or `plotting.R`.
   - First report: `reports-src/_quarto.yml`, `reports-src/.Rprofile`,
     `reports-src/.gitignore`, the journal's CSL file and `references.bib`.
   - First slides: `reports-src/slides.scss`; for a PowerPoint copy also
     `slides-reference.pptx` and `build_slides_reference.py` (section 8).
   - `docs/STYLE.md` with `CONVENTIONS.md` once there is anything to look
     at.
   - Folders under `data/`, `models/`, `outputs/` and `logs/` are created by
     the helpers on first write; they need no `.gitkeep`.
   - Packages arrive with the code that calls them (implicit snapshot).
     `DESCRIPTION` only lists packages no code calls, such as `lintr`.

5. Optionally add `.envrc` (2.4) and run `direnv allow`.

Anything the project does differently from this guide goes in the README
under "Project notes", with the reason.
