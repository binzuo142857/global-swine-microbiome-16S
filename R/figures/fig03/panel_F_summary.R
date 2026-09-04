#!/usr/bin/env Rscript
# Figure 3F — continental network summary bubble matrix.
# Bubble size is scaled WITHIN each metric (matches caption), not across the full matrix.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

net_ver <- "canonical_corrected"


  src <- require_file(file.path(PLOT_INPUTS, "corrected_continental_network_summary.tsv.gz"))
  summ <- read_source_table(src) %>% as_tibble()


plot_df <- summ %>%
  transmute(
    continent = factor(as.character(continent), levels = c("Asia", "Europe", "North America")),
    specific_edges = as.numeric(specific_edges),
    network_nodes = as.numeric(network_nodes),
    mean_degree = as.numeric(mean_degree)
  ) %>%
  pivot_longer(-continent, names_to = "metric", values_to = "value") %>%
  mutate(
    metric = recode(
      metric,
      specific_edges = "Specific edges",
      network_nodes = "Network nodes",
      mean_degree = "Mean degree"
    ),
    metric = factor(metric, levels = c("Specific edges", "Network nodes", "Mean degree")),
    label = ifelse(metric == "Mean degree", sprintf("%.2f", value), as.character(as.integer(round(value))))
  ) %>%
  group_by(metric) %>%
  mutate(
    # Within-metric scaling for bubble size (caption definition).
    size_scaled = {
      rng <- range(value, na.rm = TRUE)
      if (diff(rng) < .Machine$double.eps) 1 else (value - rng[1]) / diff(rng)
    }
  ) %>%
  ungroup()

# Sanity: print Europe row for author comparison
eu <- plot_df %>% filter(continent == "Europe")
message(
  "Fig3F NETWORK_VERSION=", net_ver,
  " | Europe: ",
  paste(eu$metric, eu$label, sep = "=", collapse = ", ")
)

p <- ggplot(plot_df, aes(continent, metric)) +
  geom_point(aes(size = size_scaled, color = size_scaled), shape = 16) +
  geom_text(aes(label = label), size = pt_to_mm(7), family = FONT, color = "black") +
  scale_color_gradient(low = "#DCE6F2", high = "#1F4E79", guide = "none") +
  scale_size(range = c(8, 18), guide = "none") +
  scale_y_discrete(limits = rev(levels(plot_df$metric))) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid = element_blank())

save_panel(p, paste0("fig03_panel_F_summary_", net_ver), width_mm = 90, height_mm = 55)
