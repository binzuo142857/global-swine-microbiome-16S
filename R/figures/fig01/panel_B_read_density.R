#!/usr/bin/env Rscript
# Figure 1B — read-count density.
# Labels are computed from the plotted subset (non-chimeric > 3000).

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(scales)
  library(viridis)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

stats_path <- plot_input("fig01B_sample_read_counts.tsv.gz")

stats_raw <- read_tsv(stats_path, show_col_types = FALSE)
plot_data_long <- stats_raw %>%
  mutate(`non-chimeric` = as.numeric(`non-chimeric`), input = as.numeric(input)) %>%
  filter(`non-chimeric` > 3000) %>%
  select(`sample-id`, input, `non-chimeric`) %>%
  pivot_longer(c(input, `non-chimeric`), names_to = "Pipeline_Stage", values_to = "Read_Count") %>%
  filter(Read_Count > 0) %>%
  mutate(Pipeline_Stage = factor(Pipeline_Stage, levels = c("input", "non-chimeric")))

totB <- plot_data_long %>%
  group_by(Pipeline_Stage) %>%
  summarize(total = sum(as.numeric(Read_Count)), n = n(), .groups = "drop")

input_total <- totB$total[totB$Pipeline_Stage == "input"]
nonchim_total <- totB$total[totB$Pipeline_Stage == "non-chimeric"]

# Dynamic labels (same visual style as original, values from data).
input_lab <- paste0("Input\n", fmt_billion_reads(input_total))
nonchim_lab <- paste0("Non-chimeric\n", fmt_billion_reads(nonchim_total))

message(sprintf(
  "Fig1B plotted subset: n_samples=%d; input=%s; non-chimeric=%s",
  n_distinct(plot_data_long$`sample-id`),
  format(input_total, scientific = FALSE),
  format(nonchim_total, scientific = FALSE)
))

vir2 <- viridis::viridis(2)
input_color <- vir2[1]
nonchim_color <- vir2[2]

p <- ggplot(plot_data_long, aes(Read_Count, fill = Pipeline_Stage, color = Pipeline_Stage)) +
  geom_density(alpha = 0.4, linewidth = 0.4) +
  scale_x_log10(
    name = "Read count",
    breaks = trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x))
  ) +
  scale_fill_viridis_d(option = "D", guide = "none") +
  scale_color_viridis_d(option = "D", guide = "none") +
  annotation_logticks(
    sides = "b", linewidth = 0.2,
    short = unit(0.4, "mm"), mid = unit(0.7, "mm"), long = unit(1, "mm")
  ) +
  annotate(
    "label", x = 9.5e3, y = 1.31, label = nonchim_lab, hjust = 0.5, vjust = 1,
    size = pt_to_mm(6.0), lineheight = 0.95, family = FONT, color = "black",
    label.size = 0.1, fill = alpha(nonchim_color, 0.32)
  ) +
  annotate(
    "label", x = 5.20e5, y = 0.92, label = input_lab, hjust = 0.5, vjust = 1,
    size = pt_to_mm(6.0), lineheight = 0.95, family = FONT, color = "black",
    label.size = 0.1, fill = alpha(input_color, 0.30)
  ) +
  labs(y = "Density") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(legend.position = "none", panel.grid.minor = element_blank())

# Provenance sidecar for the corrected totals.
write_tsv(
  totB %>% mutate(
    filter = "non-chimeric > 3000",
    label_rule = "sprintf('%.2f Billion reads', total/1e9)",
    note = "Totals computed from the plotted retained sample set"
  ),
  file.path(MANIFEST_DIR, "fig01_panel_B_read_totals.tsv")
)

save_panel(p, "fig01_panel_B_read_density", width_mm = 60, height_mm = 38)
