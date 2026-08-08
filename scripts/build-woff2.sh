#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! command -v fonttools >/dev/null 2>&1; then
  echo "Expected fonttools to be installed. Try: python3 -m pip install fonttools brotli" >&2
  exit 1
fi

build_family() {
  src_dir="$1"
  out_dir="$2"

  mkdir -p "$out_dir"

  for src in "$src_dir"/*.ttf; do
    [ -e "$src" ] || continue
    base=$(basename "$src" .ttf)
    fonttools ttLib.woff2 compress "$src" -o "$out_dir/$base.woff2"
  done
}

build_family "$repo_dir/fonts/ttf" "$repo_dir/fonts/woff2"
build_family "$repo_dir/fonts/ttf-focus" "$repo_dir/fonts/woff2-focus"
build_family "$repo_dir/fonts/ttf-instrument" "$repo_dir/fonts/woff2-instrument"
build_family "$repo_dir/fonts/ttf-text" "$repo_dir/fonts/woff2-text"

echo "Built WOFF2 fonts in:"
echo "  $repo_dir/fonts/woff2"
echo "  $repo_dir/fonts/woff2-focus"
echo "  $repo_dir/fonts/woff2-instrument"
echo "  $repo_dir/fonts/woff2-text"
