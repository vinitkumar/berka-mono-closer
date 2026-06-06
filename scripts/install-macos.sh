#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
font_dir="$HOME/Library/Fonts"

mkdir -p "$font_dir"
find "$font_dir" -maxdepth 1 -type f \( -name "BerkaMonoCloser*.ttf" -o -name "BerkaMonoCloserCompact*.ttf" -o -name "BerkaMonoCloserSemiCondensed*.ttf" -o -name "BerkaMonoControl*.ttf" \) -delete
cp "$repo_dir"/fonts/ttf/BerkaMonoCloser*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-compact/BerkaMonoCloserCompact*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-semi-condensed/BerkaMonoCloserSemiCondensed*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-control/BerkaMonoControl*.ttf "$font_dir"/

echo "Installed Berka Mono Closer, Berka Mono Closer Compact, Berka Mono Closer SemiCondensed, and Berka Mono Control into $font_dir"
