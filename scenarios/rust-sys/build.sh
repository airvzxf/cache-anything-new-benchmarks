#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export CARGO_TARGET_DIR="${RUNNER_TEMP:-/tmp}/rust-sys-target"
cargo test --locked --release
cargo run --locked --release
