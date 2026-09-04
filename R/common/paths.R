# Shared, repository-relative inputs. Run through scripts/render_figures.R.
REPO_ROOT <- normalizePath(Sys.getenv("SWINE_REPO_ROOT", getwd()), winslash = "/", mustWork = TRUE)
DATA_DIR <- file.path(REPO_ROOT, "data")
if (!dir.exists(DATA_DIR)) stop("The repository data directory is missing.")
data_file <- function(name) file.path(DATA_DIR, name)
require_file <- function(path, label = basename(path)) {
  if (!file.exists(path)) stop("Missing required input: ", label, "\n", path, call. = FALSE)
  invisible(path)
}
out <- Sys.getenv("SWINE_FIGURE_DIR", "")
if (!nzchar(out)) stop("Set an output folder with --out when running scripts/render_figures.R.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
OUT_PANELS <- normalizePath(out, winslash = "/", mustWork = TRUE)
if (identical(tolower(OUT_PANELS), tolower(REPO_ROOT)) ||
    startsWith(tolower(OUT_PANELS), paste0(tolower(REPO_ROOT), "/"))) {
  stop("Use an output folder outside this repository; generated figures are not versioned.")
}
MANIFEST_DIR <- file.path(OUT_PANELS, "run_records")
dir.create(MANIFEST_DIR, recursive = TRUE, showWarnings = FALSE)
