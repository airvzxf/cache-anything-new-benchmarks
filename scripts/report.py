#!/usr/bin/env python3
"""Aggregates Benchmark runs into a Markdown report.

Usage:
    scripts/report.py RUN_ID [RUN_ID ...] > RESULTS.md

Needs the GitHub CLI (gh), authenticated. For every run it downloads the result artifacts
and reads the job durations from the API, then prints the median of each measurement.
"""

import json
import statistics
import subprocess
import sys
import tempfile
from collections import defaultdict
from datetime import datetime
from pathlib import Path

REPO = "airvzxf/cache-anything-new-benchmarks"
SCENARIOS = ["small", "cpp-boost", "latex", "python-gdal", "rust-sys", "cuda", "debian-cpp"]
ROWS = [
    ("baseline", "install", "No cache"),
    ("can", "miss", "cache-anything-new: miss"),
    ("can", "hit", "cache-anything-new: hit"),
    ("apt", "miss", "cache-apt-pkgs: miss"),
    ("apt", "hit", "cache-apt-pkgs: hit"),
    ("apt-scripts", "miss", "cache-apt-pkgs + scripts: miss"),
    ("apt-scripts", "hit", "cache-apt-pkgs + scripts: hit"),
]


def gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout


def job_durations(run_id: str) -> dict[str, float]:
    """Maps "scenario · variant · phase" to the job's wall time in seconds."""
    durations = {}
    jobs = json.loads(gh("api", "--paginate", "--slurp",
                         f"repos/{REPO}/actions/runs/{run_id}/jobs?per_page=100"))
    for page in jobs:
        for job in page["jobs"]:
            if not job.get("completed_at") or not job.get("started_at"):
                continue
            name = job["name"].removesuffix(" / measure")
            start = datetime.fromisoformat(job["started_at"].replace("Z", "+00:00"))
            end = datetime.fromisoformat(job["completed_at"].replace("Z", "+00:00"))
            durations[name] = (end - start).total_seconds()
    return durations


def load(run_ids: list[str]) -> list[dict]:
    results = []
    for run_id in run_ids:
        durations = job_durations(run_id)
        with tempfile.TemporaryDirectory() as tmp:
            gh("run", "download", run_id, "--repo", REPO, "--dir", tmp)
            for path in Path(tmp).glob("*/result.json"):
                result = json.loads(path.read_text())
                name = f"{result['scenario']} · {result['variant']} · {result['phase']}"
                result["job_s"] = durations.get(name)
                results.append(result)
    return results


def median(values: list[float]) -> str:
    return f"{statistics.median(values):.0f}" if values else "–"


def table(results: list[dict], scenario: str) -> list[str]:
    lines = [
        "| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for variant, phase, label in ROWS:
        rows = [r for r in results
                if r["scenario"] == scenario and r["variant"] == variant and r["phase"] == phase]
        if not rows:
            continue
        # A hit only counts when the cache was really restored. A miss in the hit phase means
        # the runner got a different image build, which correctly changes the key.
        valid = [r for r in rows if phase != "hit" or r["cache_hit"] == "true"]
        ok = sum(r["build"] == "success" for r in valid)
        restored = "–" if phase != "hit" else f"{len(valid)}/{len(rows)}"
        sizes = sorted({r["size"] for r in valid if r["size"]})
        lines.append(
            f"| {label} | {median([r['setup_s'] for r in valid])} "
            f"| {median([r['download_s'] for r in valid if r.get('download_s') is not None])} "
            f"| {median([r['build_s'] for r in valid])} "
            f"| {median([r['job_s'] for r in valid if r['job_s'] is not None])} "
            f"| {ok}/{len(valid)} | {restored} | {', '.join(sizes) or '–'} |"
        )
    return lines


def main() -> None:
    run_ids = sys.argv[1:]
    if not run_ids:
        sys.exit(__doc__)
    results = load(run_ids)
    images = sorted({r["image"] for r in results})
    print(f"Runs: {', '.join(run_ids)} ({len(run_ids)} repetitions)  ")
    print(f"Runner images: {', '.join(images)}\n")
    print("Median of all repetitions. *Setup* is the time from before the install (or the")
    print("restore) to after it; *Job* is the whole job, including saving the cache in post")
    print("steps. *apt download* is the part of the setup spent downloading packages, which")
    print("depends on the Ubuntu mirror. Hits only count when the cache was restored.\n")
    for scenario in SCENARIOS:
        if any(r["scenario"] == scenario for r in results):
            print(f"### {scenario}\n")
            print("\n".join(table(results, scenario)))
            print()
    by_key = defaultdict(int)
    for r in results:
        if r["build"] != "success":
            by_key[(r["scenario"], r["variant"], r["phase"])] += 1
    if by_key:
        print("### Failed builds\n")
        for (scenario, variant, phase), count in sorted(by_key.items()):
            print(f"- {scenario} · {variant} · {phase}: {count}")


if __name__ == "__main__":
    main()
