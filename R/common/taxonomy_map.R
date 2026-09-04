# Auditable genus / taxon-label → phylum map (+ optional edge phylum cols).

load_genus_phylum_map <- function() {
  t09 <- read_source_table(data_file("shared/taxonomy_dictionary.tsv.gz")) %>%
    as_tibble() %>%
    transmute(
      genus = as.character(genus),
      phylum = as.character(phylum),
      feature_id = as.character(feature_id),
      display_name = as.character(display_name)
    ) %>%
    filter(!is.na(genus), nzchar(genus), !is.na(phylum), nzchar(phylum))

  by_genus <- t09 %>%
    count(genus, phylum, name = "n") %>%
    arrange(genus, desc(n)) %>%
    group_by(genus) %>%
    mutate(n_phyla = n_distinct(phylum), share = n / sum(n)) %>%
    slice_max(n, n = 1, with_ties = FALSE) %>%
    ungroup()

  ambiguous <- by_genus %>% filter(n_phyla > 1)
  list(map = by_genus, ambiguous = ambiguous, t09 = t09)
}

normalize_taxon_label <- function(x) {
  x <- as.character(x)
  x <- gsub("^g__", "", x)
  x <- gsub("_group$", "", x)
  x
}

map_taxon_to_phylum <- function(taxa, genus_map, allowed = NULL) {
  taxa <- as.character(taxa)
  norm <- normalize_taxon_label(taxa)
  hit <- genus_map$map$phylum[match(norm, genus_map$map$genus)]
  # Also try raw label and feature_id / display_name
  miss <- is.na(hit)
  if (any(miss)) {
    alt <- genus_map$t09 %>%
      distinct(feature_id, display_name, phylum)
    hit[miss] <- alt$phylum[match(taxa[miss], alt$feature_id)]
    miss <- is.na(hit)
    hit[miss] <- alt$phylum[match(taxa[miss], alt$display_name)]
    miss <- is.na(hit)
    hit[miss] <- alt$phylum[match(norm[miss], normalize_taxon_label(alt$display_name))]
  }
  if (!is.null(allowed)) {
    hit <- if_else(is.na(hit) | !hit %in% allowed, "Other", hit)
  }
  hit
}
