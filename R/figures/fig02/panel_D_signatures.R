#!/usr/bin/env Rscript
# Figure 2D — continent signature composite, aligned to
# plot_continent_signature_composite_v3.R layout (not pixel-identical).
# Row set = resolved T23 integrated universe (core_concord2 logic).
# Support methods = ANCOM-BC2 + LEfSe + RF only; core is force-included.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ragg)
  library(patchwork)
  library(RColorBrewer)
  library(cowplot)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

cont5 <- CONTINENT_ORDER
cont3 <- c("Asia", "Europe", "North America")
continent_colors <- CONTINENT_COLORS
cont_abbr <- setNames(cont5, cont5)

t23 <- read_source_table(
  require_file(file.path(SOURCE_TABLES, "T23_Figure2D_integrated_signature_source.tsv.gz"))
) %>%
  as_tibble() %>%
  arrange(figure_display_order) %>%
  mutate(
    gkey = as.character(figure_genus_label),
    gkey_raw = as.character(coalesce(standard_taxon_key, figure_genus_label))
  )

# Match v3 formal figure: abundance ordering within the fixed T23 universe.
gord <- t23 %>%
  arrange(desc(as.numeric(figure_order_mean_abundance_pct)), figure_display_order) %>%
  pull(gkey)
ylev <- rev(gord)

fold_label <- function(x) gsub("_group", "", x, fixed = TRUE)
ay <- scale_y_discrete(limits = ylev, labels = fold_label, drop = FALSE,
                       expand = expansion(add = 0.6))
xs <- function(levels) {
  scale_x_discrete(limits = levels, labels = cont_abbr[levels],
                   expand = expansion(add = 0.55))
}
panel_theme_sig <- function(show_y = FALSE) {
  theme_minimal(base_size = 6.5) +
    theme(
      plot.title = element_text(size = 8, face = "plain", hjust = 0.5, margin = margin(b = 1),
                                family = FONT),
      axis.title = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 6.5, color = "black",
                                 family = FONT),
      axis.text.y = if (show_y) {
        element_text(size = 6.5, face = "italic", color = "black", family = FONT, lineheight = 0.8)
      } else {
        element_blank()
      },
      panel.grid.major = element_line(linewidth = 0.12, color = "grey90"),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "grey75", fill = NA, linewidth = 0.3),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.key.size = unit(2.6, "mm"),
      legend.text = element_text(size = 5, family = FONT),
      legend.title = element_text(size = 5.5, family = FONT),
      plot.margin = margin(1, 1.2, 1, 1.2)
    )
}
g_size <- function(...) guide_legend(nrow = 1, order = 2, ...)
g_bar <- function(...) {
  guide_colourbar(
    barwidth = unit(10, "mm"), barheight = unit(1.8, "mm"),
    direction = "horizontal", title.position = "top", order = 1, ...
  )
}

# ---- Abund/Prev: prefer packable T41; else build from genus-summary and export ----
t41 <- source_table("T41_fig02D_continent_abund_prev.tsv.gz")
t41_local <- t41


  abund_path <- if (file.exists(t41)) t41 else t41_local
  message("Fig2D Abund/Prev from T41: ", abund_path)
  abund_export <- read_tsv(abund_path, show_col_types = FALSE)
  d1 <- abund_export %>%
    transmute(
      gkey = as.character(figure_genus_label),
      Label = as.character(matched_summary_label),
      continent = as.character(continent),
      abund = as.numeric(mean_abundance_pct),
      prev = as.numeric(prevalence_pct)
    ) %>%
    filter(gkey %in% gord, continent %in% cont5) %>%
    mutate(
      gkey = factor(gkey, levels = ylev),
      continent = factor(continent, levels = cont5)
    )


ab_lim <- as.numeric(quantile(d1$abund[d1$abund > 0], c(0.03, 0.97), na.rm = TRUE))
p1 <- ggplot(d1, aes(continent, gkey)) +
  geom_point(aes(size = prev, fill = abund), shape = 21, color = "grey30", stroke = 0.2) +
  scale_fill_viridis_c(
    name = "Abund %", trans = "log10", option = "turbo",
    limits = ab_lim, oob = scales::squish,
    labels = label_number(accuracy = 0.1), guide = g_bar()
  ) +
  scale_size_continuous(name = "Prev", range = c(0.2, 4.2), limits = c(0, 100),
                        breaks = c(20, 50, 80), guide = g_size()) +
  xs(cont5) + ay + panel_theme_sig(show_y = TRUE) + ggtitle("Abund/Prev")

# ---- Core stars ----
core_long <- t23 %>%
  select(gkey, core_Asia, core_Europe, core_North_America, core_Oceania, core_South_America) %>%
  pivot_longer(-gkey, names_to = "continent", values_to = "is_core") %>%
  mutate(
    continent = recode(continent,
      core_Asia = "Asia", core_Europe = "Europe",
      core_North_America = "North America",
      core_Oceania = "Oceania", core_South_America = "South America"
    ),
    is_core = as.logical(is_core)
  ) %>%
  filter(is_core, continent %in% cont5) %>%
  mutate(
    gkey = factor(gkey, levels = ylev),
    continent = factor(continent, levels = cont5)
  )

p2 <- ggplot(core_long, aes(continent, gkey)) +
  geom_text(label = "\u2605", color = "grey20", size = 4.0) +
  geom_text(aes(color = continent), label = "\u2605", size = 2.9) +
  scale_color_manual(values = continent_colors, drop = FALSE, guide = "none") +
  xs(cont5) + ay + panel_theme_sig() + ggtitle("Core")

# ---- ANCOM-BC2 triangles ----
ancom <- bind_rows(
  t23 %>% transmute(gkey, continent = "Asia",
                    lfc = as.numeric(ancombc2_lfc_Asia), q = as.numeric(ancombc2_q_Asia),
                    hit = as.logical(ancombc2_hit_Asia)),
  t23 %>% transmute(gkey, continent = "Europe",
                    lfc = as.numeric(ancombc2_lfc_Europe), q = as.numeric(ancombc2_q_Europe),
                    hit = as.logical(ancombc2_hit_Europe)),
  t23 %>% transmute(gkey, continent = "North America",
                    lfc = as.numeric(ancombc2_lfc_North_America),
                    q = as.numeric(ancombc2_q_North_America),
                    hit = as.logical(ancombc2_hit_North_America))
) %>%
  filter(hit %in% TRUE, is.finite(lfc), is.finite(q)) %>%
  mutate(
    gkey = factor(gkey, levels = ylev),
    continent = factor(continent, levels = cont3),
    neglogq = pmin(-log10(pmax(q, 1e-10)), 10)
  )
lfc_lim <- max(abs(ancom$lfc), na.rm = TRUE)
if (!is.finite(lfc_lim) || lfc_lim == 0) lfc_lim <- 1

p3 <- ggplot(ancom, aes(continent, gkey)) +
  geom_point(aes(fill = lfc, size = neglogq), shape = 24, color = "grey20", stroke = 0.2) +
  scale_fill_gradient2(
    name = "LFC", low = "#2166AC", mid = "white", high = "#B2182B",
    midpoint = 0, limits = c(-lfc_lim, lfc_lim), guide = g_bar()
  ) +
  scale_size_continuous(name = "-log10 q", range = c(0.5, 3.0), breaks = c(2, 5, 10),
                        guide = g_size()) +
  xs(cont3) + ay + panel_theme_sig() + ggtitle("ANCOM-BC2")

# ---- LEfSe squares ----
lefse <- bind_rows(
  t23 %>% transmute(gkey, continent = "Asia", lda = as.numeric(lefse_abs_lda_Asia),
                    hit = as.logical(lefse_hit_Asia)),
  t23 %>% transmute(gkey, continent = "Europe", lda = as.numeric(lefse_abs_lda_Europe),
                    hit = as.logical(lefse_hit_Europe)),
  t23 %>% transmute(gkey, continent = "North America",
                    lda = as.numeric(lefse_abs_lda_North_America),
                    hit = as.logical(lefse_hit_North_America))
) %>%
  filter(hit %in% TRUE, is.finite(lda), lda >= 3.5) %>%
  mutate(
    gkey = factor(gkey, levels = ylev),
    continent = factor(continent, levels = cont3)
  )

p4 <- ggplot(lefse, aes(continent, gkey)) +
  geom_point(aes(size = lda), shape = 22, fill = "#8856A7", color = "grey25", stroke = 0.2) +
  scale_size_continuous(name = "LDA", range = c(0.8, 3.4),
                        breaks = c(3.5, 4.0, 4.5), guide = g_size()) +
  xs(cont3) + ay + panel_theme_sig() + ggtitle("LEfSe")

# ---- RF diamonds (colnorm) ----
rf <- bind_rows(
  lapply(cont5, function(ct) {
    hit_col <- paste0("rf_hit_", gsub(" ", "_", ct))
    # T23 uses North_America / South_America in column names
    hit_col <- dplyr::case_when(
      ct == "North America" ~ "rf_hit_North_America",
      ct == "South America" ~ "rf_hit_South_America",
      TRUE ~ paste0("rf_hit_", ct)
    )
    imp_col <- sub("rf_hit_", "rf_importance_colnorm_", hit_col)
    tibble(
      gkey = t23$gkey,
      continent = ct,
      hit = as.logical(t23[[hit_col]]),
      imp_colnorm = as.numeric(t23[[imp_col]])
    )
  })
) %>%
  filter(hit %in% TRUE, is.finite(imp_colnorm)) %>%
  mutate(
    gkey = factor(gkey, levels = ylev),
    continent = factor(continent, levels = cont5)
  )

p5 <- ggplot(rf, aes(continent, gkey)) +
  geom_point(aes(size = imp_colnorm), shape = 23, fill = "#3F7F4C", color = "grey25", stroke = 0.25) +
  scale_size_continuous(name = "RF imp", range = c(0.6, 3.4),
                        breaks = c(0.25, 0.5, 1.0), limits = c(0, 1), guide = g_size()) +
  xs(cont5) + ay + panel_theme_sig() + ggtitle("RF signature")

# ---- Concordance tiles (method count per continent; ANCOM/LEfSe/RF only) ----
concord <- bind_rows(
  ancom %>% transmute(gkey = as.character(gkey), continent = as.character(continent), method = "ANCOM"),
  lefse %>% transmute(gkey = as.character(gkey), continent = as.character(continent), method = "LEfSe"),
  rf %>% transmute(gkey = as.character(gkey), continent = as.character(continent), method = "RF")
) %>%
  distinct() %>%
  count(gkey, continent, name = "n_methods") %>%
  mutate(
    gkey = factor(gkey, levels = ylev),
    continent = factor(continent, levels = cont5),
    n_methods = factor(as.character(n_methods), levels = c("1", "2", "3"))
  )
conc_cols <- c("1" = "#FEE0B6", "2" = "#F1A340", "3" = "#B35806")

p6 <- ggplot(concord, aes(continent, gkey)) +
  geom_tile(aes(fill = n_methods), color = "white", linewidth = 0.3) +
  scale_fill_manual(name = "#meth", values = conc_cols, drop = FALSE,
                    guide = guide_legend(nrow = 1, order = 1)) +
  xs(cont5) + ay + panel_theme_sig() + ggtitle("Concordance")

p <- (p1 + p2 + p3 + p4 + p5 + p6 +
  plot_layout(nrow = 1, widths = c(1.35, 0.85, 0.95, 0.85, 1.0, 0.95), guides = "collect")) &
  theme(legend.position = "bottom", legend.box = "vertical")

save_panel(p, "fig02_panel_D_signatures", width_mm = 180, height_mm = 230)

