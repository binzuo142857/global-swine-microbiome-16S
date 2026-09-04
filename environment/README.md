# R environment

Tested with Windows R 4.4.1. `package_versions.tsv` lists the plotting packages and dependencies in installation order; `sessionInfo.txt` records the validation session. Figure 4A uses `sf`; its GDAL, GEOS and PROJ versions are listed in `spatial_versions.tsv`.

Run `scripts/install_packages.R` to install missing packages. To restore the recorded versions into a separate library, use `scripts/restore_recorded_environment.R`; installing archived source packages may require R build tools.

PNG export uses ragg; PDF export uses Cairo. Set `FRW_FONT` to choose a local font, or use the default `sans`.
