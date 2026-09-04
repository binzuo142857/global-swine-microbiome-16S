# Network analysis and figures

Both network analyses use the same figure/data directory convention:

| Network | Figure script | Plotting inputs |
|---|---|---|
| Continental | `R/figures/fig03/panel_ABC_networks.R` | `data/fig03/Figure3ABC_network_edges.tsv.gz`, `Figure3ABC_network_nodes.tsv.gz` |
| China breed | `R/figures/fig04/panel_DEF_networks.R` | `data/fig04/Figure4DEF_network_edges.tsv.gz`, `Figure4DEF_network_nodes.tsv.gz` |

Run these through `scripts/render_figures.R --figure fig03` or `--figure fig04`. Summary metrics are in `data/fig03/Figure3F_network_metrics.tsv.gz` and `data/shared/network_summary_metrics.tsv.gz`.

## Optional FastSpar scripts

`run_china_breed_fastspar_zero_filtered.py` runs six China breed Include/Exclude networks after removing zero-total sample columns, with selected taxa fixed, seed 1, 1,000 bootstraps and 1,000 permutations. It requires Python and FastSpar in a Linux/POSIX environment. The source script specifies FastSpar 1.0.0.

`compare_china_breed_fastspar.py` compares network results and exports the displayed edges and node summaries. It requires NumPy, pandas and openpyxl. Focal edges meet empirical P ≤ 0.001 and |r| > 0.20; the comparison criterion is P_ex > 0.001 or |r_ex| < 0.15.

The archived upstream scripts available in this release cover the China analysis; continental plotting inputs are supplied directly. Neither analysis is launched by the figure command.

## Additional inputs

For the optional China FastSpar analysis, supply the following archived inputs:

```text
<SWINE_ANALYSIS_ROOT>/
  R_analysis_output/
    China_Breed_Networks/
      Network_China_Breed_<commercial|crossbred|LocalChina>_<Include|Exclude>/
        input_counts.tsv
        correlation.tsv
        pvalues.tsv
    China_Breed_Networks_Plots/
      Edges_ChinaSpec_<commercial|crossbred|LocalChina>.csv
```

Use a separate `SWINE_ANALYSIS_OUTPUT_DIR`. The runner writes its six jobs under that directory's `phase2_fastspar/`; the comparison script writes result workbooks under `publication_tables/`. The frozen input format includes a blank header field after `#OTU ID`, which the supplied parser checks explicitly.
