#!/usr/bin/env Rscript
# Figure 1I — core genera scatter (genus) + source table (core list).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggrepel)
  library(RColorBrewer)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

g_sum <- read_source_table(data_file("fig01/Figure1I_taxonomic_composition.tsv.gz")) %>%
  as_tibble() %>%
  filter(rank == "Genus") %>%
  transmute(
    Label = as.character(taxon),
    MeanAbundance_pct = as.numeric(mean_abundance_pct),
    Prevalence_pct = as.numeric(sample_prevalence_pct)
  ) %>%
  filter(!is.na(Label), MeanAbundance_pct > 0)

core_genera <- read_source_table(data_file("fig01/Figure1I_core_taxa.tsv.gz")) %>%
  as_tibble() %>%
  pull(genus) %>%
  unique()

selected_prev_cutoff <- 50
selected_abun_cutoff <- 1
genus_blacklist <- c("Muribaculaceae", "[Eubacterium]_coprostanoligenes_group")
other_point_color <- "grey78"
threshold_line_color <- "grey35"
threshold_fill_color <- "#F4F1E8"
x_left_share <- 0.32
x_plot_max <- 100
x_threshold_plot <- x_plot_max * x_left_share
y_low_share <- 0.12
y_plot_max <- 10
y_threshold_plot <- y_plot_max * y_low_share

tx_x <- function(x) ifelse(
  x <= selected_prev_cutoff,
  x / selected_prev_cutoff * x_threshold_plot,
  x_threshold_plot + (x - selected_prev_cutoff) / (100 - selected_prev_cutoff) * (x_plot_max - x_threshold_plot)
)
tx_y <- function(y, ymax) {
  y <- pmax(y, 0)
  sy <- sqrt(y)
  st <- sqrt(selected_abun_cutoff)
  sm <- sqrt(ymax)
  ifelse(
    y <= selected_abun_cutoff,
    sy / st * y_threshold_plot,
    y_threshold_plot + (sy - st) / (sm - st) * (y_plot_max - y_threshold_plot)
  )
}

scatter_df <- g_sum %>%
  filter(!(Label %in% genus_blacklist)) %>%
  mutate(CoreStatus = if_else(Label %in% core_genera, "Core genus", "Other genera"))
core_df <- scatter_df %>%
  filter(CoreStatus == "Core genus") %>%
  arrange(desc(Prevalence_pct), desc(MeanAbundance_pct))
ymax_o <- max(core_df$MeanAbundance_pct) * 1.18
scatter_df <- scatter_df %>% mutate(plot_x = tx_x(Prevalence_pct), plot_y = tx_y(MeanAbundance_pct, ymax_o))
core_df <- core_df %>%
  mutate(
    plot_x = tx_x(Prevalence_pct),
    plot_y = tx_y(MeanAbundance_pct, ymax_o),
    Label_disp = str_remove(Label, "_group")
  )
core_palette <- colorRampPalette(c(brewer.pal(8, "Dark2"), brewer.pal(12, "Set3")))(nrow(core_df))
names(core_palette) <- core_df$Label
x_breaks_o <- c(0, 25, 50, 60, 70, 80, 90, 100)
y_breaks_o <- c(0, 0.1, 1, 2, 4, 9)
y_breaks_o <- y_breaks_o[y_breaks_o <= ymax_o]

p <- ggplot(scatter_df, aes(plot_x, plot_y)) +
  annotate("rect", xmin = x_threshold_plot, xmax = Inf, ymin = y_threshold_plot, ymax = Inf,
           fill = threshold_fill_color, alpha = 0.62) +
  geom_point(data = filter(scatter_df, CoreStatus == "Other genera"),
             color = other_point_color, size = 0.7, alpha = 0.55) +
  geom_vline(xintercept = x_threshold_plot, linetype = "dashed",
             color = threshold_line_color, linewidth = 0.45) +
  geom_hline(yintercept = y_threshold_plot, linetype = "dashed",
             color = threshold_line_color, linewidth = 0.45) +
  geom_point(data = core_df, aes(fill = Label), shape = 21, color = "grey15",
             size = 2.6, stroke = 0.35, alpha = 0.98) +
  geom_label_repel(
    data = core_df, aes(label = Label_disp), size = pt_to_mm(6.0), fontface = "italic",
    family = FONT, min.segment.length = 0, box.padding = 0.3, max.overlaps = Inf,
    label.size = 0.12, fill = alpha("white", 0.68), seed = 7
  ) +
  annotate(
    "text", x = x_threshold_plot + 2, y = y_plot_max - 0.15,
    label = "Core genera (prev > 50%, abund > 1%)", hjust = 0, vjust = 1,
    size = pt_to_mm(6.5), family = FONT, fontface = "bold", color = "#7A2012"
  ) +
  scale_fill_manual(values = core_palette, guide = "none") +
  scale_x_continuous(breaks = tx_x(x_breaks_o), labels = x_breaks_o,
                     expand = expansion(mult = c(0.01, 0.025))) +
  scale_y_continuous(breaks = tx_y(y_breaks_o, ymax_o), labels = y_breaks_o,
                     expand = expansion(mult = c(0.02, 0.05))) +
  coord_cartesian(xlim = c(0, x_plot_max), ylim = c(0, y_plot_max), clip = "on") +
  labs(x = "Prevalence (%)", y = "Mean abundance (%)") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.minor = element_blank())

save_panel(p, "fig01_panel_I_core_scatter", width_mm = 123, height_mm = 60)
