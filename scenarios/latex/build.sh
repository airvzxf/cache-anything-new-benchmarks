#!/usr/bin/env bash
set -euo pipefail
src="$(cd "$(dirname "$0")" && pwd)"
out="${RUNNER_TEMP:-/tmp}/latex-build"
mkdir -p "${out}"
xelatex -interaction=nonstopmode -halt-on-error -output-directory "${out}" "${src}/report.tex"
pdffonts "${out}/report.pdf" | grep -q 'NotoSerif'
pdftotext "${out}/report.pdf" - | grep -q 'Zürich'
pdfinfo "${out}/report.pdf" | grep -E '^Pages:'
