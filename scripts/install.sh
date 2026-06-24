#!/usr/bin/env sh
set -eu

repo="vinitkumar/berka-mono-closer"
branch="${BERKA_BRANCH:-main}"
raw_base="${BERKA_RAW_BASE:-https://raw.githubusercontent.com/$repo/$branch}"
families="focus retina control closer compact semi-condensed narrow text"

family="${BERKA_FONT:-}"
dry_run="${BERKA_DRY_RUN:-0}"
source_dir="${BERKA_SOURCE_DIR:-}"
download_dir=""
install_dir_override="${BERKA_FONT_DIR:-}"
detected_os="${BERKA_OS:-}"

log() {
  printf '[berka-install] %s\n' "$*"
}

die() {
  printf '[berka-install] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  scripts/install.sh [guide-family]
  scripts/install.sh --family focus
  scripts/install.sh --dry-run --source-dir .

Families:
  focus            Berka Mono Focus (default)
  retina           Berka Mono Retina
  control          Berka Mono Control
  closer           Berka Mono Closer
  compact          Berka Mono Closer Compact
  semi-condensed   Berka Mono Closer SemiCondensed
  narrow           Berka Mono Closer Narrow
  text             Berka Text

Environment:
  BERKA_FONT       Default guide family when no positional family is passed
  BERKA_BRANCH     Git branch/tag for raw GitHub downloads (default: main)
  BERKA_RAW_BASE   Override raw download base URL
  BERKA_SOURCE_DIR Install from an existing repo checkout instead of download
  BERKA_FONT_DIR   Override the destination font directory
  BERKA_OS         Override OS detection for tests: Darwin, Linux, Windows
  BERKA_DRY_RUN=1  Print actions without writing files
EOF
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

canonical_family() {
  case "$1" in
    focus) printf '%s\n' focus ;;
    retina) printf '%s\n' retina ;;
    control) printf '%s\n' control ;;
    closer) printf '%s\n' closer ;;
    compact) printf '%s\n' compact ;;
    semi-condensed|semicondensed|semi) printf '%s\n' semi-condensed ;;
    narrow) printf '%s\n' narrow ;;
    text) printf '%s\n' text ;;
    *) return 1 ;;
  esac
}

select_guide_family() {
  if [ -n "$family" ]; then
    canonical_family "$family" || return 1
    return 0
  fi

  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    {
      printf 'Choose the Berka family for the editor/terminal setup guide:\n'
      printf '  1) Berka Mono Focus (recommended)\n'
      printf '  2) Berka Mono Retina\n'
      printf '  3) Berka Mono Control\n'
      printf '  4) Berka Mono Closer\n'
      printf '  5) Berka Mono Closer Compact\n'
      printf '  6) Berka Mono Closer SemiCondensed\n'
      printf '  7) Berka Mono Closer Narrow\n'
      printf '  8) Berka Text\n'
      printf 'Selection [1]: '
    } >/dev/tty
    read -r answer </dev/tty
    case "${answer:-1}" in
      1) printf '%s\n' focus ;;
      2) printf '%s\n' retina ;;
      3) printf '%s\n' control ;;
      4) printf '%s\n' closer ;;
      5) printf '%s\n' compact ;;
      6) printf '%s\n' semi-condensed ;;
      7) printf '%s\n' narrow ;;
      8) printf '%s\n' text ;;
      *) return 1 ;;
    esac
    return 0
  fi

  printf '%s\n' focus
}

family_name() {
  case "$1" in
    focus) printf '%s\n' "Berka Mono Focus" ;;
    retina) printf '%s\n' "Berka Mono Retina" ;;
    control) printf '%s\n' "Berka Mono Control" ;;
    closer) printf '%s\n' "Berka Mono Closer" ;;
    compact) printf '%s\n' "Berka Mono Closer Compact" ;;
    semi-condensed) printf '%s\n' "Berka Mono Closer SemiCondensed" ;;
    narrow) printf '%s\n' "Berka Mono Closer Narrow" ;;
    text) printf '%s\n' "Berka Text" ;;
    *) return 1 ;;
  esac
}

family_dir() {
  case "$1" in
    closer) printf '%s\n' "fonts/ttf" ;;
    compact) printf '%s\n' "fonts/ttf-compact" ;;
    semi-condensed) printf '%s\n' "fonts/ttf-semi-condensed" ;;
    narrow) printf '%s\n' "fonts/ttf-narrow" ;;
    control) printf '%s\n' "fonts/ttf-control" ;;
    retina) printf '%s\n' "fonts/ttf-retina" ;;
    focus) printf '%s\n' "fonts/ttf-focus" ;;
    text) printf '%s\n' "fonts/ttf-text" ;;
    *) return 1 ;;
  esac
}

family_files() {
  case "$1" in
    closer) prefix="BerkaMonoCloser"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    compact) prefix="BerkaMonoCloserCompact"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    semi-condensed) prefix="BerkaMonoCloserSemiCondensed"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    narrow) prefix="BerkaMonoCloserNarrow"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    control) prefix="BerkaMonoControl"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    retina) prefix="BerkaMonoRetina"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    focus) prefix="BerkaMonoFocus"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    text) prefix="BerkaText"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    *) return 1 ;;
  esac

  for style in $styles; do
    printf '%s-%s.ttf\n' "$prefix" "$style"
  done
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        ;;
      --family)
        [ "$#" -ge 2 ] || die "--family requires a value"
        family="$2"
        shift
        ;;
      --source-dir)
        [ "$#" -ge 2 ] || die "--source-dir requires a value"
        source_dir="$2"
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        family="$1"
        ;;
    esac
    shift
  done

  [ "$#" -eq 0 ] || die "Unexpected extra arguments: $*"
}

validate_ttf() {
  ttf_path="$1"
  [ -f "$ttf_path" ] || die "Expected TTF file not found: $ttf_path"

  size=$(wc -c < "$ttf_path" | tr -d ' ')
  [ "$size" -gt 100000 ] || die "$ttf_path is too small to be a real Berka TTF ($size bytes)"

  magic=$(od -An -N4 -tx1 "$ttf_path" | tr -d ' \n')
  case "$magic" in
    00010000|4f54544f|74727565) ;;
    *) die "$ttf_path is not a TTF/OTF font file (magic: ${magic:-empty})" ;;
  esac
}

expected_file_count() {
  count_key="$1"
  count=0
  for count_file in $(family_files "$count_key"); do
    count=$((count + 1))
  done
  printf '%s\n' "$count"
}

verify_local_fonts() {
  verify_key="$1"
  verify_dir="$2"
  verify_label="$3"
  verified=0

  [ -d "$verify_dir" ] || die "$verify_label directory does not exist: $verify_dir"

  for verify_file in $(family_files "$verify_key"); do
    verify_path="$verify_dir/$verify_file"
    validate_ttf "$verify_path"
    verified=$((verified + 1))
  done

  expected=$(expected_file_count "$verify_key")
  [ "$verified" = "$expected" ] ||
    die "$verify_label verification failed for $(family_name "$verify_key"): expected $expected files, found $verified"

  log "Verified $verified local TTF files for $(family_name "$verify_key") in $verify_dir."
}

verify_all_local_fonts() {
  verify_all_dir="$1"
  verify_all_label="$2"
  total_verified=0

  for verify_family in $families; do
    verify_local_fonts "$verify_family" "$verify_all_dir" "$verify_all_label"
    total_verified=$((total_verified + $(expected_file_count "$verify_family")))
  done

  log "Verified $total_verified total local TTF files for all Berka families in $verify_all_dir."
}

cleanup() {
  status=$?
  if [ -n "$download_dir" ] && [ -d "$download_dir" ]; then
    rm -rf "$download_dir"
  fi
  exit "$status"
}

stage_from_source() {
  source_key="$1"
  stage_dest="$2"
  source_family_dir=$(family_dir "$source_key")

  [ -d "$source_dir/$source_family_dir" ] || die "Source directory does not contain $source_family_dir: $source_dir"
  mkdir -p "$stage_dest"

  for source_file in $(family_files "$source_key"); do
    source_path="$source_dir/$source_family_dir/$source_file"
    validate_ttf "$source_path"
    cp "$source_path" "$stage_dest/$source_file"
  done
}

stage_all_from_source() {
  all_source_dest="$1"
  for all_source_key in $families; do
    stage_from_source "$all_source_key" "$all_source_dest"
  done
}

stage_from_download() {
  download_key="$1"
  stage_dest="$2"
  download_family_dir=$(family_dir "$download_key")

  need curl
  mkdir -p "$stage_dest"

  for download_file in $(family_files "$download_key"); do
    download_url="$raw_base/$download_family_dir/$download_file"
    download_tmp="$stage_dest/$download_file.part"
    log "Downloading $download_file"
    curl -fL --retry 3 --retry-delay 1 --progress-bar "$download_url" -o "$download_tmp" ||
      die "Failed to download $download_url"
    validate_ttf "$download_tmp"
    mv "$download_tmp" "$stage_dest/$download_file"
  done
}

stage_all_from_download() {
  all_download_dest="$1"
  for all_download_key in $families; do
    stage_from_download "$all_download_key" "$all_download_dest"
  done
}

stage_all_fonts() {
  if [ "$dry_run" = 1 ]; then
    return
  fi

  download_dir=$(mktemp -d "${TMPDIR:-/tmp}/berka-fonts.XXXXXX")
  if [ -n "$source_dir" ]; then
    log "Using local font files from $source_dir"
    stage_all_from_source "$download_dir"
  else
    log "Downloading from $raw_base"
    stage_all_from_download "$download_dir"
  fi

  verify_all_local_fonts "$download_dir" "Downloaded"
}

detect_os() {
  if [ -n "$detected_os" ]; then
    printf '%s\n' "$detected_os"
    return
  fi

  case "$(uname -s 2>/dev/null || printf unknown)" in
    Darwin) printf '%s\n' Darwin ;;
    Linux) printf '%s\n' Linux ;;
    MINGW*|MSYS*|CYGWIN*) printf '%s\n' Windows ;;
    *) die "Unsupported platform. Supported: macOS, Linux, Windows." ;;
  esac
}

default_font_dir() {
  default_os="$1"
  if [ -n "$install_dir_override" ]; then
    printf '%s\n' "$install_dir_override"
    return
  fi

  case "$default_os" in
    Darwin) printf '%s\n' "$HOME/Library/Fonts" ;;
    Linux) printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    Windows) printf '%s\n' "Windows user font directory" ;;
    *) die "Unsupported platform: $default_os" ;;
  esac
}

windows_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

install_unix_fonts() {
  install_dest="$2"

  if [ "$dry_run" = 1 ]; then
    log "Dry run: would install all Berka font families into $install_dest"
    for dry_family in $families; do
      for dry_file in $(family_files "$dry_family"); do
        log "Dry run: would install $dry_file"
      done
    done
    return
  fi

  mkdir -p "$install_dest"
  for install_file in "$download_dir"/*.ttf; do
    validate_ttf "$install_file"
    cp "$install_file" "$install_dest/"
  done

  verify_all_local_fonts "$install_dest" "Installed"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$install_dest" >/dev/null 2>&1 || true
  fi
}

install_windows_fonts() {
  install_key="$1"

  if [ "$dry_run" = 1 ]; then
    log "Dry run: would install all Berka font families into the Windows user font directory"
    for dry_family in $families; do
      for dry_file in $(family_files "$dry_family"); do
        log "Dry run: would install $dry_file and register it in HKCU"
      done
    done
    return
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    ps="powershell.exe"
  elif command -v powershell >/dev/null 2>&1; then
    ps="powershell"
  else
    die "Missing PowerShell. Install from Windows, MSYS2, Git Bash, or WSL with powershell.exe available."
  fi

  src=$(windows_path "$download_dir")
  "$ps" -NoProfile -ExecutionPolicy Bypass -Command "
    \$ErrorActionPreference = 'Stop'
    \$src = '$src'
    \$dest = Join-Path \$env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Force -Path \$dest | Out-Null
    Get-ChildItem -Path \$src -Filter '*.ttf' | ForEach-Object {
      \$target = Join-Path \$dest \$_.Name
      Copy-Item \$_.FullName -Destination \$target -Force
      New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -Name (\$_.BaseName + ' (TrueType)') -Value \$target -PropertyType String -Force | Out-Null
    }
  "
}

install_fonts() {
  install_key="$1"
  install_os="$2"
  install_dest="$3"

  case "$install_os" in
    Darwin|Linux) install_unix_fonts "$install_key" "$install_dest" ;;
    Windows) install_windows_fonts "$install_key" ;;
    *) die "Unsupported platform: $install_os" ;;
  esac
}

print_editor_docs() {
  doc_name="$1"

  cat <<EOF

Configure editors with: $doc_name

Use this font family name in your editor or terminal:
  $doc_name

VS Code, Cursor, Windsurf:
  "editor.fontFamily": "'$doc_name', Menlo, Monaco, Consolas, monospace",
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "$doc_name"

Zed:
  "buffer_font_family": "$doc_name",
  "buffer_font_features": { "calt": true, "liga": true },
  "terminal": { "font_family": "$doc_name" }

JetBrains IDEs:
  Settings -> Editor -> Font -> Font: $doc_name
  Settings -> Tools -> Terminal -> Font: $doc_name

Neovim GUI, Neovide, Vim GUI:
  vim.o.guifont = "$doc_name:h15"
  set guifont=$(printf '%s' "$doc_name" | sed 's/ /\\ /g'):h15

Ghostty:
  font-family = "$doc_name"
  font-family-bold = "$doc_name"
  font-family-italic = "$doc_name"
  font-family-bold-italic = "$doc_name"

Kitty:
  font_family      family="$doc_name"
  bold_font        family="$doc_name" style="Bold"
  italic_font      family="$doc_name" style="Italic"
  bold_italic_font family="$doc_name" style="Bold Italic"

WezTerm:
  config.font = wezterm.font("$doc_name")

Alacritty:
  [font]
  normal = { family = "$doc_name", style = "Regular" }
  bold = { family = "$doc_name", style = "Bold" }
  italic = { family = "$doc_name", style = "Italic" }
  bold_italic = { family = "$doc_name", style = "Bold Italic" }

Windows Terminal:
  "profiles": { "defaults": { "font": { "face": "$doc_name" } } }

CSS:
  Use WOFF2 files from this repo for websites. TTF files are installed for desktop apps.
EOF
}

main() {
  parse_args "$@"
  guide_family=$(select_guide_family) || die "Unknown family. Use one of: $families"
  guide_name=$(family_name "$guide_family")
  selected_os=$(detect_os)
  target_dir=$(default_font_dir "$selected_os")

  log "Installing all Berka font families."
  log "Selected $guide_name for setup guidance."
  log "Detected OS: $selected_os."
  stage_all_fonts
  install_fonts "$guide_family" "$selected_os" "$target_dir"

  if [ "$dry_run" = 1 ]; then
    log "Dry run complete. No files were changed."
  else
    log "Installed all Berka font families into $target_dir."
  fi

  print_editor_docs "$guide_name"
}

trap cleanup 0
main "$@"
