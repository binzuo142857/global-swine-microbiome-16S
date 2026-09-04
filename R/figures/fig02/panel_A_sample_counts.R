#!/usr/bin/env Rscript
# Figure 2A — continent sample counts.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

count_data <- read_source_table(data_file("shared/sample_diversity_metadata.tsv.gz")) %>%
  as_tibble() %>%
  filter(continent %in% CONTINENT_ORDER) %>%
  count(continent, name = "sample_count") %>%
  mutate(continent = factor(continent, levels = CONTINENT_ORDER)) %>%
  arrange(sample_count) %>%
  mutate(continent = factor(continent, levels = continent))

p <- ggplot(count_data, aes(sample_count, continent, fill = continent)) +
  geom_col(width = 0.76, alpha = 0.72, color = NA) +
  scale_fill_manual(values = CONTINENT_COLORS, guide = "none") +
  scale_x_continuous(labels = scales::label_comma(), expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Samples", y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank())

save_panel(p, "fig02_panel_A_sample_counts", width_mm = 60, height_mm = 28)
