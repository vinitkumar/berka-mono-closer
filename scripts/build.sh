#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/Iosevka" >&2
  exit 1
fi

iosevka_dir="$1"
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ ! -f "$iosevka_dir/package.json" ] || [ ! -f "$iosevka_dir/build-plans.toml" ]; then
  echo "Expected an Iosevka source checkout at: $iosevka_dir" >&2
  exit 1
fi

cp "$repo_dir/sources/private-build-plans.toml" "$iosevka_dir/private-build-plans.toml"
cd "$iosevka_dir"
npm install
npm run build -- ttf::BerkaMonoCloser --jCmd="${JOBS:-2}"

cp "$repo_dir/sources/compact/private-build-plans.toml" "$iosevka_dir/private-build-plans.toml"
npm run build -- ttf::BerkaMonoCloserCompact --jCmd="${JOBS:-2}"

cp "$repo_dir/sources/semi-condensed/private-build-plans.toml" "$iosevka_dir/private-build-plans.toml"
npm run build -- ttf::BerkaMonoCloserSemiCondensed --jCmd="${JOBS:-2}"

cp "$repo_dir/sources/control/private-build-plans.toml" "$iosevka_dir/private-build-plans.toml"
npm run build -- ttf::BerkaMonoControl --jCmd="${JOBS:-2}"

echo "Built fonts in:"
echo "  $iosevka_dir/dist/BerkaMonoCloser/TTF"
echo "  $iosevka_dir/dist/BerkaMonoCloserCompact/TTF"
echo "  $iosevka_dir/dist/BerkaMonoCloserSemiCondensed/TTF"
echo "  $iosevka_dir/dist/BerkaMonoControl/TTF"
