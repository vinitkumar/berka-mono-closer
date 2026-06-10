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
build_family "$repo_dir/fonts/ttf-compact" "$repo_dir/fonts/woff2-compact"
build_family "$repo_dir/fonts/ttf-semi-condensed" "$repo_dir/fonts/woff2-semi-condensed"
build_family "$repo_dir/fonts/ttf-control" "$repo_dir/fonts/woff2-control"

echo "Built WOFF2 fonts in:"
echo "  $repo_dir/fonts/woff2"
echo "  $repo_dir/fonts/woff2-compact"
echo "  $repo_dir/fonts/woff2-semi-condensed"
echo "  $repo_dir/fonts/woff2-control"
