#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
installer="$repo_dir/scripts/install.sh"
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/berka-install-test.XXXXXX")

cleanup() {
  rm -rf "$tmp_root"
}

trap cleanup 0

fail() {
  printf '[test-install] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  haystack="$1"
  needle="$2"
  printf '%s\n' "$haystack" | grep -F "$needle" >/dev/null 2>&1 ||
    fail "expected output to contain: $needle"
}

assert_file_count() {
  dir="$1"
  expected="$2"
  count=$(find "$dir" -maxdepth 1 -type f -name '*.ttf' | wc -l | tr -d ' ')
  [ "$count" = "$expected" ] || fail "expected $expected TTF files in $dir, found $count"
}

printf '[test-install] shell syntax\n'
sh -n "$installer"

printf '[test-install] help output\n'
help_output=$("$installer" --help)
assert_contains "$help_output" "Usage:"
assert_contains "$help_output" "BERKA_DRY_RUN=1"

printf '[test-install] macOS dry run\n'
mac_output=$(BERKA_DRY_RUN=1 BERKA_OS=Darwin "$installer" focus)
assert_contains "$mac_output" "Dry run: would install all Berka font families into"
assert_contains "$mac_output" "BerkaMonoFocus-Regular.ttf"
assert_contains "$mac_output" "BerkaText-BoldItalic.ttf"
assert_contains "$mac_output" "VS Code, Cursor, Windsurf:"
assert_contains "$mac_output" "font-family = \"Berka Mono Focus\""

printf '[test-install] Linux dry run with alias\n'
linux_output=$(BERKA_DRY_RUN=1 BERKA_OS=Linux "$installer" semi)
assert_contains "$linux_output" "Berka Mono Closer SemiCondensed"
assert_contains "$linux_output" "BerkaMonoCloserSemiCondensed-Regular.ttf"
assert_contains "$linux_output" "BerkaMonoRetina-Regular.ttf"

printf '[test-install] Windows dry run\n'
windows_output=$(BERKA_DRY_RUN=1 BERKA_OS=Windows "$installer" text)
assert_contains "$windows_output" "Windows user font directory"
assert_contains "$windows_output" "register it in HKCU"
assert_contains "$windows_output" "Windows Terminal:"
assert_contains "$windows_output" "BerkaMonoControl-Regular.ttf"

printf '[test-install] rejects unknown family\n'
bad_output="$tmp_root/bad.out"
if BERKA_DRY_RUN=1 BERKA_OS=Linux "$installer" nope >"$bad_output" 2>&1; then
  fail "unknown family should fail"
fi
assert_contains "$(cat "$bad_output")" "Unknown family"

printf '[test-install] installs all local fonts with focus guide into temp directory\n'
font_dir="$tmp_root/fonts"
local_output="$tmp_root/local.out"
BERKA_OS=Linux BERKA_FONT_DIR="$font_dir" "$installer" --source-dir "$repo_dir" focus >"$local_output"
assert_contains "$(cat "$local_output")" "Installed all Berka font families into $font_dir"
assert_contains "$(cat "$local_output")" "Verified 10 local TTF files for Berka Mono Focus"
assert_contains "$(cat "$local_output")" "Verified 72 total local TTF files for all Berka families"
assert_file_count "$font_dir" 72
[ -f "$font_dir/BerkaMonoFocus-Regular.ttf" ] || fail "regular font was not installed"
[ -f "$font_dir/BerkaText-BoldItalic.ttf" ] || fail "text bold italic font was not installed"

printf '[test-install] installs all local fonts with closer guide into temp directory\n'
font_dir="$tmp_root/closer-fonts"
closer_output="$tmp_root/closer.out"
BERKA_OS=Darwin BERKA_FONT_DIR="$font_dir" "$installer" --source-dir "$repo_dir" closer >"$closer_output"
assert_contains "$(cat "$closer_output")" "Installed all Berka font families into $font_dir"
assert_contains "$(cat "$closer_output")" "Verified 8 local TTF files for Berka Mono Closer"
assert_contains "$(cat "$closer_output")" "Configure editors with: Berka Mono Closer"
assert_file_count "$font_dir" 72
[ -f "$font_dir/BerkaMonoCloser-Regular.ttf" ] || fail "closer regular font was not installed"
[ -f "$font_dir/BerkaMonoRetina-Regular.ttf" ] || fail "retina regular font was not installed"

printf '[test-install] downloads through curl raw-base path\n'
font_dir="$tmp_root/downloaded-fonts"
download_output="$tmp_root/download.out"
BERKA_OS=Linux BERKA_FONT_DIR="$font_dir" BERKA_RAW_BASE="file://$repo_dir" "$installer" compact >"$download_output"
assert_contains "$(cat "$download_output")" "Downloading from file://$repo_dir"
assert_contains "$(cat "$download_output")" "Verified 8 local TTF files for Berka Mono Closer Compact"
assert_contains "$(cat "$download_output")" "Verified 72 total local TTF files for all Berka families"
assert_contains "$(cat "$download_output")" "Installed all Berka font families into $font_dir"
assert_file_count "$font_dir" 72
[ -f "$font_dir/BerkaMonoCloserCompact-Regular.ttf" ] || fail "downloaded compact regular font was not installed"
[ -f "$font_dir/BerkaMonoControl-Regular.ttf" ] || fail "downloaded control regular font was not installed"

printf '[test-install] rejects incomplete local font set\n'
partial_source="$tmp_root/partial-source"
mkdir -p "$partial_source/fonts/ttf-focus"
cp "$repo_dir/fonts/ttf-focus/BerkaMonoFocus-Regular.ttf" "$partial_source/fonts/ttf-focus/"
partial_output="$tmp_root/partial.out"
if BERKA_OS=Linux BERKA_FONT_DIR="$tmp_root/partial-fonts" "$installer" --source-dir "$partial_source" focus >"$partial_output" 2>&1; then
  fail "incomplete source directory should fail"
fi
assert_contains "$(cat "$partial_output")" "Expected TTF file not found"

printf '[test-install] ok\n'
