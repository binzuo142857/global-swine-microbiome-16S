# Install plotting dependencies. Recorded tested versions are in environment/.
packages <- c("tidyverse", "data.table", "scales", "ragg", "patchwork", "RColorBrewer",
              "cowplot", "igraph", "ggraph", "maps", "ggrepel", "viridis", "ggridges", "digest")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("Plotting packages are available. See environment/package_versions.tsv for tested versions.")
