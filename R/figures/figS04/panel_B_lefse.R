#!/usr/bin/env Rscript
# Figure S4B — China breed LEfSe |LDA|>=3.5 bar + abundance bubble.
# Abundance layer from original combo_right_data.tsv:
#   size = mean_abund; fill = row_centered_log_abund (not breed color).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
  library(patchwork)
  library(RColorBrewer)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

combo_path <- data_file("figS04/FigureS4B_lefse_abundance.tsv.gz")

combo <- read_tsv(combo_path, show_col_types = FALSE) %>%
  mutate(
    breed_type = factor(as.character(breed_type), levels = BREED_ORDER_SOURCE),
    enriched_breed_type = factor(as.character(enriched_breed_type), levels = BREED_ORDER_SOURCE),
    plot_label_ordered = as.character(plot_label_ordered),
    abs_lda = as.numeric(abs_lda),
    mean_abund = as.numeric(mean_abund),
    row_centered_log_abund = as.numeric(row_centered_log_abund),
    highlight_cell = as.logical(highlight_cell)
  )
# Source already encodes |LDA|>=3.5 marker set from original combo script.

# Left bar: one row per taxon (enriched breed / LDA from source)
left_df <- combo %>%
  group_by(plot_label_ordered) %>%
  summarise(
    abs_lda = max(abs_lda, na.rm = TRUE),
    enriched_breed_type = dplyr::first(na.omit(enriched_breed_type)),
    .groups = "drop"
  ) %>%
  filter(is.finite(abs_lda), abs_lda >= 3.5) %>%
  arrange(enriched_breed_type, desc(abs_lda)) %>%
  mutate(plot_label_ordered = factor(plot_label_ordered, levels = unique(plot_label_ordered)))

combo <- combo %>%
  mutate(plot_label_ordered = factor(plot_label_ordered, levels = levels(left_df$plot_label_ordered))) %>%
  filter(!is.na(plot_label_ordered))

if (any(!is.finite(combo$mean_abund)) || any(!is.finite(combo$row_centered_log_abund))) {
  stop("S4B combo source missing mean_abund or row_centered_log_abund; refuse substitutes.")
}

fill_lim <- max(abs(combo$row_centered_log_abund), na.rm = TRUE)
plot_colors <- rev(brewer.pal(11, "RdBu"))

p_bar <- ggplot(left_df, aes(abs_lda, plot_label_ordered, fill = enriched_breed_type)) +
  geom_col(width = 0.75) +
  scale_fill_manual(values = BREED_COLORS, labels = BREED_LABELS, name = NULL) +
  labs(x = "Absolute LDA score", y = NULL, title = "LEfSe (|LDA| ≥ 3.5)") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.y = element_text(size = 5.2, face = "italic"),
    panel.grid.major.y = element_blank(),
    legend.position = "bottom"
  )

p_bubble <- ggplot(combo, aes(breed_type, plot_label_ordered)) +
  geom_point(
    aes(size = mean_abund, fill = row_centered_log_abund),
    shape = 21, color = "grey40", stroke = 0.2, alpha = 0.95
  ) +
  geom_point(
    data = combo %>% filter(replace_na(highlight_cell, FALSE)),
    aes(size = mean_abund),
    shape = 21, fill = NA, color = "black", stroke = 0.55
  ) +
  scale_fill_gradientn(
    colors = plot_colors,
    limits = c(-fill_lim, fill_lim),
    name = "Row-centered\nlog10 abund"
  ) +
  scale_x_discrete(labels = BREED_LABELS) +
  scale_size_continuous(range = c(1.2, 5.5), name = "Mean abund") +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom"
  )

p <- (p_bar + p_bubble + plot_layout(widths = c(1.5, 1.0), guides = "collect")) &
  theme(legend.position = "bottom", legend.box = "vertical")
save_panel(p, "figS04_panel_B_lefse", width_mm = 180, height_mm = 150)
