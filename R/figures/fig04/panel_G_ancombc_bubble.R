#!/usr/bin/env Rscript
# Figure 4G — China breed one-vs-all ANCOM-BC2 abundance bubble.
# Source: publication OVA plotting table (Mean_Abund + LFC + robust stars).
# Does NOT use pairwise source table (Mean_Abundance empty; wrong contrast semantics).

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
  library(RColorBrewer)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

ova_src <- data_file("fig04/Figure4G_abundance_effects.tsv.gz")

plot_df <- read_tsv(ova_src, show_col_types = FALSE) %>%
  mutate(
    Target_Breed = factor(as.character(Target_Breed), levels = BREED_ORDER_SOURCE),
    Mean_Abund = as.numeric(Mean_Abund),
    one_vs_all_lfc_full = as.numeric(one_vs_all_lfc_full),
    robust_sig = as.logical(robust_sig),
    sig_mark = if_else(replace_na(robust_sig, FALSE), "*", ""),
    display_taxon_unique = as.character(display_taxon_unique)
  ) %>%
  filter(!is.na(Target_Breed), !is.na(Mean_Abund), is.finite(Mean_Abund))

if (!nrow(plot_df)) stop("OVA plotting table empty after filters.")
if (any(!is.finite(plot_df$one_vs_all_lfc_full))) {
  stop("Missing one_vs_all_lfc_full values; refuse LFC substitutes.")
}

# Taxon order: signature mode from original pub script (primary breed by max |LFC|).
order_df <- plot_df %>%
  group_by(Resolved_ID) %>%
  summarise(
    primary_group = Target_Breed[which.max(abs(one_vs_all_lfc_full))][1],
    primary_lfc = one_vs_all_lfc_full[which.max(abs(one_vs_all_lfc_full))][1],
    best_q = min(as.numeric(one_vs_all_q_full), na.rm = TRUE),
    any_robust = any(robust_sig, na.rm = TRUE),
    max_abs_lfc = max(abs(one_vs_all_lfc_full), na.rm = TRUE),
    global_mean_abund = mean(Mean_Abund, na.rm = TRUE),
    display_taxon_unique = first(display_taxon_unique),
    .groups = "drop"
  ) %>%
  mutate(primary_group = factor(primary_group, levels = BREED_ORDER_SOURCE)) %>%
  arrange(primary_group, desc(any_robust), best_q, desc(max_abs_lfc),
          desc(global_mean_abund), display_taxon_unique)

plot_df <- plot_df %>%
  mutate(
    display_taxon_unique = factor(
      display_taxon_unique,
      levels = order_df$display_taxon_unique
    )
  )

lfc_lim <- range(plot_df$one_vs_all_lfc_full, na.rm = TRUE)
plot_colors <- rev(brewer.pal(11, "RdYlBu"))

p <- ggplot(plot_df, aes(display_taxon_unique, Target_Breed)) +
  geom_point(
    aes(size = Mean_Abund, fill = one_vs_all_lfc_full),
    shape = 21, color = "grey35", stroke = 0.2, alpha = 0.95
  ) +
  geom_text(
    aes(label = sig_mark), color = "black", size = 2.4,
    vjust = 0.72, fontface = "bold", family = FONT
  ) +
  scale_fill_gradientn(
    colors = plot_colors,
    name = "One-vs-all LFC",
    limits = lfc_lim,
    oob = squish
  ) +
  scale_size_continuous(
    range = c(0.5, 5.5),
    trans = "sqrt",
    name = "Mean rel. abund (%)"
  ) +
  scale_y_discrete(labels = BREED_LABELS) +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 5.5, face = "italic"),
    axis.text.y = element_text(size = S_AX_TXT, face = "bold"),
    legend.position = "bottom",
    legend.box = "horizontal",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

save_panel(p, "fig04_panel_G_ancombc_bubble", width_mm = 179, height_mm = 68)
