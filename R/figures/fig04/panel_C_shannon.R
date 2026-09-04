#!/usr/bin/env Rscript
# Figure 4C — China breed Shannon: violin + slim box + median + BH Wilcoxon stars.
# Geometry matches plot_alpha_China_Breeds_composite_pub.R (not mean±SD).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

alpha <- read_source_table(source_table("T11_sample_level_alpha_diversity.tsv.gz")) %>%
  as_tibble() %>%
  filter(country == "China", breed_type %in% BREED_ORDER_SOURCE, !is.na(Shannon_index)) %>%
  transmute(
    # Original pub uses reverse breed order on y (Commercial at top visually via rev).
    breed_type = factor(as.character(breed_type), levels = rev(BREED_ORDER_SOURCE)),
    shannon = as.numeric(Shannon_index)
  )

if (!nrow(alpha)) stop("No China breed Shannon rows in T11.")

significance_label <- function(p_adj) {
  case_when(
    p_adj < 0.001 ~ "***",
    p_adj < 0.01 ~ "**",
    p_adj < 0.05 ~ "*",
    TRUE ~ "ns"
  )
}

group_levels <- levels(alpha$breed_type)
frozen_tests <- plot_input("fig04_panel_C_shannon_wilcoxon_bh.tsv.gz")
if (!file.exists(frozen_tests)) stop("Missing saved pairwise test results: ", frozen_tests)
pairwise <- read_tsv(frozen_tests, show_col_types = FALSE) %>%
  mutate(y1 = match(group1, group_levels), y2 = match(group2, group_levels), span = abs(y2 - y1))
if (nrow(pairwise) != 3 || anyNA(pairwise$y1) || anyNA(pairwise$y2)) stop("Saved tests do not match three breed groups")
x_max <- max(alpha$shannon, na.rm = TRUE)
x_min <- min(alpha$shannon, na.rm = TRUE)
x_range <- max(x_max - x_min, 1)
sig_df <- pairwise %>%
  filter(sig_label != "ns") %>%
  arrange(span, p_adj, y1, y2) %>%
  mutate(
    level = row_number(),
    x_pos = x_max + level * (0.10 * x_range),
    y_mid = (y1 + y2) / 2
  )
x_max_plot <- if (nrow(sig_df)) {
  max(sig_df$x_pos) + 0.10 * x_range
} else {
  x_max
}

write_tsv(
  pairwise %>% select(group1, group2, p_value, p_adj, sig_label),
  file.path(MANIFEST_DIR, "fig04_panel_C_shannon_wilcoxon_bh.tsv")
)

p <- ggplot(alpha, aes(shannon, breed_type, fill = breed_type)) +
  geom_violin(aes(color = breed_type), alpha = 0.32, linewidth = 0.25, trim = TRUE) +
  geom_boxplot(
    width = 0.15, alpha = 0.55, outlier.shape = NA,
    color = "grey15", fill = "white", linewidth = 0.28
  ) +
  stat_summary(fun = median, geom = "point", size = 1.0, color = "black") +
  scale_fill_manual(values = BREED_COLORS, guide = "none") +
  scale_color_manual(values = BREED_COLORS, guide = "none") +
  scale_y_discrete(labels = BREED_LABELS) +
  labs(x = "Shannon diversity", y = NULL, title = "Shannon diversity") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = S_AX_TXT, hjust = 0.5)
  )

if (nrow(sig_df)) {
  p <- p +
    geom_segment(
      data = sig_df,
      aes(x = x_pos, xend = x_pos, y = y1, yend = y2),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    geom_segment(
      data = sig_df,
      aes(x = x_pos - 0.018 * x_range, xend = x_pos, y = y1, yend = y1),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    geom_segment(
      data = sig_df,
      aes(x = x_pos - 0.018 * x_range, xend = x_pos, y = y2, yend = y2),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    geom_text(
      data = sig_df,
      aes(x = x_pos + 0.012 * x_range, y = y_mid, label = sig_label),
      inherit.aes = FALSE, size = 2.2, hjust = 0
    ) +
    coord_cartesian(xlim = c(x_min, x_max_plot), clip = "off")
}

save_panel(p, "fig04_panel_C_shannon", width_mm = 80, height_mm = 45)
