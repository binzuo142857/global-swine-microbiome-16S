#!/usr/bin/env Rscript
# Figure 3E — unidentified taxa by rank × continent from T36.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

src <- file.path(SOURCE_TABLES, "T36_unidentified_taxa_by_continent_rank.tsv.gz")
unid <- if (grepl("\\.xlsx$", src)) read_source_table(src) %>% as_tibble() else read_tsv(src, show_col_types = FALSE)

unid_data <- unid %>%
  transmute(
    continent = factor(as.character(continent), levels = CONTINENT_ORDER),
    Rank = factor(as.character(taxonomic_rank),
                  levels = c("Genus", "Family", "Order", "Class", "Phylum")),
    Avg_Unidentified = as.numeric(mean_unidentified),
    SD_Unidentified = as.numeric(sd_unidentified)
  )

p <- ggplot(unid_data, aes(Rank, Avg_Unidentified, fill = continent)) +
  geom_col(position = position_dodge(width = 0.68), width = 0.62, linewidth = 0.15) +
  geom_errorbar(
    aes(ymin = pmax(0, Avg_Unidentified - SD_Unidentified),
        ymax = Avg_Unidentified + SD_Unidentified),
    position = position_dodge(width = 0.68), width = 0.18, linewidth = 0.22
  ) +
  scale_fill_manual(values = CONTINENT_COLORS, guide = "none") +
  labs(x = NULL, y = "Unidentified taxa") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1),
        panel.grid.major.x = element_blank())

save_panel(p, "fig03_panel_E_unidentified", width_mm = 70, height_mm = 55)
