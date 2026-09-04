#!/usr/bin/env Rscript
# Figure 1D–G — rank top-10 prevalence/abundance dual-axis panels from Task4.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
  library(patchwork)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

task4 <- require_file(
  file.path(PLOT_INPUTS, "Task4_overview_dual_axis_top10_source.tsv.gz"),
  "Task4_overview_dual_axis_top10_source.tsv.gz"
)
rank_summary <- read_source_table(task4) %>%
  as_tibble() %>%
  transmute(
    Level = as.character(taxonomic_level),
    Label = as.character(taxon_label),
    Prevalence_pct = as.numeric(Prevalence_pct),
    MeanAbundance_pct = as.numeric(MeanAbundance_pct)
  )

level_palette_dark <- c(
  Phylum = "#8F6AAE", Class = "#5FA6A8",
  Order = "#C28E5B", Family = "#6E9A69"
)

make_rank_plot <- function(level_name, show_left = FALSE, show_right = FALSE) {
  col <- unname(level_palette_dark[level_name])
  level_df <- rank_summary %>%
    filter(Level == level_name) %>%
    arrange(desc(Prevalence_pct), desc(MeanAbundance_pct)) %>%
    slice_head(n = 10) %>%
    mutate(
      Label = str_remove(Label, "_group"),
      Label = if (level_name %in% c("Order", "Family")) {
        str_replace(Label, "^[^-_]+[-_]", "")
      } else {
        Label
      },
      Label = factor(Label, levels = Label),
      ScaledMeanAbundance = MeanAbundance_pct / max(MeanAbundance_pct) * 100
    )
  abundance_max <- max(level_df$MeanAbundance_pct)
  ggplot(level_df, aes(Label)) +
    geom_col(aes(y = Prevalence_pct), fill = col, width = 0.76, alpha = 0.30) +
    geom_line(aes(y = ScaledMeanAbundance, group = 1), color = col, linewidth = 0.7) +
    geom_point(aes(y = ScaledMeanAbundance), color = col, size = 0.9) +
    scale_y_continuous(
      name = "Prevalence (%)", limits = c(0, 105), breaks = c(0, 25, 50, 75, 100),
      sec.axis = sec_axis(~ . / 100 * abundance_max, name = "Mean abundance (%)",
                          labels = label_number(accuracy = 0.1))
    ) +
    labs(title = level_name, x = NULL) +
    theme_bw(base_size = S_AX_TXT) +
    base_theme_pub() +
    theme(
      axis.text.x = element_text(angle = 50, hjust = 1, vjust = 1, size = 5.7),
      axis.title.y.left = element_text(color = if (show_left) "black" else NA),
      axis.title.y.right = element_text(color = if (show_right) "black" else NA, angle = 90),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position = "none",
      plot.margin = margin(0.45, 0.03, 0.45, 0.03, unit = "mm")
    )
}

p <- make_rank_plot("Phylum", show_left = TRUE) |
  make_rank_plot("Class") |
  make_rank_plot("Order") |
  make_rank_plot("Family", show_right = TRUE)

save_panel(p, "fig01_panel_DEFG_rank_dual_axis", width_mm = 180, height_mm = 52)
