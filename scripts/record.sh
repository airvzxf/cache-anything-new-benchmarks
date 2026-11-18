#!/usr/bin/env bash
# Prints the result of one measure job as JSON. Plain bash, because container images may
# have no Python or jq.
set -euo pipefail

now="$(date +%s.%N)"
t0="$(cat "${RUNNER_TEMP}/t0")"
t1="$(cat "${RUNNER_TEMP}/t1" 2>/dev/null || echo "${now}")"

seconds() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", b - a }'; }

printf '{"scenario":"%s","variant":"%s","phase":"%s","cache_hit":"%s","size":"%s",' \
  "${SCENARIO_NAME}" "${VARIANT}" "${PHASE}" "${HIT:-}" "${SIZE:-}"
printf '"build":"%s","setup_s":%s,"build_s":%s,"image":"%s","run_id":"%s"}\n' \
  "${BUILD:-}" "$(seconds "${t0}" "${t1}")" "$(seconds "${t1}" "${now}")" \
  "${ImageOS:-container}-${ImageVersion:-}" "${GITHUB_RUN_ID}"
