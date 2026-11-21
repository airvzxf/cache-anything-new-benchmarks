#!/usr/bin/env bash
# Runs a benchmark round: dispatches the Benchmark workflow once per repetition, one run at a
# time, and then writes the report of the successful runs.
#
# Usage:
#     scripts/round.sh [-n REPETITIONS] [-s SCENARIO,...] [-r REF] [-o REPORT]
#
#   -n  successful runs to collect (default 5)
#   -s  comma-separated scenarios (default all)
#   -r  branch to run on (default main)
#   -o  report file (default report.md)
#
# Runs are dispatched one at a time because the workflow's concurrency group keeps only one
# pending run and cancels the others. A failed run is reported and replaced, up to 2 times.
# Needs the GitHub CLI (gh), authenticated, and jq.
set -euo pipefail

REPO=airvzxf/cache-anything-new-benchmarks
repetitions=5
scenarios=''
ref=main
report=report.md
while getopts 'n:s:r:o:' option; do
  case "${option}" in
    n) repetitions="${OPTARG}" ;;
    s) scenarios="${OPTARG}" ;;
    r) ref="${OPTARG}" ;;
    o) report="${OPTARG}" ;;
    *) sed -n '2,14p' "$0" >&2; exit 2 ;;
  esac
done

inputs=()
if [ -n "${scenarios}" ]; then
  inputs=(-f "scenarios=$(jq -cn --arg s "${scenarios}" '$s | split(",")')")
fi

# The id of the first workflow_dispatch run on REF created at or after a time.
run_since() {
  gh run list -R "${REPO}" --workflow benchmark.yml --branch "${ref}" --event workflow_dispatch \
    --limit 20 --json databaseId,createdAt \
    --jq "[.[] | select(.createdAt >= \"$1\")] | sort_by(.createdAt) | .[0].databaseId // empty"
}

successful=()
failures=0
while [ "${#successful[@]}" -lt "${repetitions}" ]; do
  since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  gh workflow run benchmark.yml -R "${REPO}" --ref "${ref}" "${inputs[@]}"
  run=''
  for _ in $(seq 30); do
    sleep 5
    run="$(run_since "${since}")"
    [ -z "${run}" ] || break
  done
  [ -n "${run}" ] || { echo "The dispatched run did not appear." >&2; exit 1; }
  echo "Run $((${#successful[@]} + 1))/${repetitions}: https://github.com/${REPO}/actions/runs/${run}" >&2

  if gh run watch "${run}" -R "${REPO}" --exit-status --interval 30 > /dev/null; then
    successful+=("${run}")
  else
    failures=$((failures + 1))
    echo "Run ${run} failed (${failures})." >&2
    if [ "${failures}" -gt 2 ]; then
      echo "Too many failed runs; fix the benchmark first." >&2
      exit 1
    fi
  fi
done

echo "Runs: ${successful[*]}" >&2
filter=()
[ -z "${scenarios}" ] || filter=(--scenarios "${scenarios}")
python3 "$(dirname "$0")/report.py" "${filter[@]}" "${successful[@]}" > "${report}"
echo "Report: ${report}" >&2
