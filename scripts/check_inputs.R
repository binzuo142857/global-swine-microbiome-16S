# Validate the included source tables without rerunning statistical analyses.
if (!exists("REPO_ROOT")) {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
  REPO_ROOT <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), winslash = "/", mustWork = TRUE)
}
if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("readr", quietly = TRUE)) {
  stop("Install the plotting dependencies first: Rscript scripts/install_packages.R")
}
manifest <- readr::read_tsv(file.path(REPO_ROOT, "docs", "provenance.tsv"), show_col_types = FALSE)
for (i in seq_len(nrow(manifest))) {
  p <- file.path(REPO_ROOT, manifest$published_file[i])
  if (!file.exists(p)) stop("Missing published table: ", manifest$published_file[i])
  if (digest::digest(p, algo = "sha256", file = TRUE) != manifest$published_sha256[i]) {
    stop("Source-table checksum mismatch: ", manifest$published_file[i])
  }
}
tab <- function(name, input = FALSE) readr::read_tsv(
  file.path(REPO_ROOT, "data", if (input) "plot_inputs" else "source_tables", name), show_col_types = FALSE)
check_graph <- function(edges, nodes, group, node, expected) {
  for (g in names(expected)) {
    e <- edges[edges[[group]] == g, ]; n <- nodes[nodes[[group]] == g, ]
    stopifnot(nrow(e) == expected[[g]][1], length(unique(c(e$taxon_1, e$taxon_2))) == expected[[g]][2])
    stopifnot(setequal(unique(c(e$taxon_1, e$taxon_2)), unique(n[[node]])))
    stopifnot(all(abs(e$correlation) > 0.2), !anyNA(e$correlation))
  }
}
check_graph(tab("corrected_continental_network_edges.tsv.gz", TRUE),
  tab("corrected_continental_network_nodes.tsv.gz", TRUE), "continent", "display_label",
  list(Asia = c(176, 73), Europe = c(44, 40), `North America` = c(9, 10)))
check_graph(tab("china_breed_corrected_displayed_edges.tsv.gz", TRUE),
  tab("china_breed_corrected_displayed_nodes.tsv.gz", TRUE), "breed_group", "taxon",
  list(Commercial = c(82, 58), Crossbred = c(512, 89), Indigenous = c(417, 87)))
s <- tab("T28_network_summary_metrics.tsv.gz")
stopifnot(all(abs(s$mean_degree - 2 * s$specific_edges / s$network_nodes) < 1e-10))
ova <- tab("T42_fig04G_ova_abundance_bubble.tsv.gz")
lefse <- tab("T43_figS04B_lefse_combo_right.tsv.gz")
stopifnot(nrow(ova) == 108, all(is.finite(ova$Mean_Abund)), all(ova$Mean_Abund >= 0),
  all(is.finite(ova$one_vs_all_lfc_full)), nrow(lefse) == 111, all(lefse$abs_lda >= 3.5))
message("Verified ", nrow(manifest), " source-table hashes and adopted network/abundance checks.")
