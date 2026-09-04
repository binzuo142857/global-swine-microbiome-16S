# Analysis provenance and scope

The executable entry point in this repository regenerates figures from saved results. It does not rerun sequence processing, ordination, model fitting, clustering, permutations or network inference.

The adopted network source tables contain the displayed edges, nodes, correlations and graph summaries. The China breed results were generated after removing zero-total sample columns from both focal and comparison matrices, keeping the selected taxa fixed. Six FastSpar runs used seed 1, 1,000 bootstrap replicates and 1,000 empirical permutations. The displayed-edge threshold is absolute correlation > 0.20 and empirical P <= 0.001; additional focal-specificity criteria are recorded in the edge tables. Network links are co-abundance associations.

The enterotype panels use the manuscript's adopted PAM assignments and saved PCoA coordinates. Plotting code does not recompute clustering or change the selected k. The retained finishing-stage partition has k = 10. See T37 and T38 for sample-level plotted results.

ANCOM-BC2 effect sizes and adjusted P values, LEfSe scores, RF performance/importance summaries and DBI permutation results are provided as saved tables. Figure 4C reads the saved pairwise Wilcoxon/BH results. Upstream model formulas or missing analysis parameters should be taken from the manuscript and original analysis records, not inferred from the plotting code.

The adopted China-network FastSpar rerun and comparison scripts are included in [china_network/](china_network/). Only their external path configuration was adapted; their syntax was checked, and the analysis was not rerun during packaging. They need additional archived inputs that are intentionally not shipped with this lightweight plotting package. Other original upstream analysis scripts are not included where a complete verified snapshot was unavailable. In particular, the original OVA/robust-significance and country-signature selection routines still require a verified archival snapshot. This does not prevent plotting the included results, but this release should not be cited as an end-to-end raw-read analysis pipeline.
