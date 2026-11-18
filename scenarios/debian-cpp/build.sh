#!/usr/bin/env bash
# Builds the cpp-boost sources; this scenario only changes where the job runs.
set -euo pipefail
exec bash "$(dirname "$0")/../cpp-boost/build.sh"
