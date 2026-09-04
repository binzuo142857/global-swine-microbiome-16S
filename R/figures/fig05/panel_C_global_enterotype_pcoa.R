#!/usr/bin/env Rscript
# Figure 5C — global feces enterotype PCoA.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))
source(file.path(REPO_ROOT, "R", "common", "enterotype_pcoa.R"))

p <- make_enterotype_pcoa("global_feces", title = NULL, max_per_group = 3000)
save_panel(p, "fig05_panel_C_global_enterotype_pcoa", width_mm = 58, height_mm = 52)
