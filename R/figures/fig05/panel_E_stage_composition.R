#!/usr/bin/env Rscript
# Figure 5E — enterotype composition across growth stages (global feces PAM).

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

# Prefer joining global enterotype labels with growth_stage.
coords <- read_tsv(
  file.path(DATA_DIR, "fig05/Figure5CEFGHI_enterotype_coordinates.tsv.gz"),
  show_col_types = FALSE
) %>%
  filter(analysis_scope == "global_feces") %>%
  transmute(sample_id = as.character(sample_id), enterotype = as.character(enterotype))

meta <- read_source_table(data_file("shared/sample_diversity_metadata.tsv.gz")) %>%
  as_tibble() %>%
  transmute(
    sample_id = as.character(sample_id),
    growth_stage = str_to_title(as.character(growth_stage))
  )

stage_df <- coords %>%
  inner_join(meta, by = "sample_id") %>%
  filter(growth_stage %in% c("Lactation", "Nursery", "Growing", "Finishing")) %>%
  mutate(
    growth_stage = factor(growth_stage, levels = c("Lactation", "Nursery", "Growing", "Finishing")),
    enterotype = factor(enterotype, levels = c("1", "2"))
  ) %>%
  count(growth_stage, enterotype) %>%
  group_by(growth_stage) %>%
  mutate(frac = n / sum(n)) %>%
  ungroup()

et2_cols <- c("1" = "#23395B", "2" = "#F2C14E")

p <- ggplot(stage_df, aes(x = growth_stage, y = frac, fill = enterotype)) +
  geom_col(width = 0.72, color = "white", linewidth = 0.16, alpha = 0.72) +
  scale_fill_manual(values = et2_cols, guide = "none") +
  scale_y_continuous(labels = percent_format(accuracy = 1), expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "Samples (%)") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1, vjust = 1))

write_tsv(stage_df, file.path(MANIFEST_DIR, "fig05_panel_E_stage_fractions.tsv"))
save_panel(p, "fig05_panel_E_stage_composition", width_mm = 58, height_mm = 52)
