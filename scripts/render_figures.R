#!/usr/bin/env Rscript
# Render one figure group or all groups from published source tables.
args <- commandArgs(trailingOnly = TRUE)
value <- function(flag, default) {
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i == length(args)) stop("Missing value after ", flag)
  args[i + 1L]
}
file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
repo <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), winslash = "/", mustWork = TRUE)
out <- value("--out", tempfile("swine-figures-"))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)
Sys.setenv(SWINE_REPO_ROOT = repo, SWINE_FIGURE_DIR = out)
setwd(repo)
source("R/common/paths.R")
source("scripts/check_inputs.R")
figure <- value("--figure", "all")
available <- list.dirs("R/figures", full.names = FALSE, recursive = FALSE)
if (!figure %in% c("all", available)) stop("Unknown figure: ", figure, ". Use ", paste(available, collapse = ", "))
dirs <- if (figure == "all") available else figure
scripts <- sort(unlist(lapply(dirs, function(d) list.files(file.path("R/figures", d), "\\.R$", full.names = TRUE))))
records <- list()
for (s in scripts) {
  message("Rendering ", s)
  set.seed(1)
  start <- Sys.time()
  warnings <- character()
  err <- tryCatch({
    withCallingHandlers(source(s, local = new.env(parent = globalenv()), encoding = "UTF-8"),
      warning = function(w) {warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")})
    ""
  }, error = function(e) conditionMessage(e))
  records[[length(records) + 1L]] <- data.frame(script = s, success = !nzchar(err),
    seconds = round(as.numeric(difftime(Sys.time(), start, units = "secs")), 2),
    error = err, warnings = paste(unique(warnings), collapse = " | "))
  if (nzchar(err)) message("Failed: ", err)
}
result <- do.call(rbind, records)
write.table(result, file.path(MANIFEST_DIR, "render_status.tsv"), sep = "\t", row.names = FALSE, quote = TRUE)
writeLines(capture.output(sessionInfo()), file.path(MANIFEST_DIR, "sessionInfo.txt"))
if (any(!result$success)) stop("One or more figures failed. See ", file.path(MANIFEST_DIR, "render_status.tsv"))
message("Completed ", nrow(result), " scripts. Generated files are outside the repository: ", out)
