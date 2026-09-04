# Restore recorded package versions into an external library, without changing
# the user's default library. Source installation may require compiler tools.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript scripts/restore_recorded_environment.R <external-library-directory>")
file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
repo <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), winslash = "/", mustWork = TRUE)
dir.create(args[1], recursive = TRUE, showWarnings = FALSE)
lib <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
if (startsWith(tolower(paste0(lib, "/")), tolower(paste0(repo, "/")))) stop("Use a library directory outside the repository")
.libPaths(c(lib, .libPaths()))
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", lib = lib, repos = "https://cloud.r-project.org")
record <- read.delim(file.path(repo, "environment", "package_versions.tsv"), check.names = FALSE)
if (as.character(getRversion()) != "4.4.1") message("Recorded validation used R 4.4.1; current R is ", getRversion())
for (i in seq_len(nrow(record))) {
  package <- record$Package[i]
  current <- tryCatch(as.character(utils::packageVersion(package, lib.loc = lib)), error = function(e) "")
  if (current != record$Version[i]) {
    remotes::install_version(package, version = record$Version[i], lib = lib,
      repos = "https://cloud.r-project.org", dependencies = FALSE, upgrade = "never")
  }
}
message("Restored packages to ", lib, ". Use this directory in R_LIBS_USER for subsequent R sessions.")
