# Source-table guide

All data inputs are gzip-compressed UTF-8 tab-separated tables. `NA` represents a missing value. Boolean columns use `TRUE`/`FALSE`; decimal numbers use a period. R can read these files directly with `readr::read_tsv()` without manual decompression. Table identifiers retain their manuscript working-source identifiers; they are not automatically the journal's final supplementary-table numbering.

The [column inventory](column_dictionary.tsv) lists every field and an example. The [data provenance](provenance.tsv) supplies row/column counts, sizes, original input hashes and published-file hashes. The [figure index](figure_data_code_map.tsv) links panels to the files they consume.

| Tables | Contents and units |
|---|---|
| T09 | Taxonomy dictionary used for genus-to-phylum mapping |
| T10 | Country sample counts and recorded regional labels; count units are samples |
| T11 | Saved sample-level Shannon index and plotting metadata; no count matrix |
| T12-T13 | Global composition, prevalence and core taxa; percent fields are explicitly named |
| T14, T35 | Saved taxon-discovery curves: sample count and discovered taxa |
| T15, T18 | Saved technical-factor effect sizes and mixed-model results |
| T22 | Saved sample PCoA coordinates and grouping metadata |
| T23, T41 | Integrated continent signatures and their actual mean abundance/prevalence (%) |
| T26 | Saved DBI null/permutation values, not newly generated permutations |
| T28-T29 | Adopted network summaries and edge statistics; mean degree = 2 × edges / nodes |
| T36 | Saved unidentified-taxa summaries by continent and taxonomic rank |
| T37 | Adopted enterotype PCoA coordinates, cluster labels and axis variance fractions; a sample may appear in more than one scope |
| T38 | Relative abundance for the adopted enterotype driver taxa |
| T39-T40 | Cumulative sequencing-strategy counts and samples per BioProject |
| T42 | Mean_Abund is mean relative abundance (%); one_vs_all_lfc_full is a signed ANCOM-BC2 effect size, not an abundance |
| T43 | Saved LEfSe marker scores, true mean abundance and row-centred log-abundance colour values |
| Continental/China network plot inputs | Displayed edge sets, phylum labels and true node abundance; exact selection rules are columns in the tables |
| Phylum plot inputs | Saved sample-level relative abundance and the selected hybrid-display sample order; abundance fractions are converted to percent where the script states |
| RF/DBI plot inputs | Saved performance summaries and country signature matrix |
| Figure 1B read-count input | Sample identifier and two scalar read counts; no sequence strings |
| Figure 4C comparison input | Three saved pairwise Wilcoxon comparisons, BH-adjusted P values and significance labels |

Sample-level diversity values, coordinates and selected abundance observations are necessary to reproduce distribution plots; they are processed results, not raw sequencing data. No field is replaced by a different statistic simply to approximate its visual appearance.
