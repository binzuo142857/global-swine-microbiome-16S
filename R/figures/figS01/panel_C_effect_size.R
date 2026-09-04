#!/usr/bin/env Rscript
# Figure S1C — technical-factor Cohen's f on Shannon from T15.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

t15 <- read_source_table(source_table("T15_technical_factor_effects_shannon.tsv.gz")) %>%
  as_tibble() %>%
  transmute(
    Factor = as.character(Factor),
    Cohens_f = as.numeric(Cohens_f)
  ) %>%
  arrange(Cohens_f) %>%
  mutate(Factor = factor(Factor, levels = Factor))

p <- ggplot(t15, aes(Cohens_f, Factor)) +
  geom_col(fill = "#2A6F73", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = sprintf("%.3f", Cohens_f)), hjust = -0.1, size = pt_to_mm(6), family = FONT) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Cohen's f (Shannon)", y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank())

save_panel(p, "figS01_panel_C_effect_size", width_mm = 70, height_mm = 45)
