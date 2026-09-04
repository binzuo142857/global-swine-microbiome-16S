#!/usr/bin/env Rscript
# Figure 4B — China breed-group sample counts (Commercial / Crossbred / Indigenous).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

counts <- read_source_table(data_file("shared/sample_diversity_metadata.tsv.gz")) %>%
  as_tibble() %>%
  filter(country == "China", breed_type %in% BREED_ORDER_SOURCE) %>%
  count(breed_type, name = "sample_count") %>%
  mutate(
    breed_type = factor(breed_type, levels = BREED_ORDER_SOURCE),
    breed_label = BREED_LABELS[as.character(breed_type)]
  )

p <- ggplot(counts, aes(sample_count, breed_type, fill = breed_type)) +
  geom_col(width = 0.7, alpha = 0.9) +
  geom_text(aes(label = sample_count), hjust = -0.1, size = pt_to_mm(6.5), family = FONT) +
  scale_fill_manual(values = BREED_COLORS, labels = BREED_LABELS, guide = "none") +
  scale_y_discrete(labels = BREED_LABELS, limits = rev(BREED_ORDER_SOURCE)) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15)), labels = scales::label_comma()) +
  labs(x = "Samples", y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank())

save_panel(p, "fig04_panel_B_group_counts", width_mm = 65, height_mm = 40)
