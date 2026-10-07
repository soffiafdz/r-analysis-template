#!/usr/bin/env Rscript
# =============================================================================
# 02_compare_body_mass.R - Body mass by species and sex
# =============================================================================
# Describes body mass by species and sex, estimates the difference between
# males and females within each species (Welch t-intervals), and fits one
# linear model, body_mass ~ species + sex, for the difference adjusted for
# species. The model assumes the same difference in every species; the
# per-species intervals show how far that holds. Draws the figure for the
# report and its slide version.
#
# INPUTS:
#   - data/derivatives/penguins.rds: from 01
# OUTPUTS:
#   - models/results/body_mass.rds: summaries, model estimates, figure paths
#   - outputs/figures/body_mass.pdf, body_mass_slide.png
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(data.table)
})

source(here("R/utils/logging.R"))
source(here("R/utils/config.R"))
source(here("R/utils/data_io.R"))
source(here("R/utils/validation.R"))
source(here("R/utils/plotting.R"))

log_script_start("02_compare_body_mass.R")
config <- load_config()
validate_config(config)
set_seed()

# --- Cache check ---
FORCE_REGENERATE <- get_script_setting(
  "force_regenerate", "compare_body_mass", default = FALSE
)
output.path <- get_data_path("models", "body_mass")
if (!FORCE_REGENERATE && file.exists(output.path)) {
  log_info("Output exists and force_regenerate=FALSE; skipping")
  log_script_end("02_compare_body_mass.R", success = TRUE)
  quit(status = 0)
}

# --- Configuration ---
P <- get_parameter()
OUT <- get_config("output")

log_section("Part 1: Load data")
penguins.res <- read_rds_safe(get_data_path("derivatives", "penguins"))
penguins.dt <- copy(penguins.res$data)
penguins.dt[, species := factor(species, levels = P$species)]
penguins.dt[, sex := factor(sex, levels = P$sexes, labels = P$sex_labels)]
validate_not_empty(penguins.dt, "penguins")

log_section("Part 2: Means by species and sex")
#' Mean with a t-based confidence interval
#' @param x Numeric vector
#' @return One-row data.table
mean_ci.fn <- function(x) {
  half.v <- qt(1 - (1 - P$ci_level) / 2, length(x) - 1) * sd(x) /
    sqrt(length(x))
  data.table(
    n = length(x), mean = mean(x), sd = sd(x),
    lower = mean(x) - half.v, upper = mean(x) + half.v
  )
}
means.dt <- penguins.dt[, mean_ci.fn(body_mass), keyby = .(species, sex)]
stopifnot(nrow(means.dt) == length(P$species) * length(P$sexes))

log_section("Part 3: Male minus female, within each species")
#' Welch interval for the difference in means between males and females
#' @param mass.v Body mass
#' @param sex.fct Sex, with levels P$sex_labels (female first)
#' @return One-row data.table
difference.fn <- function(mass.v, sex.fct) {
  test.res <- t.test(
    mass.v[sex.fct == P$sex_labels[2]], mass.v[sex.fct == P$sex_labels[1]],
    conf.level = P$ci_level
  )
  data.table(
    estimate = unname(test.res$estimate[1] - test.res$estimate[2]),
    lower = test.res$conf.int[1], upper = test.res$conf.int[2]
  )
}
differences.dt <- penguins.dt[, difference.fn(body_mass, sex),
                              keyby = species]

log_section("Part 4: Linear model")
model.fit <- lm(body_mass ~ species + sex, data = penguins.dt)
ci.mat <- confint(model.fit, level = P$ci_level)
coefficients.dt <- data.table(
  term = names(coef(model.fit)), estimate = unname(coef(model.fit)),
  lower = ci.mat[, 1], upper = ci.mat[, 2]
)
fit.lst <- list(
  n = nobs(model.fit), r_squared = summary(model.fit)$r.squared
)
log_info("Model fitted on %d penguins, R squared %.2f",
         fit.lst$n, fit.lst$r_squared)

log_section("Part 5: Figure")
colors.v <- unlist(manuscript_colors()[tolower(P$species)])
names(colors.v) <- P$species
figure.path <- get_data_path("outputs", "body_mass_figure")
slide.path <- get_data_path("outputs", "body_mass_slide")
save_plot(
  plot_body_mass.fn(
    penguins.dt, means.dt, colors.v,
    title = "**Body mass by species and sex.**",
    subtitle = sprintf("%d penguins with complete records", nrow(penguins.dt)),
    caption = sprintf(
      paste("Points: individual penguins. Black: means with %.0f%%",
            "confidence intervals."),
      100 * P$ci_level
    ),
    base_size = 10
  ),
  figure.path, width = OUT$figure_size[1], height = OUT$figure_size[2]
)
save_plot(
  plot_body_mass.fn(
    penguins.dt, means.dt, colors.v,
    title = NULL, subtitle = NULL, caption = NULL,
    base_size = OUT$slide_base_size
  ),
  slide.path,
  width = OUT$slide_figure_size[1], height = OUT$slide_figure_size[2]
)

log_section("Part 6: Save")
results.lst <- list(
  means = means.dt,
  differences = differences.dt,
  coefficients = coefficients.dt,
  fit = fit.lst,
  figure = figure.path,
  slide_figure = slide.path,
  config = P,
  timestamp = Sys.time()
)
write_rds_safe(results.lst, output.path, "body mass results")
log_script_end("02_compare_body_mass.R", success = TRUE)
