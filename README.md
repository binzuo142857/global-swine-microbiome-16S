# Global swine gut microbiome

Code and data for **A Global Reference Compendium of the Swine Gut Microbiome Reveals Core Bacterial Members and Geographic Signatures**.

Run the R scripts to generate Figures 1–5 and Supplementary Figures S1–S4 from the included tables.

## Getting started

The scripts were tested with R 4.4.1. Install the packages, check the inputs, and render a figure:

```sh
git clone https://github.com/binzuo142857/global-swine-microbiome-16S.git
cd global-swine-microbiome-16S
Rscript scripts/install_packages.R
Rscript scripts/check_inputs.R
Rscript scripts/render_figures.R --figure fig04 --out ../swine-figures
```

Use `--figure all` to render every panel. Available groups are `fig01`–`fig05` and `figS01`–`figS04`. PNG/PDF files are saved in the selected folder outside the repository.

## Find a figure's code and data

[Figure index](docs/figure_data_code_map.tsv) · [Data guide](docs/data_dictionary.md) · [Package versions](environment/package_versions.tsv)

```text
R/figures/fig01/ … fig05/     Main-figure scripts
R/figures/figS01/ … figS04/   Supplementary-figure scripts
data/fig01/ … fig05/         Main-figure inputs
data/figS01/ … figS04/       Supplementary-figure inputs
data/shared/                Tables used by multiple figures
R/common/                   Shared plotting helpers
scripts/                    Setup, input checks and rendering
environment/                R and package versions
analysis/networks/          Network analysis scripts and input guide
docs/                       Figure index and data definitions
```

Inputs are named by figure and panel, for example `Figure4A_breed_locations.tsv` and `Figure3ABC_network_edges.tsv.gz`. R reads the compressed tables directly.

The figure command uses the supplied result tables. Optional network analysis code has a separate [input guide](analysis/networks/README.md). Panel-specific display settings are described in [plotting notes](docs/reproduction_scope.md).
