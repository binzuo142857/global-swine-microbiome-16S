#!/usr/bin/env Rscript
# Figure 1C — Shannon histogram + density from T11.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

shannon_data <- read_source_table(source_table("T11_sample_level_alpha_diversity.tsv.gz")) %>%
  as_tibble() %>%
  transmute(shannon_entropy = as.numeric(Shannon_index)) %>%
  filter(!is.na(shannon_entropy))

BINWIDTH <- 0.13
hist_fill <- "#E7C8AD"
hist_border <- "#A77855"
density_color <- "#7B4F3A"
median_color <- "#5C4A42"
median_shannon <- median(shannon_data$shannon_entropy, na.rm = TRUE)
median_label <- paste0("Median = ", round(median_shannon, 2))
hist_breaks <- seq(
  floor(min(shannon_data$shannon_entropy) / BINWIDTH) * BINWIDTH,
  ceiling(max(shannon_data$shannon_entropy) / BINWIDTH) * BINWIDTH + BINWIDTH,
  by = BINWIDTH
)
y_max_count <- max(hist(shannon_data$shannon_entropy, breaks = hist_breaks, plot = FALSE)$counts)

p <- ggplot(shannon_data, aes(shannon_entropy)) +
  geom_histogram(
    aes(y = after_stat(count)), binwidth = BINWIDTH, boundary = 0,
    fill = alpha(hist_fill, 0.78), color = hist_border, linewidth = 0.1, closed = "left"
  ) +
  geom_density(
    aes(y = after_stat(density * nrow(shannon_data) * BINWIDTH)),
    color = density_color, linewidth = 0.7, adjust = 1.05
  ) +
  geom_vline(xintercept = median_shannon, color = median_color, linetype = "dashed", linewidth = 0.45) +
  annotate(
    "label", x = median_shannon - 0.18, y = y_max_count * 0.97,
    label = median_label, hjust = 1, vjust = 1, size = pt_to_mm(7), label.size = 0.1,
    family = FONT, fill = alpha(density_color, 0.30), color = "black"
  ) +
  scale_y_continuous(labels = label_comma(), expand = expansion(mult = c(0, 0.08))) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  labs(x = "Shannon diversity", y = "Samples") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.minor = element_blank())

save_panel(p, "fig01_panel_C_shannon", width_mm = 60, height_mm = 34)
