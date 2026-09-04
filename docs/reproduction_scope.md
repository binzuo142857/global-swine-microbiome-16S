# Plotting notes

Scripts cover Figure 1A–I, Figure 2A–D, Figure 3A–F, Figure 4A–G, Figure 5A–I and Supplementary Figures S1–S4. They export individual panels for subsequent figure assembly.

- **Maps:** Figure 1A uses the R `maps` geometry. Figure 4A uses the included GeoJSON and breed-location table; map attribution remains in the panel.
- **Networks:** layout positions may vary with package versions. Edge/node identities, abundance and correlation encodings come from the supplied tables.
- **Figure 4G:** size represents mean relative abundance (%), colour represents one-vs-all LFC, and the annotation layer reads `robust_sig`.
- **Figure S2C:** the default displays the complete 85-taxon × 15-country matrix. `TAXA_FILTER=rf_star` selects the alternative RF-marked display subset. The exact cropped row set of the manuscript artwork is not recorded in this export.
- **Figure 5:** centres and arms show medians and interquartile ranges. Point subsampling uses the fixed seeds and caps in the scripts; group summaries use all supplied observations.

Tested package versions are in `environment/`. Use `scripts/restore_recorded_environment.R` when an exact package-version restore is needed.
