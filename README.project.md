# Title

What the project asks, with which data and methods, in one paragraph.

## Data access

- Source: study, release name and date.
- Access: how to apply, under a data use agreement. The data are not part of
  this repository.
- Data dictionary: public at URL, or distributed with the data.
- Sharing results: only aggregate results leave the approved team; cells
  with fewer than N participants are suppressed (per the data use
  agreement).

## Setup

```sh
micromamba create -f environment.yml
micromamba activate ENV_NAME
Rscript -e 'renv::restore()'
```

Conventions: [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md).

## Pipeline

Run from the project root, in order:

| Script | Purpose |
|---|---|

## Project notes

Deliberate differences from `docs/CONVENTIONS.md`, with reasons.
