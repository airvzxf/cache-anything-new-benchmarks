#!/usr/bin/env bash
# Installs the packages listed in <scenario>/packages.txt with apt.
# Usage: install-apt.sh scenarios/<name>
set -euo pipefail

scenario="${1:?usage: install-apt.sh scenarios/<name>}"
mapfile -t packages < <(grep -vE '^\s*(#|$)' "${scenario}/packages.txt")

as_root() {
  if [[ "$(id -u)" == 0 ]]; then "$@"; else sudo "$@"; fi
}

as_root apt-get update -qq
as_root env DEBIAN_FRONTEND=noninteractive \
  apt-get install -y -qq --no-install-recommends "${packages[@]}"
