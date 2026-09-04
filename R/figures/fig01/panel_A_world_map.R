#!/usr/bin/env Rscript
# Figure 1A — world sample-count choropleth.

suppressPackageStartupMessages({
  library(tidyverse)
  library(maps)
  library(ragg)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

t10 <- read_source_table(data_file("fig01/Figure1A_country_sample_counts.tsv.gz")) %>%
  as_tibble() %>%
  transmute(
    region = recode(as.character(country), Czech = "Czech Republic", `Northern Ireland` = "UK"),
    country_sample_count = as.numeric(retained_samples)
  ) %>%
  group_by(region) %>%
  summarise(country_sample_count = sum(country_sample_count), .groups = "drop")

# Match original overview map: fold Taiwan into China fill.
if ("Taiwan" %in% t10$region && "China" %in% t10$region) {
  tw <- t10$country_sample_count[t10$region == "Taiwan"]
  t10 <- t10 %>%
    mutate(country_sample_count = if_else(
      region == "China", country_sample_count + sum(tw, na.rm = TRUE), country_sample_count
    )) %>%
    filter(region != "Taiwan")
}

world <- map_data("world", wrap = c(-35, 325)) %>% filter(region != "Antarctica")
map_df <- world %>% left_join(t10, by = "region")
if ("China" %in% map_df$region && "Taiwan" %in% map_df$region) {
  china_val <- unique(na.omit(map_df$country_sample_count[map_df$region == "China"]))
  if (length(china_val) == 1L) {
    map_df <- map_df %>%
      mutate(country_sample_count = if_else(region == "Taiwan", china_val, country_sample_count))
  }
}

.map_brk <- c(0, 10, 100, 1000, 10000)
.map_lbl <- c("0", "10", "100", "1k", "10k")
fill_cols <- c("#F4F1E8", "#A9C6A0", "#6E9A69", "#5FA6A8", "#5C88A8", "#3C3A63")

p <- ggplot(map_df, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = country_sample_count), color = "white", linewidth = 0.1) +
  scale_fill_gradientn(
    colours = fill_cols, na.value = "grey92", name = "Samples",
    trans = "log1p", breaks = .map_brk, labels = .map_lbl
  ) +
  guides(fill = guide_colorbar(
    title.position = "top", title.hjust = 0.5, direction = "horizontal",
    barwidth = unit(22, "mm"), barheight = unit(3, "mm")
  )) +
  coord_quickmap(xlim = c(-30, 330), ylim = c(-55, 80), expand = FALSE, clip = "on") +
  theme_void(base_size = S_AX_TXT) +
  base_theme_pub() +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.105, 0.118),
    legend.justification = c(0, 0),
    legend.direction = "horizontal",
    legend.background = element_rect(fill = alpha("white", 0.2), color = NA)
  )

save_panel(p, "fig01_panel_A_world_map", width_mm = 118, height_mm = 72)
