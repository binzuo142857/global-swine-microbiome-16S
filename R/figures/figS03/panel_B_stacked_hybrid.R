#!/usr/bin/env Rscript
# Figure S3B — hybrid per-sample stacked phylum composition by continent.
# Source classes: Firmicutes, Bacteroidota, Proteobacteria, Fusobacteriota,
# Spirochaetota, Other. Keep seed-123 hybrid_panel_order; assert full mapping.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

src <- require_file(
  file.path(DATA_DIR, "figS03/FigureS3B_phylum_composition.tsv.gz"),
  "figS03/FigureS3B_phylum_composition.tsv.gz"
)
raw <- read_source_table(src) %>% as_tibble()
df <- raw %>%
  transmute(
    sample_id = as.character(sample_id),
    continent = factor(as.character(continent), levels = CONTINENT_ORDER),
    phylum_group = as.character(phylum_group),
    relative_abundance = as.numeric(relative_abundance),
    hybrid_panel_order = as.integer(hybrid_panel_order),
    sampling_seed = if ("sampling_seed" %in% names(raw)) as.integer(sampling_seed) else NA_integer_
  ) %>%
  filter(!is.na(continent), !is.na(hybrid_panel_order))

paired <- RColorBrewer::brewer.pal(12, "Paired")
phylum_cols <- c(
  Firmicutes = paired[9],
  Bacteroidota = paired[2],
  Proteobacteria = paired[4],
  Fusobacteriota = paired[8],
  Spirochaetota = paired[6],
  Other = "grey80"
)

unmapped <- setdiff(unique(df$phylum_group), names(phylum_cols))
if (length(unmapped)) {
  stop("Unmapped phylum_group in S3B hybrid source: ", paste(unmapped, collapse = ", "))
}
seeds <- unique(na.omit(df$sampling_seed))
if (length(seeds) && !all(seeds == 123L)) {
  warning("sampling_seed is not 123: ", paste(seeds, collapse = ","))
}

# Closure check per displayed sample
closure <- df %>%
  group_by(sample_id, continent, hybrid_panel_order) %>%
  summarise(s = sum(relative_abundance), .groups = "drop")
bad_closure <- closure %>% filter(!is.finite(s) | abs(s - 1) > 1e-4)
if (nrow(bad_closure)) {
  warning("S3B closure off by >1e-4 for ", nrow(bad_closure), " sample rows (kept as source).")
}

df <- df %>%
  mutate(
    phylum_group = factor(phylum_group, levels = rev(names(phylum_cols))),
    sample_id = fct_reorder(sample_id, hybrid_panel_order)
  )

message(
  "S3B displayed samples=", n_distinct(df$sample_id),
  " phyla=", paste(names(phylum_cols), collapse = ",")
)

p <- ggplot(df, aes(sample_id, relative_abundance, fill = phylum_group)) +
  geom_col(width = 1, color = NA) +
  scale_fill_manual(values = phylum_cols, name = NULL, breaks = names(phylum_cols)) +
  scale_y_continuous(labels = percent_format(accuracy = 1), expand = c(0, 0)) +
  facet_grid(~continent, scales = "free_x", space = "free_x") +
  labs(x = NULL, y = "Relative abundance") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    legend.position = "bottom",
    panel.grid = element_blank(),
    strip.background = element_rect(fill = "grey95", color = NA)
  )

save_panel(p, "figS03_panel_B_stacked_hybrid", width_mm = 180, height_mm = 55)
