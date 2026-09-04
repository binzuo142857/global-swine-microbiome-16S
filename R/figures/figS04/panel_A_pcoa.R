#!/usr/bin/env Rscript
# Figure S4A — China breed PCoA from T22 (Commercial / Crossbred / Indigenous).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

pcoa <- read_tsv(require_file(source_table("T22_pcoa_coordinates.tsv.gz")), show_col_types = FALSE)

# Harmonize IDs / breed column.
if (!"breed_type" %in% names(pcoa) && "breed" %in% names(pcoa)) {
  # keep as-is; may lack breed_type
}
id_col <- intersect(c("sample_id", "sampleid", "Run"), names(pcoa))[1]
if (is.na(id_col)) stop("T22 lacks sample_id/sampleid/Run")

df <- pcoa %>%
  filter(country == "China") %>%
  filter(breed_type %in% BREED_ORDER_SOURCE) %>%
  transmute(
    sample_id = as.character(.data[[id_col]]),
    breed_type = factor(as.character(breed_type), levels = BREED_ORDER_SOURCE),
    PCo1 = as.numeric(PCo1),
    PCo2 = as.numeric(PCo2)
  ) %>%
  filter(is.finite(PCo1), is.finite(PCo2))

cent <- df %>%
  group_by(breed_type) %>%
  summarise(
    c1 = median(PCo1), c2 = median(PCo2),
    q1lo = quantile(PCo1, 0.25), q1hi = quantile(PCo1, 0.75),
    q2lo = quantile(PCo2, 0.25), q2hi = quantile(PCo2, 0.75),
    .groups = "drop"
  )

p <- ggplot(df, aes(PCo1, PCo2, color = breed_type)) +
  geom_point(alpha = 0.18, size = 0.35) +
  geom_errorbar(data = cent, aes(x = c1, y = c2, xmin = q1lo, xmax = q1hi),
                width = 0, inherit.aes = FALSE, color = "grey20", linewidth = 0.45) +
  geom_errorbar(data = cent, aes(x = c1, y = c2, ymin = q2lo, ymax = q2hi),
                width = 0, inherit.aes = FALSE, color = "grey20", linewidth = 0.45) +
  geom_point(data = cent, aes(c1, c2, fill = breed_type),
             shape = 21, color = "black", size = 2.4, stroke = 0.3, inherit.aes = FALSE) +
  scale_color_manual(values = BREED_COLORS, labels = BREED_LABELS, name = NULL) +
  scale_fill_manual(values = BREED_COLORS, labels = BREED_LABELS, name = NULL) +
  labs(x = "PCoA1", y = "PCoA2") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

save_panel(p, "figS04_panel_A_pcoa", width_mm = 90, height_mm = 90)
