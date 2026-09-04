# Validation

Validated on 2026-09-04 with R 4.4.1 and the package versions in `environment/`.

- All 36 figure scripts completed in an independent copy of the repository, producing 40 PNG/PDF pairs.
- The 37 input tables and Figure 4A map geometry passed checksum and structure checks. The breed map retains the original 23 breeds, coordinates and sample counts (2,453 in total), and its map geometry is byte-identical to the supplied source.
- Continental edge/node counts are 176/73, 44/40 and 9/10; China breed counts are 82/58, 512/89 and 417/87. Graph endpoints match the node tables.
- Input renaming and removal of internal file-tracking columns preserved all scientific values. Two later metadata-only edits were checked against the same inputs.
- The optional FastSpar scripts passed Python syntax checks; upstream statistical analyses were not rerun.

Generated figures and validation logs are kept outside the repository.
