#!/usr/bin/env Rscript
# Figure 5F–I — stage-specific feces enterotype PCoA panels from T37.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
  library(patchwork)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))
source(file.path(REPO_ROOT, "R", "common", "enterotype_pcoa.R"))

et_multi <- c("#00A6D6", "#D45087", "#2F9E44", "#9467BD", "#8C564B",
              "#17BECF", "#BCBD22", "#E377C2", "#7F7F7F", "#1B9E77")

pF <- make_enterotype_pcoa("feces_lactation", "Enterotype in Lactation", 1200, S_TITLE - 0.5, et_multi)
pG <- make_enterotype_pcoa("feces_nursery", "Enterotype in Nursery", 850, S_TITLE - 0.5, et_multi)
pH <- make_enterotype_pcoa("feces_growing", "Enterotype in Growing", 850, S_TITLE - 0.5, et_multi)
pI <- make_enterotype_pcoa("feces_finishing", "Enterotype in Finishing", 650, S_TITLE - 0.5, et_multi)

save_panel(pF, "fig05_panel_F_lactation_pcoa", width_mm = 44, height_mm = 50)
save_panel(pG, "fig05_panel_G_nursery_pcoa", width_mm = 44, height_mm = 50)
save_panel(pH, "fig05_panel_H_growing_pcoa", width_mm = 44, height_mm = 50)
save_panel(pI, "fig05_panel_I_finishing_pcoa", width_mm = 44, height_mm = 50)

p <- pF | pG | pH | pI
save_panel(p, "fig05_panel_FGHI_stage_pcoa_row", width_mm = 180, height_mm = 50)
