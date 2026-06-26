#!/usr/bin/env sh
set -eu

repo_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")/.." && pwd)

BERKA_OS=Darwin "$repo_dir/scripts/install.sh" --source-dir "$repo_dir" "$@"
