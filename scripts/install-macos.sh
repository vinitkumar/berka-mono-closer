#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
font_dir="$HOME/Library/Fonts"

if [ ! -d "$repo_dir/fonts/ttf" ] || [ ! -f "$repo_dir/fonts/ttf/BerkaMonoCloser-Regular.ttf" ]; then
  if command -v curl >/dev/null 2>&1; then
    echo "Local TTF files were not found; downloading Berka fonts with scripts/install.sh"
    curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh
    exit $?
  fi
  echo "Local TTF files were not found and curl is unavailable." >&2
  echo "Run scripts/install-macos.sh from a full repo checkout, or install with:" >&2
  echo "curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh" >&2
  exit 1
fi

mkdir -p "$font_dir"
find "$font_dir" -maxdepth 1 -type f \( -name "BerkaMonoCloser*.ttf" -o -name "BerkaMonoCloserCompact*.ttf" -o -name "BerkaMonoCloserSemiCondensed*.ttf" -o -name "BerkaMonoCloserNarrow*.ttf" -o -name "BerkaMonoControl*.ttf" -o -name "BerkaMonoRetina*.ttf" \) -delete
cp "$repo_dir"/fonts/ttf/BerkaMonoCloser*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-compact/BerkaMonoCloserCompact*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-semi-condensed/BerkaMonoCloserSemiCondensed*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-narrow/BerkaMonoCloserNarrow*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-control/BerkaMonoControl*.ttf "$font_dir"/
cp "$repo_dir"/fonts/ttf-retina/BerkaMonoRetina*.ttf "$font_dir"/

echo "Installed Berka Mono Closer, Berka Mono Closer Compact, Berka Mono Closer SemiCondensed, Berka Mono Closer Narrow, Berka Mono Control, and Berka Mono Retina into $font_dir"
