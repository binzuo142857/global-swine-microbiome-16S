# Validation of the packaged figures

Validated on 2026-09-04 using Windows-native R 4.4.1 and the package versions recorded under `environment/`.

- All 35 panel scripts ran successfully from an isolated copy containing only repository code, documentation and the published input tables. Three subsequent display-only adjustments were rerendered from that copy: DBI annotation spacing, the Figure 3F metric order and the Figure 4B group order.
- The 39 generated PNG/PDF pairs were inspected locally; each PDF was readable and contained one page. Generated images and local run logs are not included in the repository.
- All 36 input tables passed SHA256, row-count and column-count checks. No input table exceeds 5 MiB; the largest compressed table is approximately 3.35 MiB.
- Continental graphs contain 176/73, 44/40 and 9/10 edges/nodes for Asia, Europe and North America. China graphs contain 82/58, 512/89 and 417/87 for Commercial, Crossbred and Indigenous. Plotted endpoint sets match the node tables.
- T42 contains 108 rows with true mean abundance and OVA LFC; T43 contains 111 rows with the saved LEfSe/abundance quantities.
- The adopted PAM partitions remain k = 2, 2, 5, 6 and 10 for global feces, lactation, nursery, growing and finishing. Global fecal coordinates contain 35,065 samples.
- The two additional China-network analysis scripts were checked for Python syntax and documented path adaptation. They were not executed, and their extra archived analysis inputs are not part of the lightweight plotting package.

Package-build-version warnings and the expected log-scale warning for zero frequency bins did not change successful exports. Upstream statistical analyses, package reinstallation and cross-platform execution were not part of this validation. This validation establishes the saved-result plotting workflow; it does not assert a complete raw-read analysis pipeline or pixel-identical journal artwork.
