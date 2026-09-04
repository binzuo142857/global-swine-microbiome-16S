#!/usr/bin/env Rscript
# Figure 3D — continent taxon discovery curves.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

src <- file.path(DATA_DIR, "fig03/Figure3D_taxon_discovery.tsv.gz")
disc_data <- if (grepl("\\.xlsx$", src)) {
  read_source_table(src) %>% as_tibble()
} else {
  read_tsv(src, show_col_types = FALSE)
}
disc_data <- disc_data %>%
  transmute(
    Continent = as.character(continent),
    Sample_Size = as.numeric(sample_size),
    Mean_Unique_Taxa = as.numeric(mean_unique_taxa)
  ) %>%
  filter(Continent %in% CONTINENT_ORDER) %>%
  mutate(Continent = factor(Continent, levels = CONTINENT_ORDER))

disc_points <- disc_data %>%
  group_by(Continent) %>%
  mutate(is_last = row_number() == n()) %>%
  filter(is_last | row_number() %% 5 == 1) %>%
  ungroup()
disc_labels <- disc_data %>%
  group_by(Continent) %>%
  slice_max(Sample_Size, n = 1, with_ties = FALSE) %>%
  ungroup()

p <- ggplot(disc_data, aes(Sample_Size, Mean_Unique_Taxa, color = Continent)) +
  geom_line(linewidth = 0.45) +
  geom_point(data = disc_points, size = 0.8, alpha = 0.85) +
  geom_text(data = disc_labels, aes(label = Continent), hjust = 0, nudge_x = 250,
            size = S_AX_TXT / .pt, family = FONT, show.legend = FALSE) +
  scale_color_manual(values = CONTINENT_COLORS, guide = "none") +
  scale_x_continuous(labels = comma_format(), breaks = pretty_breaks(4),
                     expand = expansion(mult = c(0.02, 0.18))) +
  scale_y_continuous(labels = comma_format(), breaks = pretty_breaks(4)) +
  labs(x = "Number of samples", y = "Unique taxa discovered") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major = element_line(color = "grey90", linewidth = 0.25))

save_panel(p, "fig03_panel_D_discovery", width_mm = 70, height_mm = 55)
