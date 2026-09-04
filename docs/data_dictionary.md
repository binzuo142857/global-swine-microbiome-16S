# Data guide

Inputs are grouped by figure. Filenames identify the panels that use them; `data/shared/` holds tables used by more than one figure. Tables are UTF-8 TSV, usually gzip-compressed; `readr::read_tsv()` reads both forms directly. `NA` denotes a missing value.

[Figure index](figure_data_code_map.tsv) links each script to its inputs. [Column dictionary](column_dictionary.tsv) lists fields and example values. [File manifest](provenance.tsv) records dimensions, sizes and SHA-256 checksums.

| Folder | Contents |
|---|---|
| `fig01` | Sample counts, read counts, taxonomic composition, prevalence, core taxa and accumulation curves |
| `fig02` | Continental taxon signatures and abundance/prevalence summaries |
| `fig03` | Continental network edges/nodes/metrics, taxon discovery and unidentified taxa |
| `fig04` | Breed map, diversity comparisons, China network edges/nodes and ANCOM-BC2 effects |
| `fig05` | Enterotype coordinates, axis variance and driver abundance |
| `figS01` | Sequencing-strategy summaries, project sizes and technical effects |
| `figS02` | DBI permutations, RF AUC and country signatures |
| `figS03` | Phylum abundance distributions and sample composition |
| `figS04` | LEfSe scores and abundance |
| `shared` | Taxonomy, sample diversity/metadata, community PCoA and network statistics |

Figure 4A includes 23 breed labels, plotting coordinates and sample counts. `Figure4A_map.geojson` is the original map geometry, attributed to Alibaba DataV.GeoAtlas. Coordinates are the locations used in the original figure, including small display adjustments for nearby labels.

Network edge tables contain correlations and significance values; node tables supply abundance and phylum labels. Mean degree is 2 × edges / nodes. In Figure 4G, `Mean_Abund` is mean relative abundance (%) and `one_vs_all_lfc_full` is the signed ANCOM-BC2 effect size. Figure S4B supplies LDA scores, mean abundance and row-centred log-abundance colours. Enterotype coordinates and axis-variance tables use `scope` to distinguish global and stage-specific partitions.
