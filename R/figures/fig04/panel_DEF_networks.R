#!/usr/bin/env Rscript
# Figure 4D–F — China breed-specific co-abundance networks.
#
# Default (author-adopted data): corrective zero-column FastSpar displayed edges/nodes
#   Commercial 82/58, Crossbred 512/89, Indigenous 417/87.
#
# Do not mix edge/node sets across versions.

suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(ggraph)
  library(ragg)
  library(patchwork)
})
source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))
source(file.path(REPO_ROOT, "R", "common", "taxonomy_map.R"))

version_tag <- "breed"

phylum_cols <- c(
  Firmicutes = "#CAB2D6", Bacteroidota = "#1F78B4", Proteobacteria = "#33A02C",
  Spirochaetota = "#E31A1C", Actinobacteriota = "#FF7F00", Other = "grey70"
)
genus_map <- load_genus_phylum_map()


  edges <- read_source_table(file.path(DATA_DIR, "fig04/Figure4DEF_network_edges.tsv.gz")) %>%
    as_tibble() %>%
    transmute(
      breed_group = as.character(breed_group),
      from = as.character(taxon_1),
      to = as.character(taxon_2),
      correlation = as.numeric(correlation),
      sign = as.character(sign)
    )
  nodes <- read_source_table(file.path(DATA_DIR, "fig04/Figure4DEF_network_nodes.tsv.gz")) %>%
    as_tibble() %>%
    transmute(
      breed_group = as.character(breed_group),
      name = as.character(taxon),
      rel_abundance = as.numeric(relative_abundance_for_node_size)
    )
  expected <- list(
    Commercial = c(edges = 82, nodes = 58),
    Crossbred = c(edges = 512, nodes = 89),
    Indigenous = c(edges = 417, nodes = 87)
  )


make_one <- function(bg) {
  e <- edges %>% filter(breed_group == bg)
  if (!nrow(e)) return(ggplot() + theme_void() + labs(title = bg))

  if (!is.null(nodes) && nrow(nodes)) {
    v <- nodes %>% filter(breed_group == bg) %>% select(any_of(c("name", "rel_abundance", "Phylum")))
  } else {
    v <- tibble(name = unique(c(e$from, e$to)), rel_abundance = NA_real_)
  }
  if (!"Phylum" %in% names(v)) v$Phylum <- NA_character_

  if ("phylum_from" %in% names(e)) {
    phy_edge <- bind_rows(
      e %>% transmute(name = from, Phylum = phylum_from),
      e %>% transmute(name = to, Phylum = phylum_to)
    ) %>%
      filter(!is.na(Phylum), nzchar(Phylum)) %>%
      group_by(name) %>%
      summarise(Phylum_edge = dplyr::first(Phylum), .groups = "drop")
    v <- v %>% left_join(phy_edge, by = "name") %>%
      mutate(Phylum = coalesce(Phylum, Phylum_edge)) %>%
      select(-any_of("Phylum_edge"))
  }

  # source table genus map for remaining gaps (audited; ambiguous → Other).
  need <- is.na(v$Phylum) | !nzchar(v$Phylum)
  if (any(need)) {
    v$Phylum[need] <- map_taxon_to_phylum(v$name[need], genus_map, allowed = names(phylum_cols))
  }
  v <- v %>%
    mutate(
      Phylum = if_else(is.na(Phylum) | !Phylum %in% names(phylum_cols), "Other", Phylum),
      rel_abundance = as.numeric(rel_abundance)
    )
  if (any(!is.finite(v$rel_abundance))) {
    stop(
      "Missing relative abundance for ", bg, " (", version_tag, "). ",
      "Refuse constant 0.03 fill-in."
    )
  }

  exp <- expected[[bg]]
  n_e <- nrow(e)
  n_v <- nrow(v)
  title_extra <- ""
  if (!is.null(exp)) {
    if (n_e != exp[["edges"]] || n_v != exp[["nodes"]]) {
      title_extra <- sprintf(" [expected %d/%d]", exp[["edges"]], exp[["nodes"]])
    }
  }

  g <- graph_from_data_frame(
    e %>% select(from, to, correlation, sign),
    vertices = v %>% select(name, rel_abundance, Phylum),
    directed = FALSE
  )
  # Title counts must match the plotted graph object.
  n_e_g <- igraph::ecount(g)
  n_v_g <- igraph::vcount(g)
  lay <- create_layout(g, layout = "circle")
  ggraph(lay) +
    geom_edge_link(aes(color = sign, width = abs(correlation)), alpha = 0.75) +
    geom_node_point(aes(size = rel_abundance, fill = Phylum),
                    shape = 21, color = "grey20", stroke = 0.2, show.legend = bg == "Commercial") +
    scale_edge_color_manual(
      values = c(Positive = "#D73027", Negative = "#4575B4",
                 positive = "#D73027", negative = "#4575B4"),
      guide = "none"
    ) +
    scale_edge_width(range = c(0.2, 1.0), guide = "none") +
    scale_fill_manual(values = phylum_cols, limits = names(phylum_cols), drop = FALSE, name = "Phylum") +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3, fill = unname(phylum_cols)))) +
    scale_size_continuous(range = c(1.4, 5.5), guide = "none") +
    labs(title = paste0(
      bg, "\n", n_e_g, " edges, ", n_v_g, " nodes", title_extra
    )) +
    theme_graph(base_family = FONT) +
    coord_fixed(xlim = c(-1.2, 1.2), ylim = c(-1.2, 1.2), clip = "off") +
    theme(plot.title = element_text(size = S_TITLE, hjust = 0.5, family = FONT))
}

# Write phylum mapping audit for corrected nodes.
{
  audit <- nodes %>%
    mutate(
      Phylum = map_taxon_to_phylum(name, genus_map, allowed = names(phylum_cols)),
      mapped_via = "T09_genus"
    )
  write_tsv(audit, file.path(MANIFEST_DIR, "fig04_DEF_corrected_node_phylum_map.tsv"))
  if (nrow(genus_map$ambiguous)) {
    write_tsv(
      genus_map$ambiguous,
      file.path(MANIFEST_DIR, "fig04_DEF_t09_ambiguous_genus_phylum.tsv")
    )
  }
}

p <- (make_one("Commercial") | make_one("Crossbred") | make_one("Indigenous")) +
  plot_layout(guides = "collect") & theme(legend.position = "bottom")
save_panel(
  p,
  paste0("fig04_panel_DEF_networks_", version_tag),
  width_mm = 180, height_mm = 85
)
message(
  "China network version: ", version_tag,
  " | Formal Fig4 manuscript panel: author-owned, not replaced here."
)
