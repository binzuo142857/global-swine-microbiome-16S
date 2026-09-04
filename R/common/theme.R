# Shared publication theme helpers (ArialMT, compact 6-8 pt).

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
  library(RColorBrewer)
})

FONT <- Sys.getenv("FRW_FONT", "sans")
INK <- "#000000"
S_TITLE <- 8
S_AX_TIT <- 7
S_AX_TXT <- 6
S_LEG_TIT <- 6.5
S_LEG_TXT <- 6
S_TAG <- 10
pt_to_mm <- function(pt) pt / ggplot2::.pt

CONTINENT_ORDER <- c("Europe", "North America", "Asia", "Oceania", "South America")
CONTINENT_COLORS <- setNames(RColorBrewer::brewer.pal(5, "Dark2"), CONTINENT_ORDER)

BREED_ORDER_SOURCE <- c("commercial", "crossbred", "Local China")
BREED_LABELS <- c(
  commercial = "Commercial",
  crossbred = "Crossbred",
  `Local China` = "Indigenous"
)
BREED_COLORS <- c(
  commercial = "#DDCC77",
  crossbred = "#4477AA",
  `Local China` = "#CC6677"
)

base_theme_pub <- function() {
  theme(
    text = element_text(size = S_AX_TXT, family = FONT, color = INK),
    plot.title = element_text(
      size = S_TITLE, hjust = 0.5, face = "plain", color = INK, margin = margin(b = 1)
    ),
    axis.title = element_text(size = S_AX_TIT, color = INK, family = FONT),
    axis.text = element_text(size = S_AX_TXT, color = INK, family = FONT),
    legend.title = element_text(size = S_LEG_TIT, color = INK, family = FONT),
    legend.text = element_text(size = S_LEG_TXT, color = INK, family = FONT),
    legend.key.size = unit(3, "mm"),
    plot.margin = margin(2, 3, 2, 3)
  )
}

save_panel <- function(plot_obj, stem, width_mm, height_mm, out_dir = OUT_PANELS) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  png_f <- file.path(out_dir, paste0(stem, ".png"))
  pdf_f <- file.path(out_dir, paste0(stem, ".pdf"))
  png_tmp <- tempfile(pattern = paste0(stem, "_"), tmpdir = out_dir, fileext = ".png")
  pdf_tmp <- tempfile(pattern = paste0(stem, "_"), tmpdir = out_dir, fileext = ".pdf")
  on.exit(unlink(c(png_tmp, pdf_tmp)), add = TRUE)
  ggplot2::ggsave(
    png_tmp, plot_obj, width = width_mm, height = height_mm, units = "mm",
    dpi = 300, device = ragg::agg_png, bg = "white", limitsize = FALSE
  )
  ggplot2::ggsave(
    pdf_tmp, plot_obj, width = width_mm, height = height_mm, units = "mm",
    device = grDevices::cairo_pdf, bg = "white", limitsize = FALSE
  )
  if (!file.exists(pdf_tmp) || file.info(pdf_tmp)$size < 100 ||
      !identical(rawToChar(readBin(pdf_tmp, "raw", n = 5)), "%PDF-")) {
    stop("PDF export did not create a valid new file; previous outputs were retained: ", stem)
  }
  if (!file.exists(png_tmp) || file.info(png_tmp)$size < 100) stop("PNG export failed: ", stem)
  if (!file.copy(png_tmp, png_f, overwrite = TRUE) || !file.copy(pdf_tmp, pdf_f, overwrite = TRUE)) {
    stop("Could not publish the new PNG/PDF pair: ", stem)
  }
  message("Saved ", png_f)
  message("Saved ", pdf_f)
  invisible(c(png = png_f, pdf = pdf_f))
}

fmt_billion_reads <- function(x) {
  sprintf("%.2f Billion reads", as.numeric(x) / 1e9)
}

read_source_table <- function(path) {
  require_file(path)
  as.data.frame(readr::read_tsv(path, show_col_types = FALSE, guess_max = 100000), stringsAsFactors = FALSE)
}
