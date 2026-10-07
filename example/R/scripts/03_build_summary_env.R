#!/usr/bin/env Rscript
# =============================================================================
# 03_build_summary_env.R - Gather every number the summary documents use
# =============================================================================
# Reads the results of 01 and 02 and saves, as one named list, every number
# and table that reports-src/summary.qmd and the two slide decks show. The
# documents do no analysis of their own.
#
# INPUTS:
#   - data/derivatives/penguins.rds: from 01
#   - models/results/body_mass.rds: from 02
# OUTPUTS:
#   - outputs/summary_env.rds: numbers, the table and figure paths
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(data.table)
})

source(here("R/utils/logging.R"))
source(here("R/utils/config.R"))
source(here("R/utils/data_io.R"))
source(here("R/utils/validation.R"))

log_script_start("03_build_summary_env.R")
config <- load_config()
validate_config(config)
set_seed()

# --- Cache check ---
FORCE_REGENERATE <- get_script_setting(
  "force_regenerate", "build_summary_env", default = FALSE
)
output.path <- get_data_path("outputs", "summary_env")
if (!FORCE_REGENERATE && file.exists(output.path)) {
  log_info("Output exists and force_regenerate=FALSE; skipping")
  log_script_end("03_build_summary_env.R", success = TRUE)
  quit(status = 0)
}

# --- Configuration ---
P <- get_parameter()

log_section("Part 1: Load results")
penguins.res <- read_rds_safe(get_data_path("derivatives", "penguins"))
body_mass.res <- read_rds_safe(get_data_path("models", "body_mass"))
means.dt <- body_mass.res$means
differences.dt <- body_mass.res$differences
coefficients.dt <- body_mass.res$coefficients
require_output(means.dt, "means")
require_output(differences.dt, "differences")
require_output(coefficients.dt, "coefficients")

log_section("Part 2: Numbers for the text")
data.lst <- list(
  penguins = penguins.res$n$penguins,
  complete = penguins.res$n$complete,
  dropped = penguins.res$n$dropped,
  dropped_by_species = penguins.res$n$dropped_by_species,
  years = range(P$years),
  species = P$species
)
#' One model term as a list of estimate and CI bounds
#' @param term_name Term as named by lm()
#' @return Named list
term.fn <- function(term_name) {
  row.dt <- coefficients.dt[term == term_name]
  stopifnot(nrow(row.dt) == 1)
  as.list(row.dt[, .(estimate, lower, upper)])
}
model.lst <- list(
  n = body_mass.res$fit$n,
  r_squared = body_mass.res$fit$r_squared,
  male = term.fn(paste0("sex", P$sex_labels[2])),
  chinstrap = term.fn(paste0("species", P$species[2])),
  gentoo = term.fn(paste0("species", P$species[3]))
)

log_section("Part 3: Body mass table")
#' Value with its CI, rounded to whole grams
#' @param x,lower,upper Numeric vectors
#' @return Character vector, e.g. "3369 (3306 to 3432)"
ci.fn <- function(x, lower, upper) {
  sprintf("%.0f (%.0f to %.0f)", x, lower, upper)
}
wide.dt <- dcast(
  means.dt[, .(species, sex, n, value = ci.fn(mean, lower, upper))],
  species ~ sex, value.var = c("n", "value")
)
table.dt <- merge(
  wide.dt,
  differences.dt[, .(species, difference = ci.fn(estimate, lower, upper))],
  by = "species"
)
setcolorder(table.dt, c(
  "species", paste0(c("n_", "value_"), P$sex_labels[1]),
  paste0(c("n_", "value_"), P$sex_labels[2]), "difference"
))
stopifnot(nrow(table.dt) == length(P$species))

log_section("Part 4: Save")
summary_env.lst <- list(
  data = data.lst,
  means = means.dt,
  differences = differences.dt,
  model = model.lst,
  body_mass_table = table.dt,
  ci_level = P$ci_level,
  figure = body_mass.res$figure,
  slide_figure = body_mass.res$slide_figure,
  timestamp = Sys.time()
)
write_rds_safe(summary_env.lst, output.path, "summary environment")
log_script_end("03_build_summary_env.R", success = TRUE)
