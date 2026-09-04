#!/usr/bin/env Rscript
# Figure 3A–C — continent-specific co-abundance networks.
# Both ABC and F must use the same version (see panel_F_summary.R).
# Titles: co-abundance associations. Counts match plotted graph objects.

suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(ggraph)
  library(ragg)
  library(patchwork)
})

source(file.path("R", "common", "paths.R"))
source(file.path(REPO_ROOT, "R", "common", "theme.R"))

net_ver <- "continental"

phylum_cols <- c(
  Firmicutes = "#CAB2D6", Bacteroidota = "#1F78B4", Proteobacteria = "#33A02C",
  Spirochaetota = "#E31A1C", Actinobacteriota = "#FF7F00", Other = "grey70"
)


  edges <- read_source_table(file.path(DATA_DIR, "fig03/Figure3ABC_network_edges.tsv.gz")) %>%
    as_tibble() %>%
    transmute(
      continent = as.character(continent),
      from = as.character(taxon_1),
      to = as.character(taxon_2),
      correlation = as.numeric(correlation),
      sign = as.character(sign)
    ) %>%
    filter(continent %in% c("Asia", "Europe", "North America"), abs(correlation) > 0.20)
  nodes_raw <- read_source_table(file.path(DATA_DIR, "fig03/Figure3ABC_network_nodes.tsv.gz")) %>%
    as_tibble()
  nodes_lookup <- nodes_raw %>%
    transmute(
      continent = as.character(continent),
      name = as.character(dplyr::coalesce(
        as.character(.data[["display_label"]]),
        as.character(.data[["original_taxon_name"]])
      )),
      name_alt = as.character(.data[["original_taxon_name"]]),
      Phylum = as.character(phylum),
      rel_abundance = as.numeric(relative_abundance_for_node_size)
    )
  expected <- list(
    Asia = c(edges = 176, nodes = 73),
    Europe = c(edges = 44, nodes = 40),
    `North America` = c(edges = 9, nodes = 10)
  )


make_net <- function(cont) {
  e <- edges %>% filter(continent == cont)
  if (!nrow(e)) return(ggplot() + theme_void() + labs(title = cont))
  vert <- tibble(name = unique(c(e$from, e$to)))
  if ("phylum_from" %in% names(e)) {
    phy <- bind_rows(
      e %>% transmute(name = from, Phylum = phylum_from),
      e %>% transmute(name = to, Phylum = phylum_to)
    ) %>%
      group_by(name) %>%
      summarise(Phylum = dplyr::first(na.omit(Phylum)), .groups = "drop")
    vert <- vert %>% left_join(phy, by = "name")
  } else {
    vert$Phylum <- NA_character_
  }
  if (!is.null(nodes_lookup)) {
    nl <- nodes_lookup
    if ("continent" %in% names(nl) && any(!is.na(nl$continent))) {
      nl <- nl %>% filter(is.na(continent) | continent == cont)
    }
    # Match display or original labels
    join_ab <- nl %>%
      select(name, rel_abundance, Phylum_n = Phylum) %>%
      distinct(name, .keep_all = TRUE)
    vert <- vert %>%
      left_join(join_ab, by = "name") %>%
      mutate(Phylum = coalesce(Phylum, Phylum_n)) %>%
      select(-Phylum_n)
    if ("name_alt" %in% names(nl)) {
      join_alt <- nl %>%
        select(name_alt, rel_abundance_alt = rel_abundance, Phylum_alt = Phylum) %>%
        distinct(name_alt, .keep_all = TRUE)
      vert <- vert %>%
        left_join(join_alt, by = c("name" = "name_alt")) %>%
        mutate(
          rel_abundance = coalesce(rel_abundance, rel_abundance_alt),
          Phylum = coalesce(Phylum, Phylum_alt)
        ) %>%
        select(-any_of(c("rel_abundance_alt", "Phylum_alt")))
    }
  }
  if (!"rel_abundance" %in% names(vert)) vert$rel_abundance <- NA_real_
  if (all(is.na(vert$rel_abundance))) {
    warning(cont, ": no node abundance joined; using min placeholder only for missing after partial join")
  }
  if (any(!is.finite(vert$rel_abundance))) {
    stop(cont, ": refusing to invent abundance; provide node abundance source for ", net_ver)
  }
  vert <- vert %>%
    mutate(
      Phylum = if_else(is.na(Phylum) | !Phylum %in% names(phylum_cols), "Other", Phylum),
      rel_abundance = as.numeric(rel_abundance)
    )
  g <- graph_from_data_frame(e %>% select(from, to, correlation, sign), vertices = vert, directed = FALSE)
  n_e_g <- igraph::ecount(g)
  n_v_g <- igraph::vcount(g)
  exp <- expected[[cont]]
  note <- ""
  if (!is.null(exp) && (n_e_g != exp[["edges"]] || n_v_g != exp[["nodes"]])) {
    note <- sprintf(" [expected %d/%d]", exp[["edges"]], exp[["nodes"]])
  }
  lay <- create_layout(g, layout = "circle")
  ggraph(lay) +
    geom_edge_link(aes(color = sign, width = abs(correlation)), alpha = 0.75) +
    geom_node_point(aes(size = rel_abundance, fill = Phylum), shape = 21, color = "grey20", stroke = 0.2, show.legend = cont == "Asia") +
    scale_edge_color_manual(
      values = c(Positive = "#D73027", Negative = "#4575B4", positive = "#D73027", negative = "#4575B4"),
      guide = "none"
    ) +
    scale_edge_width(range = c(0.2, 1.1), guide = "none") +
    scale_fill_manual(values = phylum_cols, limits = names(phylum_cols), drop = FALSE, name = "Phylum") +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3, fill = unname(phylum_cols)))) +
    scale_size_continuous(range = c(1.5, 6), guide = "none") +
    labs(title = paste0(
      cont, "\nco-abundance associations\n",
      n_e_g, " edges, ", n_v_g, " nodes", note
    )) +
    theme_graph(base_family = FONT) +
    coord_fixed(xlim = c(-1.2, 1.2), ylim = c(-1.2, 1.2), clip = "off") +
    theme(
      plot.title = element_text(size = S_TITLE, hjust = 0.5, family = FONT),
      legend.position = "bottom"
    )
}

p <- (make_net("Asia") | make_net("Europe") | make_net("North America")) +
  plot_layout(guides = "collect") & theme(legend.position = "bottom")
save_panel(p, paste0("fig03_panel_ABC_networks_", net_ver), width_mm = 180, height_mm = 90)
message("Fig3 ABC NETWORK_VERSION=", net_ver, " (continental main-figure choice: pending author)")
