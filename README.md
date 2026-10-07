# R analysis project template

Files and conventions for R analysis projects in which anyone with access to
the data can rebuild the software environment, run the pipeline from raw
data to report, and trace every reported number back to the code that
produced it.

The template is a parts bin, not a skeleton to copy whole. A project starts
with a few core files, and each further part is copied in the first time
the project's code needs it. Copied files belong to the project from then
on; the template is a starting point and a reference, not a dependency.

## Documents

| File | Contents |
|---|---|
| [`GUIDE.md`](GUIDE.md) | The full guide, with the reasoning behind each choice; stays here |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | The short version that goes into each project |
| [`docs/STYLE.md`](docs/STYLE.md) | The look of reports, figures, tables and slides |

## Parts

| Copied | Files |
|---|---|
| At the start | `.gitignore`, `.lintr`, `.here`, `.Rprofile`, `environment.yml`, `DESCRIPTION`, `README.project.md` (as `README.md`), `docs/CONVENTIONS.md` |
| With the first script | `config/pipeline_config.yaml`; `R/utils/logging.R`, `config.R`, `data_io.R`, and `validation.R` once inputs are checked |
| With the first table or figure | `R/utils/tables.R` (gt), `R/utils/plotting.R` (ggplot2) |
| With the first report | `reports-src/_quarto.yml`, `.Rprofile`, `.gitignore`, `references.bib` |
| With the first slides | `reports-src/slides.scss`; for a PowerPoint copy, `slides-reference.pptx` and `build_slides_reference.py` |
| Once there is anything to look at | `docs/STYLE.md` |

`README.project.md` is the outline of a project's README. To start a
project, follow [`GUIDE.md`](GUIDE.md) section 13.

## Requirements

- micromamba, mamba or conda, to create the environment in
  `environment.yml` (R 4.6, Quarto 1.9, compilers and system libraries).
  R packages are installed with renv.
- TeX Live with xelatex for PDF reports; the Libertinus fonts ship with it.
  A minimal install such as TinyTeX needs `tlmgr install libertinus-fonts`.
- Python with python-pptx, only to rebuild the PowerPoint template.
- PowerPoint, to check the PowerPoint slides; LibreOffice may lay them out
  differently.

The commands in the guide were written on macOS; `sed -i ''` is BSD sed,
and GNU sed takes `-i` alone.

## Licence

`GUIDE.md` and this README are licensed under
[CC BY 4.0](LICENSE-docs). Everything else, including the files copied into
projects, is under the [MIT licence](LICENSE).
