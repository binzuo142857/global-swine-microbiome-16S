# Reproduction scope

The scripts reproduce the statistical content and broad panel structure from the included result tables. They do not reproduce final journal typesetting or require identical pixel positions. Generated PNG/PDF files and run records are written to a user-selected folder outside the repository.

## Included

- Figure 1A-I; Figure 2A-D; Figure 3A-F; Figure 4B-G; Figure 5A-I.
- Supplementary Figures S1A-D, S2A-C, S3A-B and S4A-B.
- The adopted canonical continental network and corrected China breed network inputs.
- Original adopted PAM result tables, abundance tables, effect sizes and saved test results.

Figure 4A is an externally prepared breed map and has no scripted reproduction in this repository. Full-figure assembly, graphical abstracts and final editorial artwork are outside the scripted scope.

## Display choices

- Network positions are layout choices. Node/edge sets, node abundance, phylum assignment, correlation sign and strength remain tied to the included data. Europe has 44 edges and 40 genera; China breed edge/node counts are 82/58, 512/89 and 417/87.
- Figure 4G encodes mean relative abundance (%) with bubble size and one-vs-all LFC with colour. Its optional annotation layer uses the supplied `robust_sig` field. This release's plotting script displays those marks; it does not regenerate the upstream robust-significance calculation.
- Figure S2C defaults to the complete exported matrix: 85 taxa by 15 countries. The alternative `TAXA_FILTER=rf_star` branch is a documented display option, not a different RF fit. Exact manuscript cropping or a narrower display selection is not established by this source export alone.
- Figure 5 enterotype panels use median centres and interquartile arms. Large point layers use the fixed display seed and caps written in the helper functions; those display subsets do not change the supplied assignments or full-group summary statistics. Gut-site ridgelines use the saved coordinates and the script's fixed display sample.
- The country map sums country counts across rows before joining polygons; it does not reassign continent labels in the analysis metadata. Map geometry comes from the R `maps` package. Labels such as Czech/UK are matched to the polygon vocabulary in the plotting script.

## What is not distributed

Raw reads, full count matrices, raw SRA metadata downloads, distance matrices, fitted-model caches, bootstrap matrices, generated figures and local working histories are not required by the plotting entry point and are not distributed here.

See [the analysis scope](../analysis/README.md) for the boundary between saved-result figure reproduction and upstream analysis reproduction.
