#!/usr/bin/env python3
"""Compare frozen and zero-column-filtered China breed FastSpar results."""
from __future__ import annotations

import json
import os
from pathlib import Path

import numpy as np
import pandas as pd

# Analysis inputs are supplied separately; these scripts are not called by the figure runner.
def required_directory(variable: str) -> Path:
    value = os.environ.get(variable)
    if not value:
        raise RuntimeError(f"Set {variable}; see analysis/networks/README.md")
    return Path(value).expanduser().resolve()

ROOT = required_directory("SWINE_ANALYSIS_ROOT")
BASE = required_directory("SWINE_ANALYSIS_OUTPUT_DIR")
if ROOT == BASE:
    raise RuntimeError("Use a separate analysis-output directory")

PHASE = BASE / "phase2_fastspar"
PUBLIC = BASE / "publication_tables"
OLD_BASE = ROOT / "R_analysis_output" / "China_Breed_Networks"
PUBLIC.mkdir(parents=True, exist_ok=True)

SIG_P = 0.001
EXCLUDE_R = 0.15
DISPLAY_R = 0.20

GROUPS = [
    ("Commercial", "commercial"),
    ("Crossbred", "crossbred"),
    ("Indigenous", "LocalChina"),
]


def write_one_sheet(df: pd.DataFrame, path: Path) -> None:
    with pd.ExcelWriter(path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="data", index=False)
        ws = writer.book["data"]
        ws.freeze_panes = "A2"
        ws.auto_filter.ref = ws.dimensions


def edge_id(a: object, b: object) -> str:
    return "--".join(sorted((str(a), str(b))))


def read_matrix(path: Path) -> pd.DataFrame:
    x = pd.read_csv(path, sep="\t", index_col=0)
    x.index = x.index.astype(str)
    x.columns = x.columns.astype(str)
    x = x.apply(pd.to_numeric, errors="raise")
    if x.shape[0] != x.shape[1]:
        raise ValueError(f"Non-square matrix: {path}: {x.shape}")
    if list(x.index) != list(x.columns):
        raise ValueError(f"Row/column labels differ: {path}")
    if not np.isfinite(x.to_numpy()).all():
        raise ValueError(f"Non-finite values: {path}")
    return x


def matrix_edges(run_dir: Path) -> pd.DataFrame:
    cor = read_matrix(run_dir / "correlation.tsv")
    pval = read_matrix(run_dir / "pvalues.tsv")
    if list(cor.index) != list(pval.index):
        raise ValueError(f"Correlation/P labels differ: {run_dir}")
    i, j = np.tril_indices(len(cor), k=-1)
    taxa = np.asarray(cor.index)
    out = pd.DataFrame(
        {
            "taxon_1": taxa[i],
            "taxon_2": taxa[j],
            "correlation": cor.to_numpy()[i, j],
            "empirical_P": pval.to_numpy()[i, j],
        }
    )
    out["canonical_edge_id"] = [
        edge_id(a, b) for a, b in zip(out["taxon_1"], out["taxon_2"])
    ]
    if not out["canonical_edge_id"].is_unique:
        raise ValueError(f"Duplicate canonical matrix edges: {run_dir}")
    return out


def specific_edges(include_dir: Path, exclude_dir: Path) -> pd.DataFrame:
    inc = matrix_edges(include_dir).rename(
        columns={"correlation": "r_in", "empirical_P": "p_in"}
    )
    exc = matrix_edges(exclude_dir)[
        ["canonical_edge_id", "correlation", "empirical_P"]
    ].rename(columns={"correlation": "r_ex", "empirical_P": "p_ex"})
    merged = inc.merge(exc, on="canonical_edge_id", how="left", validate="one_to_one")
    merged["r_ex"] = merged["r_ex"].fillna(0.0)
    merged["p_ex"] = merged["p_ex"].fillna(1.0)
    merged["specific_pre_display"] = (merged["p_in"] <= SIG_P) & (
        (merged["p_ex"] > SIG_P) | (merged["r_ex"].abs() < EXCLUDE_R)
    )
    merged["displayed"] = merged["specific_pre_display"] & (
        merged["r_in"].abs() > DISPLAY_R
    )
    merged["sign"] = np.where(merged["r_in"] > 0, "Positive", "Negative")
    return merged


def graph_metrics(displayed: pd.DataFrame) -> dict[str, object]:
    nodes = sorted(set(displayed["taxon_1"]).union(displayed["taxon_2"]))
    pos = int((displayed["r_in"] > 0).sum())
    neg = int((displayed["r_in"] < 0).sum())
    return {
        "displayed_edges": len(displayed),
        "network_nodes": len(nodes),
        "mean_degree": 2 * len(displayed) / len(nodes) if nodes else np.nan,
        "positive_edges": pos,
        "negative_edges": neg,
        "positive_to_negative_edge_count_ratio": pos / neg if neg else np.nan,
    }


def node_table(
    group: str, displayed: pd.DataFrame, corrected_input: Path
) -> pd.DataFrame:
    # Historical header has two leading fields; data rows have taxon + values.
    with corrected_input.open("rt", encoding="utf-8") as fh:
        header = fh.readline().rstrip("\n").split("\t")
    sample_ids = header[2:]
    counts = pd.read_csv(
        corrected_input,
        sep="\t",
        skiprows=1,
        header=None,
        index_col=0,
    )
    counts.columns = sample_ids
    abundance = counts.mean(axis=1)
    rel = abundance / abundance.sum()
    incident = pd.concat(
        [
            displayed[["taxon_1", "r_in", "sign"]].rename(
                columns={"taxon_1": "taxon"}
            ),
            displayed[["taxon_2", "r_in", "sign"]].rename(
                columns={"taxon_2": "taxon"}
            ),
        ],
        ignore_index=True,
    )
    metrics = (
        incident.groupby("taxon")
        .agg(
            total_degree=("taxon", "size"),
            positive_degree=("sign", lambda x: int((x == "Positive").sum())),
            negative_degree=("sign", lambda x: int((x == "Negative").sum())),
            mean_abs_correlation=("r_in", lambda x: float(np.abs(x).mean())),
            min_abs_correlation=("r_in", lambda x: float(np.abs(x).min())),
            max_abs_correlation=("r_in", lambda x: float(np.abs(x).max())),
        )
        .reset_index()
    )
    out = metrics.copy()
    out.insert(0, "breed_group", group)
    out["raw_mean_count_after_zero_column_removal"] = out["taxon"].map(abundance)
    out["relative_abundance_for_node_size"] = out["taxon"].map(rel)
    out["relative_abundance_denominator"] = (
        "sum of taxon mean counts across corrected nonzero sample columns"
    )
    out["incident_displayed_edges"] = out["total_degree"]
    out["taxon_filter"] = "mean relative abundance >0.0005 and prevalence >0.20"
    out["significance_threshold"] = "empirical P <= 0.001"
    out["specificity_rule"] = "p_ex > 0.001 OR abs(r_ex) < 0.15"
    out["display_threshold"] = "abs(r_in) > 0.20"
    if not (
        out["total_degree"] == out["positive_degree"] + out["negative_degree"]
    ).all():
        raise AssertionError(f"Degree sign identity failed: {group}")
    if int(out["total_degree"].sum()) != 2 * len(displayed):
        raise AssertionError(f"Handshake identity failed: {group}")
    return out


summary_rows: list[dict[str, object]] = []
matrix_rows: list[dict[str, object]] = []
edge_comparisons: list[pd.DataFrame] = []
corrected_edges_public: list[pd.DataFrame] = []
corrected_nodes_public: list[pd.DataFrame] = []

for group, stub in GROUPS:
    old_inc_dir = OLD_BASE / f"Network_China_Breed_{stub}_Include"
    old_exc_dir = OLD_BASE / f"Network_China_Breed_{stub}_Exclude"
    new_inc_dir = PHASE / f"{group}_Include"
    new_exc_dir = PHASE / f"{group}_Exclude"
    if not (new_inc_dir / "pvalues.tsv").exists():
        raise FileNotFoundError(f"Incomplete sensitivity run: {new_inc_dir}")
    if not (new_exc_dir / "pvalues.tsv").exists():
        raise FileNotFoundError(f"Incomplete sensitivity run: {new_exc_dir}")

    old_spec = specific_edges(old_inc_dir, old_exc_dir)
    new_spec = specific_edges(new_inc_dir, new_exc_dir)
    old_display = old_spec[old_spec["displayed"]].copy()
    new_display = new_spec[new_spec["displayed"]].copy()
    old_metrics = graph_metrics(old_display)
    new_metrics = graph_metrics(new_display)
    saved_plot_file = (
        ROOT
        / "R_analysis_output"
        / "China_Breed_Networks_Plots"
        / f"Edges_ChinaSpec_{stub}.csv"
    )
    saved_plot = pd.read_csv(saved_plot_file)
    saved_plot_display = saved_plot[saved_plot["r_In"].abs() > DISPLAY_R].copy()
    old_raw_nodes = len(
        set(saved_plot_display["from"].astype(str)).union(
            saved_plot_display["to"].astype(str)
        )
    )
    if len(saved_plot_display) != old_metrics["displayed_edges"]:
        raise AssertionError(f"Saved/current edge count differs for {group}")

    old_corr = matrix_edges(old_inc_dir)[
        ["canonical_edge_id", "correlation"]
    ].rename(columns={"correlation": "old_correlation"})
    new_corr = matrix_edges(new_inc_dir)[
        ["canonical_edge_id", "correlation"]
    ].rename(columns={"correlation": "new_correlation"})
    common_corr = old_corr.merge(
        new_corr, on="canonical_edge_id", how="inner", validate="one_to_one"
    )
    matrix_rows.append(
        {
            "breed_group": group,
            "common_matrix_entries": len(common_corr),
            "pearson_correlation_old_vs_corrected": common_corr[
                ["old_correlation", "new_correlation"]
            ].corr(method="pearson").iloc[0, 1],
            "spearman_correlation_old_vs_corrected": common_corr[
                ["old_correlation", "new_correlation"]
            ].corr(method="spearman").iloc[0, 1],
            "mean_absolute_correlation_change": (
                common_corr["new_correlation"] - common_corr["old_correlation"]
            ).abs().mean(),
            "max_absolute_correlation_change": (
                common_corr["new_correlation"] - common_corr["old_correlation"]
            ).abs().max(),
        }
    )

    old_e = old_display[
        ["canonical_edge_id", "taxon_1", "taxon_2", "r_in", "p_in", "sign"]
    ].rename(
        columns={
            "taxon_1": "old_taxon_1",
            "taxon_2": "old_taxon_2",
            "r_in": "old_correlation",
            "p_in": "old_empirical_P",
            "sign": "old_sign",
        }
    )
    new_e = new_display[
        ["canonical_edge_id", "taxon_1", "taxon_2", "r_in", "p_in", "sign"]
    ].rename(
        columns={
            "taxon_1": "new_taxon_1",
            "taxon_2": "new_taxon_2",
            "r_in": "new_correlation",
            "p_in": "new_empirical_P",
            "sign": "new_sign",
        }
    )
    comp = old_e.merge(new_e, on="canonical_edge_id", how="outer")
    comp.insert(0, "breed_group", group)
    comp["comparison_status"] = np.select(
        [
            comp["old_sign"].notna() & comp["new_sign"].isna(),
            comp["old_sign"].isna() & comp["new_sign"].notna(),
            comp["old_sign"].eq(comp["new_sign"]),
            comp["old_sign"].notna() & comp["new_sign"].notna(),
        ],
        [
            "old_only",
            "new_only",
            "shared_same_sign",
            "shared_sign_changed",
        ],
        default="ERROR",
    )
    edge_comparisons.append(comp)
    status_counts = comp["comparison_status"].value_counts()
    shared = int(
        status_counts.get("shared_same_sign", 0)
        + status_counts.get("shared_sign_changed", 0)
    )
    union = len(comp)

    inc_prov = json.loads((new_inc_dir / "run_provenance.json").read_text())
    exc_prov = json.loads((new_exc_dir / "run_provenance.json").read_text())
    summary_rows.append(
        {
            "breed_group": group,
            "source_label": stub,
            "current_T28_sample_number_including_blank_header_placeholder": (
                inc_prov["old_real_sample_columns"] + 1
            ),
            "old_include_samples": inc_prov["old_real_sample_columns"],
            "corrected_include_samples": inc_prov["corrected_sample_columns"],
            "removed_include_zero_columns": inc_prov[
                "removed_zero_total_columns"
            ],
            "old_exclude_samples": exc_prov["old_real_sample_columns"],
            "corrected_exclude_samples": exc_prov["corrected_sample_columns"],
            "removed_exclude_zero_columns": exc_prov[
                "removed_zero_total_columns"
            ],
            "retained_taxa_include": inc_prov["taxa"],
            "old_specific_edges_pre_display": int(
                old_spec["specific_pre_display"].sum()
            ),
            "corrected_specific_edges_pre_display": int(
                new_spec["specific_pre_display"].sum()
            ),
            "old_displayed_edges": old_metrics["displayed_edges"],
            "corrected_displayed_edges": new_metrics["displayed_edges"],
            "common_displayed_edges": shared,
            "lost_displayed_edges": int(status_counts.get("old_only", 0)),
            "gained_displayed_edges": int(status_counts.get("new_only", 0)),
            "displayed_edge_jaccard": shared / union if union else np.nan,
            "shared_sign_changes": int(
                status_counts.get("shared_sign_changed", 0)
            ),
            "old_nodes": old_raw_nodes,
            "old_nodes_canonical": old_metrics["network_nodes"],
            "corrected_nodes": new_metrics["network_nodes"],
            "old_mean_degree": (
                2 * len(saved_plot_display) / old_raw_nodes
                if old_raw_nodes
                else np.nan
            ),
            "old_mean_degree_canonical": old_metrics["mean_degree"],
            "corrected_mean_degree": new_metrics["mean_degree"],
            "old_positive_edges": old_metrics["positive_edges"],
            "corrected_positive_edges": new_metrics["positive_edges"],
            "old_negative_edges": old_metrics["negative_edges"],
            "corrected_negative_edges": new_metrics["negative_edges"],
            "old_positive_negative_ratio": old_metrics[
                "positive_to_negative_edge_count_ratio"
            ],
            "corrected_positive_negative_ratio": new_metrics[
                "positive_to_negative_edge_count_ratio"
            ],
            "significance_threshold": "empirical P <= 0.001",
            "specificity_rule": "p_ex > 0.001 OR abs(r_ex) < 0.15",
            "display_threshold": "abs(r_in) > 0.20",
        }
    )

    pub_e = new_display[
        [
            "taxon_1",
            "taxon_2",
            "r_in",
            "p_in",
            "sign",
        ]
    ].copy()
    pub_e.insert(0, "breed_group", group)
    pub_e = pub_e.rename(
        columns={"r_in": "correlation", "p_in": "empirical_P"}
    )
    pub_e["significance_threshold"] = "empirical P <= 0.001"
    pub_e["specificity_rule"] = "p_ex > 0.001 OR abs(r_ex) < 0.15"
    pub_e["display_threshold"] = "abs(r_in) > 0.20"
    corrected_edges_public.append(pub_e)
    corrected_nodes_public.append(
        node_table(
            group,
            new_display,
            new_inc_dir / "input_counts_zero_columns_removed.tsv",
        )
    )

summary = pd.DataFrame(summary_rows)
matrix_summary = pd.DataFrame(matrix_rows)
edge_comparison = pd.concat(edge_comparisons, ignore_index=True)
corrected_edge_table = pd.concat(corrected_edges_public, ignore_index=True)
corrected_node_table = pd.concat(corrected_nodes_public, ignore_index=True)

old_order = summary.sort_values(
    ["old_displayed_edges", "old_nodes", "old_mean_degree"], ascending=False
)["breed_group"].tolist()
new_order = summary.sort_values(
    ["corrected_displayed_edges", "corrected_nodes", "corrected_mean_degree"],
    ascending=False,
)["breed_group"].tolist()
summary["old_network_complexity_order"] = " > ".join(old_order)
summary["corrected_network_complexity_order"] = " > ".join(new_order)
summary["qualitative_complexity_order_changed"] = old_order != new_order

write_one_sheet(
    summary,
    PUBLIC / "china_breed_fastspar_sensitivity_summary.xlsx",
)
write_one_sheet(
    matrix_summary,
    PHASE / "correlation_matrix_comparison_internal.xlsx",
)
write_one_sheet(
    edge_comparison,
    PUBLIC / "china_breed_displayed_edge_comparison.xlsx",
)
write_one_sheet(
    corrected_edge_table,
    PUBLIC / "china_breed_corrected_displayed_edges.xlsx",
)
write_one_sheet(
    corrected_node_table,
    PUBLIC / "china_breed_corrected_displayed_nodes.xlsx",
)
print(summary.to_string(index=False))
print(matrix_summary.to_string(index=False))
