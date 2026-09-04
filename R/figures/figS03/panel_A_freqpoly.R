#!/usr/bin/env Rscript
# Figure S3A — phylum relative-abundance frequency polygons by continent.
# Palette matches exact hybrid source: Fusobacteriota (not Actinobacteriota).

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

src <- require_file(
  file.path(PLOT_INPUTS, "Task5_phylum_abundance_freqpoly_input_source.tsv.gz"),
  "Task5_phylum_abundance_freqpoly_input_source.tsv.gz"
)
df <- read_source_table(src) %>%
  as_tibble() %>%
  transmute(
    continent = factor(as.character(continent), levels = CONTINENT_ORDER),
    phylum_group = as.character(phylum_group),
    relative_abundance = as.numeric(relative_abundance)
  ) %>%
  filter(!is.na(continent), !is.na(relative_abundance))

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
  stop("Unmapped phylum_group in S3A source: ", paste(unmapped, collapse = ", "))
}

df <- df %>% mutate(phylum_group = factor(phylum_group, levels = names(phylum_cols)))

p <- ggplot(df, aes(relative_abundance, color = phylum_group)) +
  geom_freqpoly(bins = 40, linewidth = 0.7) +
  scale_y_log10(labels = label_comma()) +
  scale_color_manual(values = phylum_cols, name = NULL) +
  facet_wrap(~continent, nrow = 1) +
  labs(x = "Relative abundance", y = "Sample counts (log10)") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "grey95", color = NA)
  )

save_panel(p, "figS03_panel_A_freqpoly", width_mm = 180, height_mm = 55)
