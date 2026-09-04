#!/usr/bin/env Rscript
# Figure 1H — taxonomic accumulation curves from T14.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

t14_path <- require_file(source_table("T14_taxon_accumulation_discovery.tsv.gz"))
rare <- read_tsv(t14_path, show_col_types = FALSE)

# Prefer global sample accumulation rows if present.
if ("analysis_scope" %in% names(rare)) {
  scopes <- unique(as.character(rare$analysis_scope))
  prefer <- scopes[grepl("global.*accum|sample_accum|rarefaction", scopes, ignore.case = TRUE)]
  if (length(prefer) >= 1L) rare <- rare %>% filter(analysis_scope == prefer[[1]])
}

# Harmonize column names.
nm <- names(rare)
if (!"Level" %in% nm) {
  if ("taxonomic_rank" %in% nm) rare <- rare %>% rename(Level = taxonomic_rank)
  else if ("rank" %in% nm) rare <- rare %>% rename(Level = rank)
}
if (!"Samples" %in% nm && "sample_size" %in% nm) rare <- rare %>% rename(Samples = sample_size)
if (!"Richness" %in% nm) {
  if ("mean_cumulative_taxa" %in% nm) rare <- rare %>% rename(Richness = mean_cumulative_taxa)
  else if ("mean_richness" %in% nm) rare <- rare %>% rename(Richness = mean_richness)
  else if ("richness" %in% nm) rare <- rare %>% rename(Richness = richness)
}

rare <- rare %>%
  transmute(
    Level = as.character(Level),
    Samples = as.numeric(Samples),
    Richness = as.numeric(Richness)
  ) %>%
  filter(Level %in% c("Phylum", "Class", "Order", "Family", "Genus")) %>%
  mutate(Level = factor(Level, levels = c("Phylum", "Class", "Order", "Family", "Genus")))

level_palette_dark <- c(
  Phylum = "#8F6AAE", Class = "#5FA6A8", Order = "#C28E5B",
  Family = "#6E9A69", Genus = "#5C88A8"
)

rare_ds <- rare %>%
  group_by(Level) %>%
  group_modify(~ {
    n <- nrow(.x)
    if (n <= 1500) return(.x)
    .x[unique(round(seq(1, n, length.out = 1500))), , drop = FALSE]
  }) %>%
  ungroup()

rare_ends <- rare_ds %>%
  group_by(Level) %>%
  slice_max(Samples, n = 1, with_ties = FALSE) %>%
  ungroup()

p <- ggplot(rare_ds, aes(Samples, Richness, color = Level, group = Level)) +
  geom_line(linewidth = 0.8, lineend = "round") +
  geom_text(
    data = rare_ends, aes(label = Level), hjust = 0, fontface = "bold",
    nudge_x = max(rare_ds$Samples) * 0.02, size = pt_to_mm(6.5), family = FONT
  ) +
  scale_color_manual(values = level_palette_dark, guide = "none") +
  scale_x_continuous(labels = label_number(scale = 1e-3, suffix = "K"),
                     expand = expansion(mult = c(0.01, 0.20))) +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(clip = "off") +
  labs(x = "Samples", y = "Unique taxa") +
  theme_classic(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(legend.position = "none", plot.margin = margin(2, 9, 2, 3))

save_panel(p, "fig01_panel_H_rarefaction", width_mm = 55, height_mm = 60)
