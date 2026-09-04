#!/usr/bin/env Rscript
# Shared helper: enterotype PCoA panel.

make_enterotype_pcoa <- function(scope, title, max_per_group = 900, title_size = S_TITLE,
                                 palette = NULL) {
  coords <- read_tsv(
    file.path(DATA_DIR, "fig05/Figure5CEFGHI_enterotype_coordinates.tsv.gz"),
    show_col_types = FALSE
  ) %>% filter(analysis_scope == scope)
  vars <- read_tsv(
    file.path(DATA_DIR, "fig05/Figure5CFGHI_axis_variance.tsv.gz"),
    show_col_types = FALSE
  ) %>% filter(analysis_scope == scope)

  pdat <- coords %>%
    transmute(
      sampleid = sample_id,
      enterotype = factor(as.character(enterotype),
                          levels = sort(unique(as.character(enterotype)))),
      PCo1 = as.numeric(PCo1),
      PCo2 = as.numeric(PCo2)
    ) %>%
    filter(!is.na(enterotype), is.finite(PCo1), is.finite(PCo2))

  set.seed(20260707)
  pdat_sample <- pdat %>%
    group_by(enterotype) %>%
    group_modify(~ dplyr::slice_sample(.x, n = min(max_per_group, nrow(.x)))) %>%
    ungroup()
  stats <- pdat %>%
    group_by(enterotype) %>%
    summarise(
      c1 = median(PCo1), c2 = median(PCo2),
      q1_lo = quantile(PCo1, 0.25), q1_hi = quantile(PCo1, 0.75),
      q2_lo = quantile(PCo2, 0.25), q2_hi = quantile(PCo2, 0.75),
      .groups = "drop"
    )

  et_levels <- levels(pdat$enterotype)
  if (is.null(palette)) {
    palette <- if (length(et_levels) <= 2) {
      c("1" = "#23395B", "2" = "#F2C14E")
    } else {
      c("#00A6D6", "#D45087", "#2F9E44", "#9467BD", "#8C564B",
        "#17BECF", "#BCBD22", "#E377C2", "#7F7F7F", "#1B9E77")
    }
  }
  cols <- setNames(rep(unname(palette), length.out = length(et_levels)), et_levels)
  p1 <- vars$PCo1_variance_fraction[1]
  p2 <- vars$PCo2_variance_fraction[1]
  x_lab <- paste0("PCo1 (", round(p1 * 100, 1), "%)")
  y_lab <- paste0("PCo2 (", round(p2 * 100, 1), "%)")

  ggplot() +
    geom_bin2d(data = pdat_sample, aes(PCo1, PCo2, fill = after_stat(count)),
               bins = 70, alpha = 0.20, show.legend = FALSE) +
    scale_fill_gradient(low = "grey96", high = "grey45", guide = "none") +
    geom_point(data = pdat_sample, aes(PCo1, PCo2, color = enterotype),
               alpha = 0.30, size = 0.30, stroke = 0) +
    geom_segment(data = stats, aes(x = q1_lo, xend = q1_hi, y = c2, yend = c2, color = enterotype),
                 linewidth = 0.42, lineend = "round") +
    geom_segment(data = stats, aes(x = c1, xend = c1, y = q2_lo, yend = q2_hi, color = enterotype),
                 linewidth = 0.42, lineend = "round") +
    geom_point(data = stats, aes(c1, c2, color = enterotype),
               shape = 21, fill = "white", size = 1.60, stroke = 0.40) +
    scale_color_manual(values = cols, guide = "none") +
    labs(title = title, x = x_lab, y = y_lab) +
    theme_bw(base_size = S_AX_TXT) +
    base_theme_pub() +
    theme(
      plot.title = element_text(size = title_size),
      panel.grid.minor = element_blank()
    )
}
