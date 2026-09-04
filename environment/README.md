# Tested environment

`package_versions.tsv` records the installed versions of the direct plotting packages and their available non-base dependencies, in dependency order. `sessionInfo.txt` records the final successful plotting validation session. Validation used Windows-native R 4.4.1; some installed Windows binaries were built under R 4.4.3 and emitted package-build warnings without preventing rendering.

`scripts/install_packages.R` provides a simple missing-package installer. `scripts/restore_recorded_environment.R` is an optional helper for installing the recorded package versions into a separate external library. It uses archived CRAN source versions, may require the appropriate build tools, and was not used to reinstall the already available validation environment. Cross-platform package restoration is not claimed to have been tested.

PNG output uses ragg and PDF output uses the R Cairo device. `FRW_FONT` optionally selects a locally available font; the default `sans` avoids a requirement for a specific proprietary font. Fonts and network layout positions are not numerical reproduction criteria.
