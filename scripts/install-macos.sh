#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
font_dir="$HOME/Library/Fonts"

mkdir -p "$font_dir"
find "$font_dir" -maxdepth 1 -type f -name "BerkaMonoCloser*.ttf" -delete
cp "$repo_dir"/fonts/ttf/BerkaMonoCloser*.ttf "$font_dir"/

echo "Installed Berka Mono Closer into $font_dir"

