#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
font_dir="$HOME/Library/Fonts"
current_step="starting"

log() {
  printf '[berka-install] %s\n' "$*"
}

die() {
  printf '[berka-install] ERROR: %s\n' "$*" >&2
  exit 1
}

set_step() {
  current_step="$1"
  log "$1"
}

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    printf '[berka-install] FAILED while %s (exit %s)\n' "$current_step" "$status" >&2
  fi
  exit "$status"
}

interrupted() {
  printf '\n[berka-install] Interrupted while %s\n' "$current_step" >&2
  exit 130
}

copy_fonts() {
  label="$1"
  src_dir="$2"
  pattern="$3"

  set_step "Installing $label from $src_dir"
  [ -d "$src_dir" ] || die "Expected directory not found: $src_dir"

  set -- "$src_dir"/$pattern
  [ -f "$1" ] || die "No fonts matched: $src_dir/$pattern"

  count=$#
  log "Found $count $label TTF file(s)."
  for file do
    log "  -> copying $(basename "$file") to $font_dir"
  done
  cp "$@" "$font_dir"/
  log "Copied $count $label TTF file(s)."
}

trap cleanup EXIT
trap interrupted INT TERM

if [ ! -d "$repo_dir/fonts/ttf" ] || [ ! -f "$repo_dir/fonts/ttf/BerkaMonoCloser-Regular.ttf" ]; then
  if command -v curl >/dev/null 2>&1; then
    set_step "Local TTF files were not found; downloading Berka fonts with scripts/install.sh"
    curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh
    exit $?
  fi
  printf '[berka-install] ERROR: Local TTF files were not found and curl is unavailable.\n' >&2
  printf '[berka-install] Run scripts/install-macos.sh from a full repo checkout, or install with:\n' >&2
  printf '[berka-install] curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh\n' >&2
  exit 1
fi

set_step "Using repo checkout at $repo_dir"
set_step "Ensuring macOS font directory exists: $font_dir"
mkdir -p "$font_dir"

set_step "Removing existing Berka TTF files from $font_dir"
existing_fonts=$(find "$font_dir" -maxdepth 1 -type f \( -name "BerkaMonoCloser*.ttf" -o -name "BerkaMonoCloserCompact*.ttf" -o -name "BerkaMonoCloserSemiCondensed*.ttf" -o -name "BerkaMonoCloserNarrow*.ttf" -o -name "BerkaMonoControl*.ttf" -o -name "BerkaMonoRetina*.ttf" \) -print)
if [ -n "$existing_fonts" ]; then
  printf '%s\n' "$existing_fonts" | while IFS= read -r file; do
    log "  -> deleting $file"
  done
  printf '%s\n' "$existing_fonts" | while IFS= read -r file; do
    rm -f "$file"
  done
else
  log "No existing Berka TTF files found."
fi

copy_fonts "Berka Mono Closer" "$repo_dir/fonts/ttf" "BerkaMonoCloser*.ttf"
copy_fonts "Berka Mono Closer Compact" "$repo_dir/fonts/ttf-compact" "BerkaMonoCloserCompact*.ttf"
copy_fonts "Berka Mono Closer SemiCondensed" "$repo_dir/fonts/ttf-semi-condensed" "BerkaMonoCloserSemiCondensed*.ttf"
copy_fonts "Berka Mono Closer Narrow" "$repo_dir/fonts/ttf-narrow" "BerkaMonoCloserNarrow*.ttf"
copy_fonts "Berka Mono Control" "$repo_dir/fonts/ttf-control" "BerkaMonoControl*.ttf"
copy_fonts "Berka Mono Retina" "$repo_dir/fonts/ttf-retina" "BerkaMonoRetina*.ttf"

set_step "Installed Berka Mono Closer, Berka Mono Closer Compact, Berka Mono Closer SemiCondensed, Berka Mono Closer Narrow, Berka Mono Control, and Berka Mono Retina into $font_dir"
