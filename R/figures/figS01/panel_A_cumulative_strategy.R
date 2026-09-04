#!/usr/bin/env Rscript
# Figure S1A — cumulative samples over time by LibraryStrategy (from SraRunInfo).

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(lubridate)
  library(scales)
  library(ragg)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

strategy_colors <- c(
  "AMPLICON" = "#2A6F73", "WGS" = "#C1666B", "RNA-Seq" = "#D4A373",
  "WXS" = "#6D6875", "Other" = "grey70"
)

cum <- read_tsv(source_table("T39_cumulative_samples_by_library_strategy.tsv.gz"), show_col_types = FALSE)

cum <- cum %>%
  mutate(
    ReleaseDate = as_date(ReleaseDate),
    LibraryStrategy = as.character(LibraryStrategy),
    cum_n = as.numeric(cum_n)
  )

p <- ggplot(cum, aes(ReleaseDate, cum_n, color = LibraryStrategy)) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = strategy_colors, name = NULL) +
  scale_y_continuous(labels = label_comma()) +
  labs(x = NULL, y = "Cumulative samples", title = "Samples over time") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

save_panel(p, "figS01_panel_A_cumulative_strategy", width_mm = 70, height_mm = 55)
