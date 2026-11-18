#!/usr/bin/env bash
set -euo pipefail
src="$(dirname "$0")"
build="${RUNNER_TEMP:-/tmp}/cpp-boost-build"
cmake -S "${src}" -B "${build}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${build}" --parallel
ctest --test-dir "${build}" --output-on-failure
"${build}/bench" --self-test
