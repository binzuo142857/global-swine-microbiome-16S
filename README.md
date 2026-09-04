# Global swine gut microbiome

Source tables and R figure scripts accompanying **A Global Reference Compendium of the Swine Gut Microbiome Reveals Under-characterized Diversity and Biogeographic Structure**.

This repository regenerates figure panels from processed, adopted study results. It includes 36 compressed tables and 35 panel scripts. It does not require raw sequence files, full count matrices or model caches. Generated figures are not stored in the repository.

## Quick start

Use R with the packages listed in `environment/package_versions.tsv`. The package was tested with R 4.4.1 on Windows; exact tested package versions are recorded rather than assuming that all future versions behave identically.

```sh
git clone https://github.com/binzuo142857/global-swine-microbiome-16S.git
cd global-swine-microbiome-16S
Rscript scripts/install_packages.R
Rscript scripts/check_inputs.R
Rscript scripts/render_figures.R --figure fig03 --out ../swine-figure-check
```

Use `--figure all` to run all panel scripts. Figure groups are `fig01` through `fig05` and `figS01` through `figS04`. The output folder must be outside this repository. If `--out` is omitted, the runner creates an external temporary directory and reports its path. The runner writes PNG/PDF panels, per-script status and session information there.

The installation helper installs missing packages from CRAN. It does not silently downgrade an existing R library; compare the recorded versions when investigating a rendering difference. An exact package-version restore helper is also provided in `scripts/restore_recorded_environment.R`.

## Find the code and data for a figure

Start with [figure_data_code_map.tsv](docs/figure_data_code_map.tsv). The [source-table guide](docs/data_dictionary.md) explains the quantities and units; [provenance.tsv](docs/provenance.tsv) records table sources and checksums.

```text
data/source_tables/  Processed source tables with retained T identifiers
data/plot_inputs/    Additional compact inputs required by panel scripts
R/common/           Shared input, theme, taxonomy and PCoA helpers
R/figures/          Scripts grouped by manuscript figure
scripts/            Input checks, dependency setup and plotting entry point
environment/        Tested R and package versions
docs/               Figure index, data definitions and provenance
analysis/           Scope and provenance of the saved upstream results
```

## Scope

The executable workflow plots saved results; it does not rerun FastSpar, PAM, ordination, RF training or differential-abundance models. The adopted China-network analysis scripts are included separately; other upstream scripts are omitted where a verified snapshot was unavailable. See [analysis/README.md](analysis/README.md) and [reproduction_scope.md](docs/reproduction_scope.md) for coverage, display choices and the externally prepared Figure 4A.

Network source tables use canonical continental taxon names and the adopted China breed results. Enterotype plots retain the manuscript's adopted PAM result tables. Graph layouts and final journal typesetting need not be pixel-identical to obtain the same plotted data and statistical meaning.

## Citation and contact

Manuscript authors and the current manuscript title are recorded in `CITATION.cff`. No publication DOI is assigned in this repository until available. Please include the commit identifier when referring to a particular code snapshot.

Questions can be raised through this repository's Issues. A repository-wide reuse license has not yet been specified by the authors.
