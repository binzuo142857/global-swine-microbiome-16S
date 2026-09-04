# Adopted China breed network analysis code

These two scripts document the computations that generated the adopted China breed network results. They are separate from the figure-rendering workflow and were not executed during packaging. Only the original machine-specific root/output paths were replaced with explicit environment variables; see `docs/analysis_script_provenance.tsv`.

`run_china_breed_fastspar_zero_filtered.py` removes zero-total sample columns from the frozen selected-taxon inputs, then runs the six Include/Exclude FastSpar jobs. The original script declares FastSpar 1.0.0 and uses 1,000 bootstraps, 1,000 permutations and seed 1. It is intended for the original Linux/POSIX analysis environment with `fastspar`, `fastspar_bootstrap` and `fastspar_pvalues` on PATH. It uses Python standard-library modules. The individual saved run records had an empty FastSpar version string, so the declared version is not a fresh binary-version verification.

`compare_china_breed_fastspar.py` compares frozen and corrected correlations and extracts focal-specific displayed networks. It requires NumPy, pandas and openpyxl; their original server versions were not recovered as a validated environment lock in this release. Focal edges meet empirical P <= 0.001; the comparison criterion is P_ex > 0.001 OR |r_ex| < 0.15; displayed focal edges also satisfy |r_in| > 0.20.

## Additional inputs

These scripts require the archived analysis inputs below. They are **not** needed for plotting and are not included in the repository:

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

The scripts are provided for methodological traceability and optional analysis reproduction when the original inputs and environment are available. The normal figure command uses the published edge/node tables directly and never starts these jobs.
