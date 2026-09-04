#!/usr/bin/env Rscript
# Figure 5A — gut-site Shannon from T11.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

gut_order <- c("stomach", "duodenum", "jejunum", "ileum", "cecum", "colon", "feces")
gut_cols <- c(
  stomach = "#4E79A7", duodenum = "#59A14F", jejunum = "#9C755F", ileum = "#F28E2B",
  cecum = "#E15759", colon = "#B07AA1", feces = "#6B6B6B"
)

df <- read_source_table(source_table("T11_sample_level_alpha_diversity.tsv.gz")) %>%
  as_tibble() %>%
  mutate(gut_region = tolower(as.character(gut_region))) %>%
  filter(gut_region %in% gut_order, !is.na(Shannon_index)) %>%
  transmute(
    gut_region = factor(gut_region, levels = rev(gut_order)),
    shannon = as.numeric(Shannon_index)
  )

p <- ggplot(df, aes(shannon, gut_region, fill = gut_region)) +
  geom_violin(scale = "width", linewidth = 0.2, alpha = 0.75, color = "grey30") +
  scale_fill_manual(values = gut_cols, guide = "none") +
  scale_y_discrete(labels = function(x) stringr::str_to_title(x)) +
  labs(x = "Shannon diversity", y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank())

save_panel(p, "fig05_panel_A_gut_shannon", width_mm = 90, height_mm = 52)
