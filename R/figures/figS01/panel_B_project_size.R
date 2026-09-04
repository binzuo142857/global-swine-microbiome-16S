#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

proj <- read_tsv(source_table("T40_samples_per_bioproject.tsv.gz"), show_col_types = FALSE)

med_proj <- median(proj$Sample_Count)
long_tail <- proj %>% filter(Sample_Count > quantile(Sample_Count, 0.99))

p <- ggplot(proj, aes(Sample_Count)) +
  geom_histogram(bins = 40, fill = "#2A6F73", color = "white", linewidth = 0.1, boundary = 0) +
  geom_vline(xintercept = med_proj, linetype = "dashed", color = "#1B454C", linewidth = 0.4) +
  annotate("text", x = med_proj, y = Inf, label = paste0("  median = ", med_proj),
           hjust = 0, vjust = 1.5, size = pt_to_mm(6), family = FONT, color = "#1B454C") +
  scale_x_continuous(labels = comma_format()) +
  scale_y_continuous(labels = comma_format(), expand = expansion(mult = c(0, 0.08))) +
  labs(title = "Samples per project", x = "Samples in project", y = "Projects") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.minor = element_blank())

save_panel(p, "figS01_panel_B_project_size", width_mm = 70, height_mm = 55)
