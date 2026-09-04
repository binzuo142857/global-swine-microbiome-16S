#!/usr/bin/env Rscript
# Figure 5D — top driver taxon abundances by global feces enterotype from T38.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

box_df <- read_tsv(
  file.path(SOURCE_TABLES, "T38_enterotype_driver_taxon_relative_abundance.tsv.gz"),
  show_col_types = FALSE
) %>%
  mutate(
    enterotype = factor(as.character(enterotype), levels = c("1", "2")),
    taxon_short = factor(taxon_short, levels = unique(taxon_short))
  )

et2_cols <- c("1" = "#23395B", "2" = "#F2C14E")

p <- ggplot(box_df, aes(x = taxon_short, y = relative_abundance * 100, fill = enterotype)) +
  geom_boxplot(outlier.size = 0.08, linewidth = 0.20, alpha = 0.72,
               width = 0.62, position = position_dodge(width = 0.70)) +
  scale_fill_manual(values = et2_cols, guide = "none") +
  labs(x = NULL, y = "Relative abundance (%)") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1, size = S_AX_TXT - 1, face = "italic")
  )

save_panel(p, "fig05_panel_D_driver_boxplots", width_mm = 58, height_mm = 52)
