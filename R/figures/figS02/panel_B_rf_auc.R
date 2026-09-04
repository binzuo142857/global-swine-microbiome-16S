#!/usr/bin/env Rscript
# Figure S2B — RF AUC lollipops from Fig2_RF_AUC_source_data.tsv (also in source table).

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

auc_path <- data_file("figS02/FigureS2B_rf_auc.tsv.gz")

auc_all <- read_tsv(
  require_file(auc_path, "Fig2_RF_AUC_source_data.tsv"),
  show_col_types = FALSE
) %>%
  mutate(
    level = factor(level, levels = c("Continent", "Country")),
    continent = factor(continent, levels = CONTINENT_ORDER)
  )

country_order <- auc_all %>%
  filter(level == "Country") %>%
  arrange(continent, desc(auc)) %>%
  pull(region)
y_levels <- c(CONTINENT_ORDER, country_order)
auc_all <- auc_all %>% mutate(region = factor(region, levels = rev(y_levels)))

make_auc_panel <- function(df, title, show_x = FALSE) {
  ggplot(df, aes(x = auc, y = region, color = continent)) +
    geom_vline(xintercept = c(0.90, 0.95), linetype = "dashed", color = "grey55", linewidth = 0.3) +
    geom_segment(aes(x = 0.85, xend = auc, y = region, yend = region),
                 color = "grey70", linewidth = 0.35) +
    geom_point(size = if (all(df$level == "Continent")) 2.0 else 1.6) +
    geom_text(aes(x = 1.002, label = n_samples), hjust = 0, size = S_AX_TXT / .pt,
              family = FONT, color = "grey25") +
    scale_color_manual(values = CONTINENT_COLORS, guide = "none") +
    scale_x_continuous(limits = c(0.85, 1.02), breaks = seq(0.85, 1.0, 0.05), expand = c(0, 0)) +
    labs(title = title, x = if (show_x) "AUC" else NULL, y = NULL) +
    theme_bw(base_size = S_AX_TXT) +
    base_theme_pub() +
    theme(panel.grid.major.y = element_blank())
}

p <- make_auc_panel(filter(auc_all, level == "Continent"), "Continent classifiers") /
  make_auc_panel(filter(auc_all, level == "Country"), "Country classifiers (top 15)", show_x = TRUE) +
  plot_layout(heights = c(1, 3))

save_panel(p, "figS02_panel_B_rf_auc", width_mm = 130, height_mm = 70)
