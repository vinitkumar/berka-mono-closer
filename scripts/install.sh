#!/usr/bin/env sh
set -eu

repo="vinitkumar/berka-mono-closer"
branch="${BERKA_BRANCH:-main}"
raw_base="https://raw.githubusercontent.com/$repo/$branch"

families='closer compact semi-condensed control retina'
choice="${1:-${BERKA_FONT:-}}"

family_name() {
  case "$1" in
    closer) printf '%s\n' "Berka Mono Closer" ;;
    compact) printf '%s\n' "Berka Mono Closer Compact" ;;
    semi-condensed|semicondensed|semi) printf '%s\n' "Berka Mono Closer SemiCondensed" ;;
    control) printf '%s\n' "Berka Mono Control" ;;
    retina) printf '%s\n' "Berka Mono Retina" ;;
    *) return 1 ;;
  esac
}

family_dir() {
  case "$1" in
    closer) printf '%s\n' "fonts/ttf" ;;
    compact) printf '%s\n' "fonts/ttf-compact" ;;
    semi-condensed|semicondensed|semi) printf '%s\n' "fonts/ttf-semi-condensed" ;;
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
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

select_family() {
  if [ -n "$choice" ]; then
    family_name "$choice" >/dev/null || {
      printf 'Unknown Berka font "%s". Use one of: %s\n' "$choice" "$families" >&2
      exit 1
    }
    printf '%s\n' "$choice"
    return
  fi

  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    printf 'Choose the Berka font to configure:\n' > /dev/tty
    printf '  1) Berka Mono Closer\n' > /dev/tty
    printf '  2) Berka Mono Closer Compact\n' > /dev/tty
    printf '  3) Berka Mono Closer SemiCondensed\n' > /dev/tty
    printf '  4) Berka Mono Control\n' > /dev/tty
    printf '  5) Berka Mono Retina\n' > /dev/tty
    printf 'Selection [1]: ' > /dev/tty
    read -r answer < /dev/tty
    case "${answer:-1}" in
      1) printf '%s\n' closer ;;
      2) printf '%s\n' compact ;;
      3) printf '%s\n' semi-condensed ;;
      4) printf '%s\n' control ;;
      5) printf '%s\n' retina ;;
      *) printf 'Invalid selection: %s\n' "$answer" >&2; exit 1 ;;
    esac
  else
    printf '%s\n' closer
  fi
}

download_family() {
  key="$1"
  dest="$2"
  dir=$(family_dir "$key")
  mkdir -p "$dest"
  for file in $(family_files "$key"); do
    curl -fsSL "$raw_base/$dir/$file" -o "$dest/$file"
  done
}

install_fonts_unix() {
  os="$1"
  src="$2"
  case "$os" in
    Darwin) font_dir="$HOME/Library/Fonts" ;;
    Linux) font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    *) printf 'Unsupported Unix platform: %s\n' "$os" >&2; exit 1 ;;
  esac
  mkdir -p "$font_dir"
  find "$font_dir" -maxdepth 1 -type f \( -name "BerkaMonoCloser*.ttf" -o -name "BerkaMonoControl*.ttf" -o -name "BerkaMonoRetina*.ttf" \) -delete
  cp "$src"/*.ttf "$font_dir"/
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi
  printf 'Installed Berka fonts into %s\n' "$font_dir"
}

install_fonts_windows() {
  src="$1"
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
  mkdir -p "$(dirname "$file")"
  python3 - "$file" "$family" "$mode" <<'PY'
import json
import os
import sys

path, family, mode = sys.argv[1:4]
data = {}
if os.path.exists(path) and os.path.getsize(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except json.JSONDecodeError:
        os.replace(path, path + ".berka.bak")
        data = {}

if mode == "vscode":
    data["editor.fontFamily"] = f"'{family}', monospace"
    data["editor.fontLigatures"] = True
    data["terminal.integrated.fontFamily"] = family
elif mode == "zed":
    data["buffer_font_family"] = family
    data["buffer_font_features"] = {"calt": True, "liga": True}
    terminal = data.get("terminal") if isinstance(data.get("terminal"), dict) else {}
    terminal["font_family"] = family
    data["terminal"] = terminal

tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
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
    "editor.xml": ("DefaultFont", {"FONT_FAMILY": family}),
    "editor-font.xml": (
        "EditorFont",
        {"FONT_FAMILY": family, "FONT_LIGATURES": "true"},
    ),
    "console-font.xml": (
        "ConsoleFont",
        {"FONT_FAMILY": family, "USE_LIGATURES": "true"},
    ),
    "terminal-font.xml": (
        "TerminalFontOptions",
        {"FONT_FAMILY": family, "USE_LIGATURES": "true"},
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

configure_unix_apps() {
  os="$1"
  family="$2"
  if command -v python3 >/dev/null 2>&1; then
    case "$os" in
      Darwin)
        json_set_unix "$HOME/Library/Application Support/Code/User/settings.json" "$family" vscode
        json_set_unix "$HOME/Library/Application Support/Cursor/User/settings.json" "$family" vscode
        ;;
      Linux)
        json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json" "$family" vscode
        json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json" "$family" vscode
        ;;
    esac
    json_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/zed/settings.json" "$family" zed
    case "$os" in
      Darwin) jetbrains_xml_set_unix "$HOME/Library/Application Support/JetBrains" "$family" ;;
      Linux) jetbrains_xml_set_unix "${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains" "$family" ;;
    esac
  else
    printf 'python3 not found; skipped VS Code, Cursor, Zed, and JetBrains settings.\n'
  fi

  configure_text_file "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf" "# Berka Mono Closer begin" "# Berka Mono Closer end" "font_family      family=\"$family\"
bold_font        family=\"$family\" style=\"Bold\"
italic_font      family=\"$family\" style=\"Italic\"
bold_italic_font family=\"$family\" style=\"Bold Italic\"
disable_ligatures never"

  ghostty_file="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
  [ "$os" = Darwin ] && ghostty_file="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  configure_text_file "$ghostty_file" "# Berka Mono Closer begin" "# Berka Mono Closer end" "font-family = \"$family\"
font-family-bold = \"$family\"
font-family-italic = \"$family\"
font-family-bold-italic = \"$family\"
font-feature = liga
font-feature = calt
font-feature = clig"

  configure_text_file "${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml" "# Berka Mono Closer begin" "# Berka Mono Closer end" "[font]
normal = { family = \"$family\", style = \"Regular\" }
bold = { family = \"$family\", style = \"Bold\" }
italic = { family = \"$family\", style = \"Italic\" }
bold_italic = { family = \"$family\", style = \"Bold Italic\" }"

  if [ "$os" = Linux ] && command -v gsettings >/dev/null 2>&1; then
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
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "\$ErrorActionPreference='Stop'; \$family='$family'; function Set-Json(\$Path,\$Kind){ \$dir=Split-Path \$Path; New-Item -ItemType Directory -Force -Path \$dir | Out-Null; if(Test-Path \$Path){ try{ \$json=Get-Content \$Path -Raw | ConvertFrom-Json } catch { Rename-Item \$Path (\$Path + '.berka.bak') -Force; \$json=[pscustomobject]@{} } } else { \$json=[pscustomobject]@{} }; if(\$Kind -eq 'vscode'){ \$json | Add-Member -Force NoteProperty 'editor.fontFamily' (\"'\$family', monospace\"); \$json | Add-Member -Force NoteProperty 'editor.fontLigatures' \$true; \$json | Add-Member -Force NoteProperty 'terminal.integrated.fontFamily' \$family } elseif(\$Kind -eq 'terminal'){ if(-not \$json.profiles){ \$json | Add-Member -Force NoteProperty profiles ([pscustomobject]@{}) }; if(-not \$json.profiles.defaults){ \$json.profiles | Add-Member -Force NoteProperty defaults ([pscustomobject]@{}) }; \$json.profiles.defaults | Add-Member -Force NoteProperty font ([pscustomobject]@{ face = \$family }) }; \$json | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 \$Path }; function Set-JetBrainsXml(\$Path,\$ComponentName,\$Values){ \$dir=Split-Path \$Path; New-Item -ItemType Directory -Force -Path \$dir | Out-Null; if(Test-Path \$Path){ [xml]\$xml=Get-Content \$Path -Raw; if(\$xml.DocumentElement.Name -ne 'application'){ return } } else { \$xml=New-Object System.Xml.XmlDocument; \$xml.AppendChild(\$xml.CreateElement('application')) | Out-Null }; \$app=\$xml.DocumentElement; \$component=\$app.SelectSingleNode(\"component[@name='\$ComponentName']\"); if(-not \$component){ \$component=\$xml.CreateElement('component'); \$component.SetAttribute('name', \$ComponentName); \$app.AppendChild(\$component) | Out-Null }; foreach(\$name in \$Values.Keys){ \$option=\$component.SelectSingleNode(\"option[@name='\$name']\"); if(-not \$option){ \$option=\$xml.CreateElement('option'); \$option.SetAttribute('name', \$name); \$component.AppendChild(\$option) | Out-Null }; \$option.SetAttribute('value', [string]\$Values[\$name]) }; \$xml.Save(\$Path) }; function Set-JetBrains(\$Root){ if(-not (Test-Path \$Root)){ return }; Get-ChildItem \$Root -Directory | ForEach-Object { foreach(\$rel in @('options','settingsSync\options')){ \$options=Join-Path \$_.FullName \$rel; if(Test-Path \$options){ Set-JetBrainsXml (Join-Path \$options 'editor.xml') 'DefaultFont' @{ FONT_FAMILY = \$family }; Set-JetBrainsXml (Join-Path \$options 'editor-font.xml') 'EditorFont' @{ FONT_FAMILY = \$family; FONT_LIGATURES = 'true' }; Set-JetBrainsXml (Join-Path \$options 'console-font.xml') 'ConsoleFont' @{ FONT_FAMILY = \$family; USE_LIGATURES = 'true' }; Set-JetBrainsXml (Join-Path \$options 'terminal-font.xml') 'TerminalFontOptions' @{ FONT_FAMILY = \$family; USE_LIGATURES = 'true' } } } } }; Set-Json (Join-Path \$env:APPDATA 'Code\User\settings.json') vscode; Set-Json (Join-Path \$env:APPDATA 'Cursor\User\settings.json') vscode; Set-Json (Join-Path \$env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json') terminal; Set-JetBrains (Join-Path \$env:APPDATA 'JetBrains'); Write-Host 'Configured VS Code, Cursor, JetBrains IDEs, and Windows Terminal.'"
}

key=$(select_family)
configured_family=$(family_name "$key")
tmp="${TMPDIR:-/tmp}/berka-fonts-$$"
trap 'rm -rf "$tmp"' EXIT INT TERM
need curl

for item in $families; do
  download_family "$item" "$tmp"
done

uname_s=$(uname -s 2>/dev/null || printf Windows)
case "$uname_s" in
  Darwin|Linux)
    install_fonts_unix "$uname_s" "$tmp"
    configure_unix_apps "$uname_s" "$configured_family"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    install_fonts_windows "$tmp"
    configure_windows_apps "$configured_family"
    ;;
  *)
    printf 'Unsupported platform: %s\n' "$uname_s" >&2
    exit 1
    ;;
esac

printf 'Configured IDEs and terminals to use %s.\n' "$configured_family"
