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
# Written by install-apt.sh when it ran in this job (not on a cache hit).
update_s=null download_s=null unpack_s=null
if [[ -r "${RUNNER_TEMP}/apt-times" ]]; then
  # shellcheck disable=SC1091
  source "${RUNNER_TEMP}/apt-times"
fi

printf '"build":"%s","setup_s":%s,"build_s":%s,"image":"%s","run_id":"%s",' \
  "${BUILD:-}" "$(seconds "${t0}" "${t1}")" "$(seconds "${t1}" "${now}")" \
  "${ImageOS:-container}-${ImageVersion:-}" "${GITHUB_RUN_ID}"
printf '"update_s":%s,"download_s":%s,"unpack_s":%s}\n' "${update_s}" "${download_s}" "${unpack_s}"
