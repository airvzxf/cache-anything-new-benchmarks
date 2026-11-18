#!/usr/bin/env bash
# The toolkit comes from Jimver/cuda-toolkit, not from apt packages.txt.
set -euo pipefail
src="$(dirname "$0")"
out="${RUNNER_TEMP:-/tmp}/cuda-build"
mkdir -p "${out}"
nvcc --version
nvcc -O2 -o "${out}/hello" "${src}/hello.cu"
file "${out}/hello" | grep -q ELF
