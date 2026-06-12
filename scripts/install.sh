#!/usr/bin/env sh
set -eu

repo="vinitkumar/berka-mono-closer"
branch="${BERKA_BRANCH:-main}"
raw_base="https://raw.githubusercontent.com/$repo/$branch"

families='closer compact semi-condensed narrow control retina'
choice="${1:-${BERKA_FONT:-}}"
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
  if [ -n "${download_dir:-}" ] && [ -d "$download_dir" ]; then
    rm -rf "$download_dir"
  fi
  if [ "$status" -ne 0 ]; then
    printf '[berka-install] FAILED while %s (exit %s)\n' "$current_step" "$status" >&2
  fi
  exit "$status"
}

interrupted() {
  printf '\n[berka-install] Interrupted while %s\n' "$current_step" >&2
  exit 130
}

family_name() {
  case "$1" in
    closer) printf '%s\n' "Berka Mono Closer" ;;
    compact) printf '%s\n' "Berka Mono Closer Compact" ;;
    semi-condensed|semicondensed|semi) printf '%s\n' "Berka Mono Closer SemiCondensed" ;;
    narrow) printf '%s\n' "Berka Mono Closer Narrow" ;;
    control) printf '%s\n' "Berka Mono Control" ;;
    retina) printf '%s\n' "Berka Mono Retina" ;;
    *) return 1 ;;
  esac
}

family_xcode_name() {
  case "$1" in
    closer) printf '%s\n' "BerkaMonoCloser-Regular" ;;
    compact) printf '%s\n' "BerkaMonoCloserCompact-Regular" ;;
    semi-condensed|semicondensed|semi) printf '%s\n' "BerkaMonoCloserSemiCondensed-Regular" ;;
    narrow) printf '%s\n' "BerkaMonoCloserNarrow-Regular" ;;
    control) printf '%s\n' "BerkaMonoControl-Regular" ;;
    retina) printf '%s\n' "BerkaMonoRetina-Regular" ;;
    *) return 1 ;;
  esac
}

family_dir() {
  case "$1" in
    closer) printf '%s\n' "fonts/ttf" ;;
    compact) printf '%s\n' "fonts/ttf-compact" ;;
    semi-condensed|semicondensed|semi) printf '%s\n' "fonts/ttf-semi-condensed" ;;
    narrow) printf '%s\n' "fonts/ttf-narrow" ;;
    control) printf '%s\n' "fonts/ttf-control" ;;
    retina) printf '%s\n' "fonts/ttf-retina" ;;
    *) return 1 ;;
  esac
}

family_files() {
  case "$1" in
    closer) prefix="BerkaMonoCloser"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    compact) prefix="BerkaMonoCloserCompact"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    semi-condensed|semicondensed|semi) prefix="BerkaMonoCloserSemiCondensed"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    narrow) prefix="BerkaMonoCloserNarrow"; styles="Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    control) prefix="BerkaMonoControl"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    retina) prefix="BerkaMonoRetina"; styles="Book BookItalic Regular Italic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic" ;;
    *) return 1 ;;
  esac
  for style in $styles; do
    printf '%s-%s.ttf\n' "$prefix" "$style"
  done
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    die "Missing required command: $1"
  }
}

validate_ttf() {
  file="$1"
  size=$(wc -c < "$file" | tr -d ' ')
  if [ "$size" -lt 100000 ]; then
    die "Downloaded $file is too small to be a Berka TTF file ($size bytes)"
  fi

  magic=$(od -An -N4 -tx1 "$file" | tr -d ' \n')
  case "$magic" in
    00010000|4f54544f|74727565)
      ;;
    *)
      die "Downloaded $file is not a real TTF/OTF font file (magic: ${magic:-empty})"
      ;;
  esac
}

select_family() {
  if [ -n "$choice" ]; then
    family_name "$choice" >/dev/null || {
      die "Unknown Berka font \"$choice\". Use one of: $families"
    }
    printf '%s\n' "$choice"
    return
  fi

  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    printf 'Choose the Berka font to configure:\n' > /dev/tty
    printf '  1) Berka Mono Closer\n' > /dev/tty
    printf '  2) Berka Mono Closer Compact\n' > /dev/tty
    printf '  3) Berka Mono Closer SemiCondensed\n' > /dev/tty
    printf '  4) Berka Mono Closer Narrow\n' > /dev/tty
    printf '  5) Berka Mono Control\n' > /dev/tty
    printf '  6) Berka Mono Retina\n' > /dev/tty
    printf 'Selection [1]: ' > /dev/tty
    read -r answer < /dev/tty
    case "${answer:-1}" in
      1) printf '%s\n' closer ;;
      2) printf '%s\n' compact ;;
      3) printf '%s\n' semi-condensed ;;
      4) printf '%s\n' narrow ;;
      5) printf '%s\n' control ;;
      6) printf '%s\n' retina ;;
      *) die "Invalid selection: $answer" ;;
    esac
  else
    printf '%s\n' closer
  fi
}

download_family() {
  key="$1"
  dest="$2"
  dir=$(family_dir "$key")
  name=$(family_name "$key")
  set_step "Downloading $name from $branch"
  mkdir -p "$dest"
  for file in $(family_files "$key"); do
    log "  -> $file"
    tmp="$dest/$file.part"
    curl -fL --retry 3 --retry-delay 1 --progress-bar "$raw_base/$dir/$file" -o "$tmp" || die "Failed to download $file from $raw_base/$dir/$file"
    validate_ttf "$tmp"
    mv "$tmp" "$dest/$file"
  done
  log "Downloaded $name."
}

install_fonts_unix() {
  os="$1"
  src="$2"
  case "$os" in
    Darwin) font_dir="$HOME/Library/Fonts" ;;
    Linux) font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    *) die "Unsupported Unix platform: $os" ;;
  esac
  set_step "Installing TTF files into $font_dir"
  mkdir -p "$font_dir"
  find "$font_dir" -maxdepth 1 -type f \( -name "BerkaMonoCloser*.ttf" -o -name "BerkaMonoControl*.ttf" -o -name "BerkaMonoRetina*.ttf" \) -delete
  cp "$src"/*.ttf "$font_dir"/
  if command -v fc-cache >/dev/null 2>&1; then
    log "Refreshing font cache for $font_dir"
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi
  log "Installed Berka fonts into $font_dir"
}

install_fonts_windows() {
  src="$1"
  set_step "Installing TTF files into Windows user font directory"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "\$ErrorActionPreference='Stop'; \$src='$(wpath "$src")'; \$dest=Join-Path \$env:LOCALAPPDATA 'Microsoft\Windows\Fonts'; New-Item -ItemType Directory -Force -Path \$dest | Out-Null; Get-ChildItem \$dest -Filter 'BerkaMono*.ttf' | Remove-Item -Force; Get-ChildItem \$src -Filter '*.ttf' | ForEach-Object { Copy-Item \$_.FullName -Destination \$dest -Force; New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -Name (\$_.BaseName + ' (TrueType)') -Value (Join-Path \$dest \$_.Name) -PropertyType String -Force | Out-Null }; Write-Host \"Installed Berka fonts into \$dest\""
}

wpath() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

json_set_unix() {
  file="$1"
  family="$2"
  mode="$3"
  terminal_family="${4:-$family}"
  mkdir -p "$(dirname "$file")"
  python3 - "$file" "$family" "$mode" "$terminal_family" <<'PY'
import os
import re
import sys

path, family, mode, terminal_family = sys.argv[1:5]

if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
else:
    text = "{\n}\n"

if not text.strip():
    text = "{\n}\n"

def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'

def upsert_scalar(source: str, key: str, value: str) -> str:
    pattern = re.compile(rf'(^\s*"{re.escape(key)}"\s*:\s*)([^,\n}}]+)(,?)', re.MULTILINE)
    if pattern.search(source):
        return pattern.sub(rf'\g<1>{value}\3', source, count=1)
    open_brace = source.find("{")
    if open_brace == -1:
        return "{\n  " + quote(key) + ": " + value + "\n}\n"
    return source[:open_brace + 1] + "\n  " + quote(key) + ": " + value + "," + source[open_brace + 1:]

if mode == "vscode":
    text = upsert_scalar(text, "editor.fontFamily", quote(f'"{family}", Menlo, Monaco, monospace'))
    text = upsert_scalar(text, "editor.fontLigatures", "false")
    text = upsert_scalar(text, "editor.fontSize", "15")
    text = upsert_scalar(text, "editor.lineHeight", "1.5")
    text = upsert_scalar(text, "editor.fontWeight", quote("normal"))
    text = upsert_scalar(text, "terminal.integrated.fontFamily", quote(terminal_family))
elif mode == "zed":
    text = upsert_scalar(text, "buffer_font_family", quote(family))
    text = upsert_scalar(text, "buffer_font_size", "15")

tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    fh.write(text)
os.replace(tmp, path)
PY
}

jetbrains_xml_set_unix() {
  root="$1"
  family="$2"
  [ -d "$root" ] || return 0
  python3 - "$root" "$family" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

root, family = sys.argv[1:3]

targets = {
    "editor.xml": (
        "DefaultFont",
        {
            "FONT_FAMILY": family,
            "FONT_SIZE": "15",
            "FONT_SIZE_2D": "15.0",
            "SECONDARY_FONT_FAMILY": "JetBrains Mono",
            "LINE_SPACING": "1.2",
        },
    ),
    "editor-font.xml": (
        "EditorFont",
        {
            "FONT_FAMILY": family,
            "FONT_SIZE": "15",
            "LINE_SPACING": "1.2",
            "FONT_LIGATURES": "false",
        },
    ),
    "console-font.xml": (
        "ConsoleFont",
        {"FONT_FAMILY": family, "USE_LIGATURES": "false"},
    ),
    "terminal-font.xml": (
        "TerminalFontOptions",
        {"FONT_FAMILY": family, "USE_LIGATURES": "false"},
    ),
}

def indent(element, level=0):
    pad = "\n" + level * "  "
    if len(element):
        if not element.text or not element.text.strip():
            element.text = pad + "  "
        for child in element:
            indent(child, level + 1)
        if not child.tail or not child.tail.strip():
            child.tail = pad
    if level and (not element.tail or not element.tail.strip()):
        element.tail = pad

def set_options(path, component_name, values):
    if os.path.exists(path) and os.path.getsize(path):
        tree = ET.parse(path)
        app = tree.getroot()
        if app.tag != "application":
            return
    else:
        app = ET.Element("application")
        tree = ET.ElementTree(app)

    component = None
    for candidate in app.findall("component"):
        if candidate.get("name") == component_name:
            component = candidate
            break
    if component is None:
        component = ET.SubElement(app, "component", {"name": component_name})

    for name, value in values.items():
        option = None
        for candidate in component.findall("option"):
            if candidate.get("name") == name:
                option = candidate
                break
        if option is None:
            option = ET.SubElement(component, "option", {"name": name})
        option.set("value", value)

    indent(app)
    tmp = path + ".tmp"
    tree.write(tmp, encoding="utf-8", xml_declaration=False)
    os.replace(tmp, path)

for product in os.listdir(root):
    product_dir = os.path.join(root, product)
    if not os.path.isdir(product_dir):
        continue
    for rel in ("options", os.path.join("settingsSync", "options")):
        options = os.path.join(product_dir, rel)
        if not os.path.isdir(options):
            continue
        for filename, (component, values) in targets.items():
            set_options(os.path.join(options, filename), component, values)
PY
}

configure_text_file() {
  file="$1"
  begin="$2"
  end="$3"
  body="$4"
  log "Configuring $file"
  mkdir -p "$(dirname "$file")"
  tmp="$file.tmp"
  if [ -f "$file" ]; then
    awk -v begin="$begin" -v end="$end" '
      $0 == begin {skip=1; next}
      $0 == end {skip=0; next}
      !skip {print}
    ' "$file" > "$tmp"
  else
    : > "$tmp"
  fi
  {
    cat "$tmp"
    printf '\n%s\n%s\n%s\n' "$begin" "$body" "$end"
  } > "$file"
  rm -f "$tmp"
}

write_text_file() {
  file="$1"
  body="$2"
  log "Configuring $file"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$body" > "$file"
}

configure_unix_apps() {
  os="$1"
  family="$2"
  xcode_font="$3"
  font_size_terminal=15
  font_size_editor=15
  set_step "Configuring Unix apps for $family"
  if command -v python3 >/dev/null 2>&1; then
    case "$os" in
      Darwin)
        log "Configuring VS Code settings"
        json_set_unix "$HOME/Library/Application Support/Code/User/settings.json" "$family" vscode "$family"
        log "Configuring Cursor settings"
        json_set_unix "$HOME/Library/Application Support/Cursor/User/settings.json" "$family" vscode "$family"
        log "Configuring Windsurf settings"
        json_set_unix "$HOME/Library/Application Support/Windsurf/User/settings.json" "$family" vscode "$family"
        ;;
      Linux)
        log "Configuring VS Code settings"
        json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json" "$family" vscode "$family"
        log "Configuring Cursor settings"
        json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json" "$family" vscode "$family"
        log "Configuring Windsurf settings"
        json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/Windsurf/User/settings.json" "$family" vscode "$family"
        ;;
    esac
    log "Configuring Zed settings"
    json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/zed/settings.json" "$family" zed
    case "$os" in
      Darwin)
        log "Configuring JetBrains settings"
        jetbrains_xml_set_unix "$HOME/Library/Application Support/JetBrains" "$family"
        ;;
      Linux)
        log "Configuring JetBrains settings"
        jetbrains_xml_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains" "$family"
        ;;
    esac
  else
    log "python3 not found; skipped VS Code, Cursor, Zed, and JetBrains settings."
  fi

  configure_text_file "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf" "# Berka Mono Closer begin" "# Berka Mono Closer end" "font_family      family=\"$family\"
bold_font        family=\"$family\" style=\"Bold\"
italic_font      family=\"$family\" style=\"Italic\"
bold_italic_font family=\"$family\" style=\"Bold Italic\"
font_size        $font_size_terminal.0
disable_ligatures never"

  ghostty_file="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
  configure_text_file "$ghostty_file" "# Berka Mono Closer begin" "# Berka Mono Closer end" "font-family = \"$family\"
font-family-bold = \"$family\"
font-family-italic = \"$family\"
font-family-bold-italic = \"$family\"
font-size = $font_size_terminal
font-feature = liga
font-feature = calt
font-feature = clig
font-thicken = true"

  write_text_file "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/config/fonts.lua" "local wezterm = require('wezterm')
local platform = require('utils.platform')

local font_family = '$family'
local font_size = platform.is_mac and $font_size_terminal or 12

return {
   font = wezterm.font({
      family = font_family,
      weight = 'Regular',
      harfbuzz_features = { 'liga=1', 'calt=1', 'clig=1' },
   }),
   font_rules = {
      {
         intensity = 'Bold',
         font = wezterm.font({ family = font_family, weight = 'Bold' }),
      },
      {
         italic = true,
         font = wezterm.font({ family = font_family, style = 'Italic' }),
      },
      {
         italic = true,
         intensity = 'Bold',
         font = wezterm.font({ family = font_family, weight = 'Bold', style = 'Italic' }),
      },
   },
   font_size = font_size,
   freetype_load_target = 'Light',
   freetype_render_target = 'HorizontalLcd',
   cell_width = 1.0,
   line_height = 1.0,
}"

  configure_text_file "${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml" "# Berka Mono Closer begin" "# Berka Mono Closer end" "[font]
normal = { family = \"$family\", style = \"Regular\" }
bold = { family = \"$family\", style = \"Bold\" }
italic = { family = \"$family\", style = \"Italic\" }
bold_italic = { family = \"$family\", style = \"Bold Italic\" }"

  neovide_conf="${XDG_CONFIG_HOME:-$HOME/.config}/neovide/config.toml"
  if [ -f "$neovide_conf" ]; then
    log "Configuring Neovide"
    if grep -q '^normal = ' "$neovide_conf"; then
      sed -i.bak "s/^normal = .*/normal = \"$family\"/" "$neovide_conf"
    else
      sed -i.bak "/^\[font\]/a\\
normal = \"$family\"" "$neovide_conf"
    fi
    if grep -q '^size = ' "$neovide_conf"; then
      sed -i.bak "s/^size = .*/size = $font_size_editor.0/" "$neovide_conf"
    fi
  fi

  if [ "$os" = Darwin ]; then
    gvimrc="$HOME/.gvimrc"
    if [ -f "$gvimrc" ]; then
      log "Configuring MacVim (.gvimrc)"
      escaped_family=$(printf '%s' "$family" | sed 's/ /\\ /g')
      if grep -q '^set guifont=' "$gvimrc"; then
        sed -i.bak "s/^set guifont=.*/set guifont=$escaped_family:h$font_size_editor/" "$gvimrc"
      else
        printf '\nset guifont=%s:h%s\n' "$escaped_family" "$font_size_editor" >> "$gvimrc"
      fi
    fi
  fi

  vimrc="$HOME/.vimrc"
  if [ -f "$vimrc" ]; then
    log "Configuring Vim (.vimrc guifont)"
    escaped_family=$(printf '%s' "$family" | sed 's/ /\\ /g')
    if grep -q '^set guifont=' "$vimrc"; then
      sed -i.bak "s/^set guifont=.*/set guifont=$escaped_family:h$font_size_editor/" "$vimrc"
    elif grep -q '^" === Core Settings ===' "$vimrc"; then
      sed -i.bak "/^\" === Core Settings ===/a\\
set guifont=$escaped_family:h$font_size_editor" "$vimrc"
    else
      printf '\nset guifont=%s:h%s\n' "$escaped_family" "$font_size_editor" >> "$vimrc"
    fi
  fi

  nvim_init="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
  if [ -f "$nvim_init" ]; then
    log "Configuring Neovim (init.lua)"
    sed -i.bak \
      -e "s/vim\.opt\.guifont = .*/vim.opt.guifont = '$family:h$font_size_editor'/" \
      -e "s/vim\.o\.guifont = .*/vim.o.guifont = \"$family:h$font_size_editor\"/" \
      "$nvim_init"
  fi

  if [ "$os" = Darwin ]; then
    xcode_theme_source="/Applications/Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/Versions/A/Resources/FontAndColorThemes/Default (Dark).xccolortheme"
    xcode_theme_dir="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"
    xcode_theme_name="Berka Mono"
    xcode_theme="$xcode_theme_dir/$xcode_theme_name.xccolortheme"
    if [ -f "$xcode_theme_source" ] && command -v python3 >/dev/null 2>&1; then
      log "Configuring Xcode"
      mkdir -p "$xcode_theme_dir"
      cp "$xcode_theme_source" "$xcode_theme"
      python3 - "$xcode_theme" "$xcode_font" "$font_size_editor" <<'PY'
import plistlib
import sys

path, font_name, font_size = sys.argv[1], sys.argv[2], sys.argv[3]
font_value = f"{font_name} - {float(font_size):.1f}"

with open(path, "rb") as handle:
    theme = plistlib.load(handle)

for key in list(theme):
    if key.endswith("TextFont") or key == "DVTMarkupTextCodeFont":
        theme[key] = font_value

syntax_fonts = theme.get("DVTSourceTextSyntaxFonts")
if isinstance(syntax_fonts, dict):
    for key in list(syntax_fonts):
        syntax_fonts[key] = font_value

with open(path, "wb") as handle:
    plistlib.dump(theme, handle, sort_keys=False)
PY
      defaults write com.apple.dt.Xcode XCFontAndColorCurrentTheme "$xcode_theme_name"
      defaults write com.apple.dt.Xcode XCFontAndColorCurrentDarkTheme "$xcode_theme_name"
    fi
  fi

  if [ "$os" = Linux ] && command -v gsettings >/dev/null 2>&1; then
    log "Configuring GNOME Terminal if a default profile exists"
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'") || profile=""
    if [ -n "$profile" ]; then
      base="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
      gsettings set "$base" use-system-font false >/dev/null 2>&1 || true
      gsettings set "$base" font "$family 13" >/dev/null 2>&1 || true
    fi
  fi
}

configure_windows_apps() {
  family="$1"
  set_step "Configuring Windows apps for $family"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "\$ErrorActionPreference='Stop'; \$family='$family'; function Set-Json(\$Path,\$Kind){ \$dir=Split-Path \$Path; New-Item -ItemType Directory -Force -Path \$dir | Out-Null; if(Test-Path \$Path){ try{ \$json=Get-Content \$Path -Raw | ConvertFrom-Json } catch { Rename-Item \$Path (\$Path + '.berka.bak') -Force; \$json=[pscustomobject]@{} } } else { \$json=[pscustomobject]@{} }; if(\$Kind -eq 'vscode'){ \$json | Add-Member -Force NoteProperty 'editor.fontFamily' (\"'\$family', monospace\"); \$json | Add-Member -Force NoteProperty 'editor.fontLigatures' \$true; \$json | Add-Member -Force NoteProperty 'terminal.integrated.fontFamily' \$family } elseif(\$Kind -eq 'terminal'){ if(-not \$json.profiles){ \$json | Add-Member -Force NoteProperty profiles ([pscustomobject]@{}) }; if(-not \$json.profiles.defaults){ \$json.profiles | Add-Member -Force NoteProperty defaults ([pscustomobject]@{}) }; \$json.profiles.defaults | Add-Member -Force NoteProperty font ([pscustomobject]@{ face = \$family }) }; \$json | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 \$Path }; function Set-JetBrainsXml(\$Path,\$ComponentName,\$Values){ \$dir=Split-Path \$Path; New-Item -ItemType Directory -Force -Path \$dir | Out-Null; if(Test-Path \$Path){ [xml]\$xml=Get-Content \$Path -Raw; if(\$xml.DocumentElement.Name -ne 'application'){ return } } else { \$xml=New-Object System.Xml.XmlDocument; \$xml.AppendChild(\$xml.CreateElement('application')) | Out-Null }; \$app=\$xml.DocumentElement; \$component=\$app.SelectSingleNode(\"component[@name='\$ComponentName']\"); if(-not \$component){ \$component=\$xml.CreateElement('component'); \$component.SetAttribute('name', \$ComponentName); \$app.AppendChild(\$component) | Out-Null }; foreach(\$name in \$Values.Keys){ \$option=\$component.SelectSingleNode(\"option[@name='\$name']\"); if(-not \$option){ \$option=\$xml.CreateElement('option'); \$option.SetAttribute('name', \$name); \$component.AppendChild(\$option) | Out-Null }; \$option.SetAttribute('value', [string]\$Values[\$name]) }; \$xml.Save(\$Path) }; function Set-JetBrains(\$Root){ if(-not (Test-Path \$Root)){ return }; Get-ChildItem \$Root -Directory | ForEach-Object { foreach(\$rel in @('options','settingsSync\options')){ \$options=Join-Path \$_.FullName \$rel; if(Test-Path \$options){ Set-JetBrainsXml (Join-Path \$options 'editor.xml') 'DefaultFont' @{ FONT_FAMILY = \$family }; Set-JetBrainsXml (Join-Path \$options 'editor-font.xml') 'EditorFont' @{ FONT_FAMILY = \$family; FONT_LIGATURES = 'true' }; Set-JetBrainsXml (Join-Path \$options 'console-font.xml') 'ConsoleFont' @{ FONT_FAMILY = \$family; USE_LIGATURES = 'true' }; Set-JetBrainsXml (Join-Path \$options 'terminal-font.xml') 'TerminalFontOptions' @{ FONT_FAMILY = \$family; USE_LIGATURES = 'true' } } } } }; Set-Json (Join-Path \$env:APPDATA 'Code\User\settings.json') vscode; Set-Json (Join-Path \$env:APPDATA 'Cursor\User\settings.json') vscode; Set-Json (Join-Path \$env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json') terminal; Set-JetBrains (Join-Path \$env:APPDATA 'JetBrains'); Write-Host 'Configured VS Code, Cursor, JetBrains IDEs, and Windows Terminal.'"
}

key=$(select_family)
configured_family=$(family_name "$key")
configured_xcode_font=$(family_xcode_name "$key")
download_dir="${TMPDIR:-/tmp}/berka-fonts-$$"
trap cleanup 0
trap interrupted INT TERM
log "Selected $configured_family."
log "Using branch $branch from github.com/$repo."
need curl

for item in $families; do
  download_family "$item" "$download_dir"
done

uname_s=$(uname -s 2>/dev/null || printf Windows)
log "Detected platform: $uname_s"
case "$uname_s" in
  Darwin|Linux)
    install_fonts_unix "$uname_s" "$download_dir"
    configure_unix_apps "$uname_s" "$configured_family" "$configured_xcode_font"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    install_fonts_windows "$download_dir"
    configure_windows_apps "$configured_family"
    ;;
  *)
    die "Unsupported platform: $uname_s"
    ;;
esac

current_step="done"
log "Configured IDEs and terminals to use $configured_family."
