#!/usr/bin/env python3
"""Zero-total-column FastSpar sensitivity rerun from frozen old inputs.

This script never writes into the old China_Breed_Networks directories. It
parses the historical write.table + sed header exactly, removes only real
sample columns whose post-filter sum is zero, and reruns the frozen FastSpar
1.0.0 settings with explicit default seeds.
"""
from __future__ import annotations

import concurrent.futures
import csv
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

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

OUT = BASE / "phase2_fastspar"
LOG_DIR = BASE / "internal_logs"
OLD_BASE = ROOT / "R_analysis_output" / "China_Breed_Networks"

N_THREADS = 40
N_BOOTSTRAPS = 1000
FASTSPAR_SEED = 1
BOOTSTRAP_SEED = 1

RUNS = [
    ("Commercial", "commercial", "Include"),
    ("Commercial", "commercial", "Exclude"),
    ("Crossbred", "crossbred", "Include"),
    ("Crossbred", "crossbred", "Exclude"),
    ("Indigenous", "LocalChina", "Include"),
    ("Indigenous", "LocalChina", "Exclude"),
]


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def parse_frozen_input(path: Path) -> tuple[list[str], list[str], list[list[int]]]:
    with path.open("rt", encoding="utf-8", newline="") as fh:
        reader = csv.reader(fh, delimiter="\t")
        header = next(reader)
        if len(header) < 3 or header[0] != "#OTU ID" or header[1] != "":
            raise ValueError(f"Unexpected historical header layout: {path}")
        sample_ids = header[2:]
        taxa: list[str] = []
        matrix: list[list[int]] = []
        for line_no, fields in enumerate(reader, start=2):
            if len(fields) != len(sample_ids) + 1:
                raise ValueError(
                    f"{path}:{line_no}: {len(fields)} fields for "
                    f"{len(sample_ids)} samples"
                )
            taxa.append(fields[0])
            matrix.append([int(float(v)) for v in fields[1:]])
    if len(set(sample_ids)) != len(sample_ids):
        raise ValueError(f"Duplicate real sample IDs in {path}")
    if len(set(taxa)) != len(taxa):
        raise ValueError(f"Duplicate aggregated taxon labels in {path}")
    return sample_ids, taxa, matrix


def write_corrected_input(
    path: Path,
    sample_ids: list[str],
    taxa: list[str],
    matrix: list[list[int]],
    keep_indices: list[int],
) -> None:
    with path.open("wt", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        # Preserve the historical parser-compatible blank header field.
        writer.writerow(["#OTU ID", "", *[sample_ids[i] for i in keep_indices]])
        for taxon, row in zip(taxa, matrix):
            writer.writerow([taxon, *[row[i] for i in keep_indices]])


def run_logged(command: list[str], log_fh, cwd: Path | None = None) -> float:
    started = time.monotonic()
    log_fh.write(f"[{now()}] COMMAND: {json.dumps(command)}\n")
    log_fh.flush()
    proc = subprocess.run(
        command,
        cwd=str(cwd or ROOT),
        stdout=log_fh,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    elapsed = time.monotonic() - started
    log_fh.write(
        f"[{now()}] EXIT={proc.returncode} DURATION_SECONDS={elapsed:.3f}\n"
    )
    log_fh.flush()
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed ({proc.returncode}): {command}")
    return elapsed


def correlate_one(boot_file: Path, boot_cor_dir: Path) -> dict[str, object]:
    stem = boot_file.stem
    cor = boot_cor_dir / f"cor_{stem}.tsv"
    cov = boot_cor_dir / f"cov_{stem}.tsv"
    if cor.exists() and cov.exists() and cor.stat().st_size > 0 and cov.stat().st_size > 0:
        return {"file": boot_file.name, "status": "existing", "seconds": 0.0}
    cmd = [
        "fastspar",
        "--otu_table",
        str(boot_file),
        "--correlation",
        str(cor),
        "--covariance",
        str(cov),
        "--threads",
        "1",
        "--seed",
        str(FASTSPAR_SEED),
    ]
    start = time.monotonic()
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    elapsed = time.monotonic() - start
    if proc.returncode != 0:
        return {
            "file": boot_file.name,
            "status": "failed",
            "seconds": elapsed,
            "command": cmd,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
        }
    return {"file": boot_file.name, "status": "completed", "seconds": elapsed}


def run_one(manuscript_group: str, source_stub: str, mode: str) -> dict[str, object]:
    old_dir = OLD_BASE / f"Network_China_Breed_{source_stub}_{mode}"
    old_input = old_dir / "input_counts.tsv"
    run_name = f"{manuscript_group}_{mode}"
    run_dir = OUT / run_name
    run_dir.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / f"phase2_{run_name}.log"
    existing_prov = run_dir / "run_provenance.json"
    existing_pval = run_dir / "pvalues.tsv"
    existing_cors = list((run_dir / "bootstrap_correlations").glob("cor_boot_*.tsv"))
    if (
        existing_prov.exists()
        and existing_pval.exists()
        and len(existing_cors) == N_BOOTSTRAPS
        and (run_dir / "correlation.tsv").exists()
    ):
        with log_path.open("at", encoding="utf-8") as log:
            log.write(
                f"\n[{now()}] SKIP entire run {run_name}: provenance and "
                f"{N_BOOTSTRAPS} bootstrap correlations already present\n"
            )
        return json.loads(existing_prov.read_text(encoding="utf-8"))

    sample_ids, taxa, matrix = parse_frozen_input(old_input)
    sums = [sum(row[j] for row in matrix) for j in range(len(sample_ids))]
    zero_indices = [j for j, value in enumerate(sums) if value == 0]
    keep_indices = [j for j, value in enumerate(sums) if value > 0]
    if not keep_indices:
        raise RuntimeError(f"No nonzero columns remain for {run_name}")

    corrected_input = run_dir / "input_counts_zero_columns_removed.tsv"
    write_corrected_input(corrected_input, sample_ids, taxa, matrix, keep_indices)
    with (run_dir / "removed_zero_total_samples.tsv").open(
        "wt", encoding="utf-8", newline=""
    ) as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(
            [
                "manuscript_group",
                "source_label",
                "mode",
                "sample_id",
                "post_filter_sum",
            ]
        )
        for j in zero_indices:
            writer.writerow(
                [manuscript_group, source_stub, mode, sample_ids[j], sums[j]]
            )

    cor = run_dir / "correlation.tsv"
    cov = run_dir / "covariance.tsv"
    pval = run_dir / "pvalues.tsv"
    boot_dir = run_dir / "bootstrap_counts"
    boot_cor_dir = run_dir / "bootstrap_correlations"
    boot_dir.mkdir(exist_ok=True)
    boot_cor_dir.mkdir(exist_ok=True)
    stage_durations: dict[str, float] = {}

    with log_path.open("at", encoding="utf-8") as log:
        log.write(
            f"\n[{now()}] START {run_name}; old_input={old_input}; "
            f"old_samples={len(sample_ids)}; removed_zero={len(zero_indices)}; "
            f"corrected_samples={len(keep_indices)}; taxa={len(taxa)}\n"
        )
        if not cor.exists() or not cov.exists():
            stage_durations["main"] = run_logged(
                [
                    "fastspar",
                    "--otu_table",
                    str(corrected_input),
                    "--correlation",
                    str(cor),
                    "--covariance",
                    str(cov),
                    "--threads",
                    str(N_THREADS),
                    "--seed",
                    str(FASTSPAR_SEED),
                ],
                log,
            )
        else:
            log.write(f"[{now()}] SKIP main: outputs already present\n")

        boot_files = sorted(boot_dir.glob("boot_*.tsv"))
        if len(boot_files) != N_BOOTSTRAPS:
            for old in boot_dir.glob("boot_*.tsv"):
                old.unlink()
            stage_durations["bootstrap_generation"] = run_logged(
                [
                    "fastspar_bootstrap",
                    "--otu_table",
                    str(corrected_input),
                    "--number",
                    str(N_BOOTSTRAPS),
                    "--prefix",
                    str(boot_dir / "boot"),
                    "--threads",
                    "1",
                    "--seed",
                    str(BOOTSTRAP_SEED),
                ],
                log,
            )
            boot_files = sorted(boot_dir.glob("boot_*.tsv"))
        if len(boot_files) != N_BOOTSTRAPS:
            raise RuntimeError(
                f"{run_name}: expected {N_BOOTSTRAPS} bootstraps, got {len(boot_files)}"
            )

        start = time.monotonic()
        with concurrent.futures.ThreadPoolExecutor(max_workers=N_THREADS) as pool:
            boot_results = list(pool.map(lambda p: correlate_one(p, boot_cor_dir), boot_files))
        stage_durations["bootstrap_correlations"] = time.monotonic() - start
        failures = [r for r in boot_results if r["status"] == "failed"]
        (run_dir / "bootstrap_correlation_run_summary.json").write_text(
            json.dumps(boot_results, indent=2), encoding="utf-8"
        )
        log.write(
            f"[{now()}] bootstrap correlations completed; "
            f"files={len(boot_results)} failures={len(failures)} "
            f"duration_seconds={stage_durations['bootstrap_correlations']:.3f}\n"
        )
        if failures:
            raise RuntimeError(f"{run_name}: {len(failures)} bootstrap failures")

        cor_boot_files = list(boot_cor_dir.glob("cor_boot_*.tsv"))
        if len(cor_boot_files) != N_BOOTSTRAPS:
            raise RuntimeError(
                f"{run_name}: expected {N_BOOTSTRAPS} bootstrap correlations, "
                f"got {len(cor_boot_files)}"
            )
        if not pval.exists():
            stage_durations["pvalues"] = run_logged(
                [
                    "fastspar_pvalues",
                    "--otu_table",
                    str(corrected_input),
                    "--correlation",
                    str(cor),
                    "--prefix",
                    str(boot_cor_dir / "cor_boot_"),
                    "--permutations",
                    str(N_BOOTSTRAPS),
                    "--outfile",
                    str(pval),
                ],
                log,
            )
        else:
            log.write(f"[{now()}] SKIP pvalues: output already present\n")
        log.write(f"[{now()}] COMPLETE {run_name}\n")

    provenance = {
        "manuscript_group": manuscript_group,
        "source_label": source_stub,
        "mode": mode,
        "old_input": str(old_input),
        "old_input_sha256": sha256(old_input),
        "corrected_input": str(corrected_input),
        "corrected_input_sha256": sha256(corrected_input),
        "taxa": len(taxa),
        "old_real_sample_columns": len(sample_ids),
        "removed_zero_total_columns": len(zero_indices),
        "corrected_sample_columns": len(keep_indices),
        "fastspar_version": subprocess.check_output(
            ["fastspar", "--version"], text=True
        ).strip(),
        "fastspar_threads": N_THREADS,
        "fastspar_seed": FASTSPAR_SEED,
        "bootstrap_count": N_BOOTSTRAPS,
        "bootstrap_threads": 1,
        "bootstrap_seed": BOOTSTRAP_SEED,
        "pvalue_permutations": N_BOOTSTRAPS,
        "stage_durations_seconds": stage_durations,
        "completed_at": now(),
    }
    (run_dir / "run_provenance.json").write_text(
        json.dumps(provenance, indent=2), encoding="utf-8"
    )
    return provenance


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    required = ["fastspar", "fastspar_bootstrap", "fastspar_pvalues"]
    missing = [name for name in required if shutil.which(name) is None]
    if missing:
        raise RuntimeError(f"Missing executables: {missing}")
    selected = RUNS
    if len(sys.argv) > 1:
        wanted = {arg.strip() for arg in sys.argv[1:]}
        selected = [
            spec
            for spec in RUNS
            if f"{spec[0]}_{spec[2]}" in wanted or f"{spec[1]}_{spec[2]}" in wanted
        ]
        if not selected:
            raise RuntimeError(f"No matching runs for argv={sys.argv[1:]}")
    overall_start = time.monotonic()
    results = []
    for spec in selected:
        results.append(run_one(*spec))
    report = {
        "started_and_completed_in_this_invocation": now(),
        "selected_runs": [f"{a}_{c}" for a, _, c in selected],
        "total_duration_seconds": time.monotonic() - overall_start,
        "python": sys.version,
        "platform": {
            "sysname": os.uname().sysname,
            "nodename": os.uname().nodename,
            "release": os.uname().release,
            "version": os.uname().version,
            "machine": os.uname().machine,
        },
        "runs": results,
    }
    (OUT / "all_runs_provenance.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
