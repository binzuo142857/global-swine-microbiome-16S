#!/usr/bin/env Rscript
# Figure 4A: geographic distribution and sample counts of 23 Chinese pig breeds.
suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
  library(sf)
  library(ggrepel)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))
pig_data <- read_tsv(data_file("fig04/Figure4A_breed_locations.tsv"), show_col_types = FALSE)
china_map <- st_make_valid(st_read(data_file("fig04/Figure4A_map.geojson"), quiet = TRUE))
stopifnot(nrow(pig_data) == 23, sum(pig_data$sample_count) == 2453)
p <- ggplot() +
  geom_sf(data = china_map, fill = "#EFEFEF", color = "#BDBDBD", linewidth = 0.3) +
  geom_point(data = pig_data, aes(x = longitude, y = latitude, size = sample_count),
             shape = 21, fill = "#E74C3C", color = "black", stroke = 0.5, alpha = 0.7) +
  scale_size_continuous(name = "Sample Count", range = c(2, 12), breaks = c(50, 200, 400, 700)) +
  geom_text_repel(data = pig_data, aes(x = longitude, y = latitude, label = breed_name),
                  size = 4, color = "black", box.padding = grid::unit(0.4, "lines"),
                  point.padding = grid::unit(0.6, "lines"), segment.color = "grey60",
                  min.segment.length = 0.5, max.overlaps = Inf, seed = 1) +
  labs(title = "Distribution of Local Chinese Pig Breeds (by Sample Count)",
       caption = "Map data © Alibaba DataV.GeoAtlas") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold", margin = margin(b = 15)),
        plot.caption = element_text(hjust = 1, size = 10, color = "grey60", margin = margin(t = 15)),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        legend.position = "inside", legend.position.inside = c(0.08, 0.25),
        legend.background = element_rect(fill = scales::alpha("white", 0.7), color = NA))
save_panel(p, "Figure4A_breed_map", width_mm = 266.7, height_mm = 254)
