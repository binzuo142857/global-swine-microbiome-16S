#!/usr/bin/env Rscript
# Figure S2C — country signature abundance/importance matrix.
# Uses published Fig3_Signature_source_data.tsv taxon set as-is (TAXA_FILTER=all
# semantics of the exported table). Optional TAXA_FILTER=rf_star matches original
# height-cap rule (Importance non-NA; per-country top TOP_N_FEATURES=10).

suppressPackageStartupMessages({
  library(tidyverse)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

sig_path <- data_file("figS02/FigureS2C_country_signatures.tsv.gz")

sig <- read_tsv(sig_path, show_col_types = FALSE) %>%
  mutate(
    continent = factor(continent, levels = CONTINENT_ORDER),
    country = as.character(country),
    Display_Label = as.character(Display_Label),
    Importance = suppressWarnings(as.numeric(Importance)),
    Mean_Abund = as.numeric(Mean_Abund),
    Z_Score = as.numeric(Z_Score),
    Max_Imp = suppressWarnings(as.numeric(Max_Imp))
  )

TOP_N_FEATURES <- as.integer(Sys.getenv("TOP_N_FEATURES", unset = "10"))
TAXA_FILTER <- Sys.getenv("TAXA_FILTER", unset = "all")  # all | rf_star

taxon_order <- sig %>%
  distinct(Display_Label, Primary_country, Max_Imp, continent) %>%
  arrange(continent, Primary_country, desc(Max_Imp)) %>%
  pull(Display_Label) %>%
  unique()

apply_taxa_filter <- function(stats, filter_mode) {
  out <- stats
  if (identical(filter_mode, "rf_star")) {
    sig_labs <- out %>% filter(!is.na(Importance)) %>% distinct(Display_Label) %>% pull(Display_Label)
    out <- out %>% filter(Display_Label %in% sig_labs)
    out <- out %>%
      group_by(country) %>%
      mutate(rank_imp = rank(-coalesce(Importance, 0), ties.method = "first")) %>%
      filter(is.na(Importance) | rank_imp <= TOP_N_FEATURES) %>%
      ungroup() %>%
      select(-rank_imp)
  }
  out
}

sig_plot <- apply_taxa_filter(sig, TAXA_FILTER)
keep <- unique(sig_plot$Display_Label)
country_order <- sig %>%
  distinct(country, continent, n_samples) %>%
  arrange(continent, desc(n_samples)) %>%
  pull(country) %>%
  unique()

sig_plot <- sig_plot %>%
  mutate(
    Display_Label = factor(Display_Label, levels = rev(intersect(taxon_order, keep))),
    country = factor(country, levels = country_order)
  )

message(
  "S2C TAXA_FILTER=", TAXA_FILTER,
  " n_taxa=", n_distinct(sig_plot$Display_Label),
  " Importance_nonNA_taxa=", n_distinct(sig$Display_Label[!is.na(sig$Importance)])
)

p <- ggplot(sig_plot, aes(country, Display_Label)) +
  geom_point(aes(size = Mean_Abund, color = Z_Score), alpha = 0.9) +
  # RF stars: taxa with Importance in that country cell
  geom_point(
    data = sig_plot %>% filter(!is.na(Importance)),
    shape = 8, size = 0.55, color = "grey15", stroke = 0.25
  ) +
  scale_color_viridis_c(option = "C", name = "Z") +
  scale_size_continuous(range = c(0.4, 3.2), name = "Mean abund") +
  labs(x = NULL, y = NULL, title = "Country signature taxa") +
  theme_bw(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    axis.text.x = element_text(angle = 55, hjust = 1, vjust = 1, size = 5.5),
    axis.text.y = element_text(size = 5, face = "italic"),
    panel.grid.major = element_line(color = "grey92", linewidth = 0.2),
    legend.position = "right"
  )

save_panel(p, paste0("figS02_panel_C_signature_matrix_", TAXA_FILTER), width_mm = 180, height_mm = max(120, 35 + 2.4 * length(keep)))
