#!/usr/bin/env Rscript
# Figure 2B — continent Shannon violin from T11.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

alpha_data <- read_source_table(source_table("T11_sample_level_alpha_diversity.tsv.gz")) %>%
  as_tibble() %>%
  filter(continent %in% CONTINENT_ORDER, !is.na(Shannon_index)) %>%
  transmute(
    continent = factor(as.character(continent), levels = CONTINENT_ORDER),
    shannon_entropy = as.numeric(Shannon_index)
  )

ord <- alpha_data %>% count(continent) %>% arrange(n) %>% pull(continent)
alpha_data <- alpha_data %>% mutate(continent = factor(continent, levels = ord))

p <- ggplot(alpha_data, aes(shannon_entropy, continent, fill = continent)) +
  geom_violin(aes(color = continent), alpha = 0.55, width = 0.88, linewidth = 0.24, trim = TRUE) +
  scale_fill_manual(values = CONTINENT_COLORS, guide = "none") +
  scale_color_manual(values = CONTINENT_COLORS, guide = "none") +
  stat_summary(fun = median, geom = "point", size = 0.7, color = "black") +
  labs(x = "Shannon diversity", y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank())

save_panel(p, "fig02_panel_B_shannon", width_mm = 60, height_mm = 40)
