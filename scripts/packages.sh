#!/usr/bin/env bash
# Prints the packages of <scenario>/packages.txt on one line, for actions that take a list.
set -euo pipefail
grep -vE '^\s*(#|$)' "${1:?usage: packages.sh scenarios/<name>}/packages.txt" | paste -sd ' '
