# =============================================================================
# Plotting Utilities
# =============================================================================
# Generic theme, colours and saving with ggplot2. Project-specific
# plot_<thing>() functions go below the generic section.
# =============================================================================

source(here::here("R/utils/data_io.R"))

# ----- Color Palettes -----

#' Color palettes for manuscript figures
#'
#' The single source of colours for every figure, so a variable has the same
#' colour everywhere. Do not redefine colours in individual plotting
#' functions; add a named entry here instead.
#'
#' @return Named list of color values
manuscript_colors <- function() {
  list(
    female = "#8B0000",        # Dark red
    male = "#191970",          # Midnight blue
    combined = "gray40",
    reference_line = "gray50"
    # Project entries go here: one per group, predictor or measure, taken
    # from the tol_bright or tol_muted palettes in get_palette
  )
}

#' Get standard color palette
#'
#' Colourblind-safe palettes. Use manuscript_colors() for named, per-variable
#' colours.
#'
#' @param type "default" (Okabe-Ito), "tol_bright", "tol_muted", "sex",
#'   "sex_md" (ggtext labels)
#' @return Color vector
get_palette <- function(type = "default") {
  colors.lst <- manuscript_colors()
  palettes <- list(
    default = c(
      "#999999", "#E69F00", "#56B4E9", "#009E73",
      "#F0E442", "#0072B2", "#D55E00", "#CC79A7"
    ),
    # Paul Tol, https://personal.sron.nl/~pault/
    tol_bright = c(
      blue = "#4477AA", cyan = "#66CCEE", green = "#228833",
      yellow = "#CCBB44", red = "#EE6677", purple = "#AA3377",
      grey = "#BBBBBB"
    ),
    tol_muted = c(
      indigo = "#332288", cyan = "#88CCEE", teal = "#44AA99",
      green = "#117733", olive = "#999933", sand = "#DDCC77",
      rose = "#CC6677", wine = "#882255", purple = "#AA4499"
    ),
    sex = c(
      Female = colors.lst$female,
      Male = colors.lst$male,
      Combined = colors.lst$combined
    ),
    sex_md = c(
      Female = sprintf(
        "<span style='color: %s;'>Female</span>", colors.lst$female
      ),
      Male = sprintf(
        "<span style='color: %s;'>Male</span>", colors.lst$male
      )
    )
  )

  if (!type %in% names(palettes)) {
    stop("Unknown palette: ", type, call. = FALSE)
  }
  palettes[[type]]
}

# ----- Plot Themes -----

#' Standard ggplot theme for publications
#' @param base_size Base font size
#' @param use_markdown Whether to use ggtext markdown in axis titles and text,
#'   strips and the plot title (requires the ggtext package)
#' @return ggplot2 theme object
theme_publication <- function(base_size = 10, use_markdown = FALSE) {
  base_theme <- ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      text = ggplot2::element_text(size = base_size),
      axis.text = ggplot2::element_text(size = base_size - 1),
      plot.caption = ggplot2::element_text(size = base_size - 3),
      legend.position = "bottom"
    )

  if (use_markdown) {
    if (!requireNamespace("ggtext", quietly = TRUE)) {
      stop("use_markdown = TRUE requires the ggtext package", call. = FALSE)
    }
    base_theme <- base_theme +
      ggplot2::theme(
        axis.title.x = ggtext::element_markdown(),
        axis.title.y = ggtext::element_markdown(),
        axis.text.x = ggtext::element_markdown(),
        axis.text.y = ggtext::element_markdown(),
        strip.text = ggtext::element_markdown(),
        plot.title = ggtext::element_markdown()
      )
  }

  base_theme
}

# ----- Plot Helpers -----

#' Save plot with standard settings
#' @param plot ggplot object
#' @param filename Output filename; the extension sets the format
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Resolution
save_plot <- function(plot, filename, width = 7, height = 7, dpi = 600) {
  ensure_directory(dirname(filename))

  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi
  )

  invisible(filename)
}

#' Wrap long text (titles, captions)
#' @param text Text to wrap, or NULL
#' @param width Maximum line width
#' @param indent Indentation for wrapped lines
#' @return Wrapped text, or NULL for NULL
wrap_text <- function(text, width = 100, indent = 0) {
  # str_wrap(NULL) gives character(0), for which ggplot2 still lays out a
  # label; NULL leaves it out
  if (is.null(text)) return(NULL)
  stringr::str_wrap(text, width = width, exdent = indent)
}

#' Coefficient plot: estimates with CIs, by group
#' @param data Data frame
#' @param x Term variable (axis after coord_flip)
#' @param y Estimate variable
#' @param group Grouping variable (colour and shape)
#' @param ci_lower Lower CI bound variable
#' @param ci_upper Upper CI bound variable
#' @param sig Optional variable with values "sig" / "non-sig"
#' @param colors Color palette
#' @return ggplot object
plot_comparison <- function(data, x, y, group, ci_lower, ci_upper,
                            sig = NULL, colors = NULL) {
  if (is.null(colors)) {
    colors <- get_palette("default")
  }

  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data[[x]], y = .data[[y]],
      colour = .data[[group]], group = .data[[group]]
    )
  )

  if (!is.null(sig)) {
    p <- p + ggplot2::aes(alpha = .data[[sig]])
  }

  p <- p +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data[[ci_lower]], ymax = .data[[ci_upper]]),
      position = ggplot2::position_dodge(width = 1),
      width = 0
    ) +
    ggplot2::geom_point(
      ggplot2::aes(shape = .data[[group]]),
      position = ggplot2::position_dodge(width = 1),
      size = 0.75
    ) +
    ggplot2::geom_hline(
      yintercept = 0,
      linetype = "dashed",
      alpha = 0.5,
      colour = manuscript_colors()$reference_line
    ) +
    ggplot2::scale_colour_manual(values = colors) +
    theme_publication()

  if (!is.null(sig)) {
    p <- p +
      ggplot2::scale_alpha_manual(
        values = c("non-sig" = 0.5, "sig" = 1),
        guide = "none"
      )
  }

  p + ggplot2::coord_flip()
}

# =============================================================================
# Project-specific figures: one plot_<thing>() per figure
# =============================================================================
