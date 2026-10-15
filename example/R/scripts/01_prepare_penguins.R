#!/usr/bin/env Rscript
# =============================================================================
# 01_prepare_penguins.R - Check the penguin data and keep complete records
# =============================================================================
# Reads datasets::penguins (shipped with R since 4.5), checks it against its
# help page and keeps the penguins with every measurement and a recorded sex,
# which the body mass comparison needs.
#
# Data: Gorman, Williams & Fraser (2014), doi:10.1371/journal.pone.0090081;
# prepared for R by Horst, Presmanes Hill & Gorman (2022),
# doi:10.32614/RJ-2022-020. Both DOIs checked on Crossref.
#
# INPUTS:
#   - datasets::penguins
# OUTPUTS:
#   - data/derivatives/penguins.rds: complete records and counts
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(data.table)
})

source(here("R/utils/logging.R"))
source(here("R/utils/config.R"))
source(here("R/utils/data_io.R"))
source(here("R/utils/validation.R"))

log_script_start("01_prepare_penguins.R")
config <- load_config()
validate_config(config)
set_seed()

# --- Cache check ---
FORCE_REGENERATE <- get_script_setting(
  "force_regenerate", "prepare_penguins", default = FALSE
)
output.path <- get_data_path("derivatives", "penguins")
if (!FORCE_REGENERATE && file.exists(output.path)) {
  log_info("Output exists and force_regenerate=FALSE; skipping")
  log_script_end("01_prepare_penguins.R", success = TRUE)
  quit(status = 0)
}

# --- Configuration ---
P <- get_parameter()

log_section("Part 1: Check the data against ?datasets::penguins")
penguins.dt <- as.data.table(datasets::penguins)
validate_columns(penguins.dt, P$columns, "penguins")
validate_not_empty(penguins.dt, "penguins")
validate_categorical(penguins.dt, "species", P$species)
validate_categorical(penguins.dt, "island", P$islands)
validate_categorical(penguins.dt, "sex", P$sexes)
validate_categorical(penguins.dt, "year", P$years)
# Lengths in mm and mass in g cannot be negative; the help page gives units
# but no ranges
for (measurement in P$measurements) {
  validate_num_range(penguins.dt, measurement, min_val = 0)
}

log_section("Part 2: Keep complete records")
complete.v <- complete.cases(penguins.dt[, c(P$measurements, "sex"),
                                         with = FALSE])
complete.dt <- penguins.dt[complete.v]
dropped.dt <- penguins.dt[!complete.v, .N, by = species]
log_info(
  "%d of %d penguins have every measurement and a recorded sex",
  nrow(complete.dt), nrow(penguins.dt)
)
validate_not_empty(complete.dt, "complete records")

log_section("Part 3: Save")
results.lst <- list(
  data = complete.dt,
  n = list(
    penguins = nrow(penguins.dt),
    complete = nrow(complete.dt),
    dropped = nrow(penguins.dt) - nrow(complete.dt),
    dropped_by_species = dropped.dt
  ),
  config = P,
  timestamp = Sys.time()
)
write_rds_safe(results.lst, output.path, "complete penguin records")
log_script_end("01_prepare_penguins.R", success = TRUE)
