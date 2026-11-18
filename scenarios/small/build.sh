#!/usr/bin/env bash
set -euo pipefail
test "$(echo '{"answer": 42}' | jq '.answer')" = 42
tree --version
