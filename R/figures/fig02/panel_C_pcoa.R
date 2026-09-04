#!/usr/bin/env Rscript
# Figure 2C — continent Bray-Curtis PCoA density + IQR crosshairs from T22.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
  library(patchwork)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

df <- read_tsv(require_file(source_table("T22_pcoa_coordinates.tsv.gz")), show_col_types = FALSE) %>%
  filter(continent %in% CONTINENT_ORDER) %>%
  transmute(
    continent = factor(as.character(continent), levels = CONTINENT_ORDER),
    PCo1 = as.numeric(PCo1),
    PCo2 = as.numeric(PCo2)
  ) %>%
  filter(is.finite(PCo1), is.finite(PCo2))

stats <- df %>%
  group_by(continent) %>%
  summarise(
    n = n(),
    c1 = median(PCo1), c2 = median(PCo2),
    q1lo = quantile(PCo1, 0.25), q1hi = quantile(PCo1, 0.75),
    q2lo = quantile(PCo2, 0.25), q2hi = quantile(PCo2, 0.75),
    .groups = "drop"
  )

x_lim <- range(df$PCo1)
y_lim <- range(df$PCo2)

make_one <- function(cont) {
  d <- df %>% filter(continent == cont)
  s <- stats %>% filter(continent == cont)
  ggplot(d, aes(PCo1, PCo2)) +
    geom_bin2d(bins = 50) +
    scale_fill_gradient(low = "#FEE6CE", high = "#A63603", trans = "log10", guide = "none") +
    geom_errorbar(data = s, aes(x = c1, y = c2, xmin = q1lo, xmax = q1hi),
                  inherit.aes = FALSE, width = 0, color = "black", linewidth = 0.35) +
    geom_errorbar(data = s, aes(x = c1, y = c2, ymin = q2lo, ymax = q2hi),
                  inherit.aes = FALSE, width = 0, color = "black", linewidth = 0.35) +
    geom_point(data = s, aes(c1, c2), size = 1.6, color = "black") +
    coord_cartesian(xlim = x_lim, ylim = y_lim) +
    labs(title = cont, x = NULL, y = NULL) +
    theme_bw(base_size = S_AX_TXT) +
    base_theme_pub() +
    theme(
      plot.title = element_text(size = S_AX_TXT),
      panel.grid.minor = element_blank()
    )
}

panels <- lapply(CONTINENT_ORDER, make_one)
p <- wrap_plots(panels, ncol = 3)

save_panel(p, "fig02_panel_C_pcoa", width_mm = 120, height_mm = 70)
