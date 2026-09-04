#!/usr/bin/env Rscript
# Figure S2A — null-calibrated DBI comparison from T26 + Fig1_DBI_source_data.tsv.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

dbi_path <- plot_input("Fig1_DBI_source_data.tsv.gz")

dbi_stats <- read_tsv(
  require_file(dbi_path, "Fig1_DBI_source_data.tsv"),
  show_col_types = FALSE
) %>%
  mutate(scale = factor(scale, levels = c("Continent", "Country")))

t26 <- read_source_table(source_table("T26_davies_bouldin_permutation_results.tsv.gz")) %>%
  as_tibble() %>%
  transmute(
    geographic_level = as.character(geographic_level),
    permutation_id = as.integer(permutation_id),
    DBI = as.numeric(DBI),
    observed_null_status = as.character(observed_null_status)
  )

dbi_null_long <- t26 %>%
  filter(is.na(observed_null_status) | observed_null_status != "observed") %>%
  mutate(
    scale = recode(geographic_level, continent = "Continent", country = "Country"),
    scale = factor(scale, levels = c("Continent", "Country")),
    dbi = DBI
  )

dbi_obs <- dbi_stats
scale_cols <- c(Continent = unname(CONTINENT_COLORS["Europe"]), Country = "#C28E5B")
ann_labels <- dbi_stats %>%
  mutate(
    label = paste0(
      "Obs = ", sprintf("%.3f", observed),
      "\nNull med = ", sprintf("%.3f", null_median),
      "\n", ifelse(empirical_p < 0.001, "P < 0.001", paste0("P = ", sprintf("%.3f", empirical_p))),
      "\nZ = ", sprintf("%.2f", z_score),
      "\nObs/Null = ", sprintf("%.2f", obs_null_ratio)
    ),
    x_ann = max(dbi_null_long$dbi, na.rm = TRUE) * 1.02
  )

p <- ggplot(dbi_null_long, aes(x = dbi, y = scale)) +
  geom_violin(fill = "grey75", color = NA, alpha = 0.85, trim = TRUE, width = 0.7) +
  geom_vline(data = dbi_obs, aes(xintercept = observed, color = scale), linewidth = 0.7) +
  geom_point(data = dbi_obs, aes(x = observed, y = scale, color = scale), size = 2.2) +
  geom_text(
    data = ann_labels, aes(x = x_ann, y = scale, label = label, color = scale),
    inherit.aes = FALSE, hjust = 0, vjust = 0.5,
    size = S_AX_TXT / .pt, family = FONT, lineheight = 0.95
  ) +
  scale_color_manual(values = scale_cols, guide = "none") +
  labs(
    title = "Null-calibrated DBI comparison",
    x = "Davies-Bouldin Index (lower = tighter clusters)",
    y = NULL
  ) +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(panel.grid.major.y = element_blank()) +
  coord_cartesian(xlim = c(0, max(dbi_null_long$dbi, na.rm = TRUE) * 1.75), clip = "off")

save_panel(p, "figS02_panel_A_dbi", width_mm = 110, height_mm = 70)
