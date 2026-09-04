#!/usr/bin/env Rscript
# Figure 5B — gut-site PCoA ridgelines from T22.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggridges)
  library(ragg)
  library(patchwork)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

gut_order <- c("stomach", "duodenum", "jejunum", "ileum", "cecum", "colon", "feces")
gut_cols <- c(
  stomach = "#4E79A7", duodenum = "#59A14F", jejunum = "#9C755F", ileum = "#F28E2B",
  cecum = "#E15759", colon = "#B07AA1", feces = "#6B6B6B"
)

df <- read_tsv(require_file(source_table("T22_pcoa_coordinates.tsv.gz")), show_col_types = FALSE) %>%
  mutate(gut_region = tolower(as.character(gut_region))) %>%
  filter(gut_region %in% gut_order) %>%
  transmute(
    gut_region = factor(gut_region, levels = rev(gut_order)),
    PCo1 = as.numeric(PCo1),
    PCo2 = as.numeric(PCo2),
    PCo3 = as.numeric(PCo3)
  ) %>%
  pivot_longer(c(PCo1, PCo2, PCo3), names_to = "PC_axis", values_to = "PC_value") %>%
  filter(is.finite(PC_value))

set.seed(20260707)
df_plot <- df %>%
  group_by(PC_axis, gut_region) %>%
  group_modify(~ dplyr::slice_sample(.x, n = min(500, nrow(.x)))) %>%
  ungroup()

make_ridge <- function(axis_name) {
  ggplot(filter(df_plot, PC_axis == axis_name),
         aes(x = PC_value, y = gut_region, fill = gut_region)) +
    geom_density_ridges(alpha = 0.7, scale = 0.92, color = "white", linewidth = 0.25,
                        quantile_lines = TRUE, quantiles = 0.5, rel_min_height = 0.01) +
    scale_fill_manual(values = gut_cols, guide = "none") +
    scale_y_discrete(labels = function(x) stringr::str_to_title(x)) +
    labs(title = axis_name, x = NULL, y = NULL) +
    theme_bw(base_size = S_AX_TXT) +
    base_theme_pub() +
    theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), panel.grid.major.y = element_blank())
}

p <- make_ridge("PCo1") | make_ridge("PCo2") | make_ridge("PCo3")
save_panel(p, "fig05_panel_B_gut_pcoa_ridges", width_mm = 90, height_mm = 52)
