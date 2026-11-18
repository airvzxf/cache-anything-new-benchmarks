#!/usr/bin/env bash
# Installs the packages listed in <scenario>/packages.txt with apt, timing each phase so the
# download (which depends on the mirror) can be told apart from the rest.
# Usage: install-apt.sh scenarios/<name>
set -euo pipefail

scenario="${1:?usage: install-apt.sh scenarios/<name>}"
mapfile -t packages < <(grep -vE '^\s*(#|$)' "${scenario}/packages.txt")

as_root() {
  if [[ "$(id -u)" == 0 ]]; then "$@"; else sudo "$@"; fi
}

install=(env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends)
times="${RUNNER_TEMP:-/tmp}/apt-times"

t0="$(date +%s.%N)"
as_root apt-get update -qq
t1="$(date +%s.%N)"
as_root "${install[@]}" --download-only "${packages[@]}"
t2="$(date +%s.%N)"
as_root "${install[@]}" "${packages[@]}"
t3="$(date +%s.%N)"

awk -v t0="${t0}" -v t1="${t1}" -v t2="${t2}" -v t3="${t3}" 'BEGIN {
  printf "update_s=%.1f download_s=%.1f unpack_s=%.1f\n", t1 - t0, t2 - t1, t3 - t2
}' | tee "${times}"
