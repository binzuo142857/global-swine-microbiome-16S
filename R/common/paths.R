# Shared, repository-relative inputs. Run through scripts/render_figures.R.
REPO_ROOT <- normalizePath(Sys.getenv("SWINE_REPO_ROOT", getwd()), winslash = "/", mustWork = TRUE)
SOURCE_TABLES <- file.path(REPO_ROOT, "data", "source_tables")
PLOT_INPUTS <- file.path(REPO_ROOT, "data", "plot_inputs")
if (!dir.exists(SOURCE_TABLES) || !dir.exists(PLOT_INPUTS)) {
  stop("Run Rscript scripts/render_figures.R from a complete repository checkout.")
}
source_table <- function(name) file.path(SOURCE_TABLES, name)
plot_input <- function(name) file.path(PLOT_INPUTS, name)
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
