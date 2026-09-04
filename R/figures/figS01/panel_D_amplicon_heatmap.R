#!/usr/bin/env Rscript
# Figure S1D — amplicon-region genus LMM effect heatmap from T18.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

t18 <- read_source_table(source_table("T18_amplicon_region_genus_mixed_model_results.tsv.gz")) %>%
  as_tibble() %>%
  transmute(
    Taxon = coalesce(as.character(Genus_Label), as.character(Taxon)),
    Amplicon = as.character(Amplicon),
    Estimate = as.numeric(Estimate),
    Q_value = as.numeric(Q_value),
    Phylum = as.character(Phylum)
  )

# Keep taxa with any significant call to control panel size.
sig_taxa <- t18 %>%
  filter(Q_value < 0.05) %>%
  count(Taxon, name = "n_sig") %>%
  arrange(desc(n_sig)) %>%
  slice_head(n = 40) %>%
  pull(Taxon)

plot_df <- t18 %>%
  filter(Taxon %in% sig_taxa) %>%
  mutate(
    Taxon = factor(Taxon, levels = rev(sig_taxa)),
    Amplicon = factor(Amplicon, levels = sort(unique(Amplicon)))
  )

p <- ggplot(plot_df, aes(Amplicon, Taxon, fill = Estimate)) +
  geom_tile(color = "white", linewidth = 0.15) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", name = "Estimate") +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 5.5),
    axis.text.y = element_text(size = 5, face = "italic"),
    panel.grid = element_blank()
  )

save_panel(p, "figS01_panel_D_amplicon_heatmap", width_mm = 120, height_mm = 110)
