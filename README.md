# Berka Mono Closer

Berka Mono Closer is a custom build of [Iosevka](https://github.com/be5invis/Iosevka) tuned for a calm, wide, rectangular coding-font feel.

The repository includes seven families. They share the same core upright glyph
design, so the visual difference between cuts is intentionally modest. The real
differences are in width, weight, leading, italic construction, and ligature
policy:

| Family | Cell width | Weights | Leading | Italic | Ligature policy |
| --- | ---: | --- | ---: | --- | --- |
| `Berka Mono Closer` | 620 | 400, 500, 600, 700 | 1200 | italic | disables `arrow-wave`, `counter-arrow-wave`, `html-comment`, `trig` |
| `Berka Mono Closer Compact` | 605 | 400, 500, 600, 700 | 1200 | italic | same disables as Closer |
| `Berka Mono Closer SemiCondensed` | 585 | 400, 500, 600, 700 | 1200 | italic | same disables as Closer |
| `Berka Mono Closer Narrow` | 520 | 400, 500, 600, 700 | 1180 | italic | same disables as Closer |
| `Berka Mono Control` | 595 | 400, 450, 500, 600, 700 | 1180 | oblique | full Iosevka `default-calt` |
| `Berka Mono Retina` | 605 | 430, 470, 530, 630, 730 | 1180 | oblique | full Iosevka `default-calt` |
| `Berka Mono Focus` | 592 | 425, 465, 525, 620, 710 | 1170 | oblique | debugging-first `default-calt` subset |

It is built only from Iosevka's open source build system and variant parameters. It does not contain proprietary outlines, copied glyphs, or commercial font files.

![Berka Mono Closer dark specimen](images/specimen-dark.png)

![Berka Mono Closer light specimen](images/specimen-light.png)

![Berka Mono Closer Compact comparison](images/compact-comparison.png)

![Berka Mono Closer SemiCondensed specimen](images/semi-condensed-specimen.png)

![Berka Mono Closer Narrow specimen](images/narrow-specimen.png)

![Berka Mono Control specimen](images/control-specimen.png)

![Berka Mono Retina specimen](images/retina-specimen.png)

![Berka Mono Focus specimen](images/focus-specimen.png)

## Download

## Install

Install every Berka TTF family and configure your editor and terminal to use one selected family:

```sh
curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh
```

Use a specific family non-interactively:

```sh
curl -fsSL https://raw.githubusercontent.com/vinitkumar/berka-mono-closer/main/scripts/install.sh | sh -s -- retina
```

Available choices:

```text
closer
compact
semi-condensed
narrow
control
retina
focus
```

The installer supports macOS, Linux, and Windows through Git Bash/MSYS/Cygwin. It installs the fonts and configures VS Code, Cursor, JetBrains IDEs, Zed, Ghostty, Kitty, Alacritty, Windows Terminal, and GNOME Terminal when their config locations are present.

Try the fonts in the browser at:

```text
https://vinitkumar.github.io/berka-mono-closer/
```

## Manual Download

Install the TTF files from:

```text
fonts/ttf/
fonts/ttf-compact/
fonts/ttf-semi-condensed/
fonts/ttf-narrow/
fonts/ttf-control/
fonts/ttf-retina/
fonts/ttf-focus/
```

Use the WOFF2 files for websites:

```text
fonts/woff2/
fonts/woff2-compact/
fonts/woff2-semi-condensed/
fonts/woff2-narrow/
fonts/woff2-control/
fonts/woff2-retina/
fonts/woff2-focus/
```

On macOS, you can copy them into `~/Library/Fonts` manually:

```sh
./scripts/install-macos.sh
```

Use this font family name in editors and terminals:

```text
Berka Mono Closer
Berka Mono Closer Compact
Berka Mono Closer SemiCondensed
Berka Mono Closer Narrow
Berka Mono Control
Berka Mono Retina
Berka Mono Focus
```

## VS Code

After installing the TTF files, open `settings.json` with `Preferences: Open User Settings (JSON)` and add:

```json
{
  "editor.fontFamily": "'Berka Mono Closer', monospace",
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "'Berka Mono Closer'"
}
```

For Compact, SemiCondensed, Narrow, Control, Retina, or Focus, replace `Berka Mono Closer` with the matching family name from the Download section.

## Cursor

Cursor uses VS Code-compatible settings. After installing the TTF files, open `settings.json` with `Preferences: Open User Settings (JSON)` and add:

```json
{
  "editor.fontFamily": "'Berka Mono Closer', monospace",
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "'Berka Mono Closer'"
}
```

You can also import existing VS Code settings from Cursor Settings if you already configured the font in VS Code.

## Zed

After installing the TTF files, open Zed settings and add:

```json
{
  "buffer_font_family": "Berka Mono Closer",
  "buffer_font_features": {
    "calt": true,
    "liga": true
  },
  "terminal": {
    "font_family": "Berka Mono Closer"
  }
}
```

For Compact, SemiCondensed, Narrow, Control, Retina, or Focus, replace `Berka Mono Closer` with the matching family name from the Download section.

## Styles

- Regular
- Italic
- Medium
- Medium Italic
- SemiBold
- SemiBold Italic
- Bold
- Bold Italic

`Berka Mono Control`, `Berka Mono Retina`, and `Berka Mono Focus` also include Book and Book Italic.

## Ligatures

Programming ligatures are enabled through Iosevka's `default-calt` set.

Closer, Compact, SemiCondensed, and Narrow intentionally disable a few more decorative groups:

- `arrow-wave`
- `counter-arrow-wave`
- `html-comment`
- `trig`

Control and Retina keep the full `default-calt` set for broader language and markup coverage.

Focus is the recommended everyday coding cut. It keeps useful operator ligatures
but disables decorative wave arrows, HTML comment ligatures, trig ligatures, and
tilde chaining so raw source stays easy to inspect. It also uses a dotted zero,
a flat-top `1`, a high underscore for `snake_case`, larger parentheses, and
curly-flat braces for nested code.

## Ghostty

```conf
font-family = "Berka Mono Closer"
font-family-bold = "Berka Mono Closer"
font-family-italic = "Berka Mono Closer"
font-family-bold-italic = "Berka Mono Closer"
font-size = 15
font-feature = liga
font-feature = calt
font-feature = clig
font-thicken = true
```

Full example: [examples/ghostty.conf](examples/ghostty.conf)

For Compact, replace the family name with:

```conf
font-family = "Berka Mono Closer Compact"
font-family-bold = "Berka Mono Closer Compact"
font-family-italic = "Berka Mono Closer Compact"
font-family-bold-italic = "Berka Mono Closer Compact"
```

For SemiCondensed, replace the family name with:

```conf
font-family = "Berka Mono Closer SemiCondensed"
font-family-bold = "Berka Mono Closer SemiCondensed"
font-family-italic = "Berka Mono Closer SemiCondensed"
font-family-bold-italic = "Berka Mono Closer SemiCondensed"
```

For Narrow, replace the family name with:

```conf
font-family = "Berka Mono Closer Narrow"
font-family-bold = "Berka Mono Closer Narrow"
font-family-italic = "Berka Mono Closer Narrow"
font-family-bold-italic = "Berka Mono Closer Narrow"
```

For Control, replace the family name with:

```conf
font-family = "Berka Mono Control"
font-family-bold = "Berka Mono Control"
font-family-italic = "Berka Mono Control"
font-family-bold-italic = "Berka Mono Control"
```

For Retina, replace the family name with:

```conf
font-family = "Berka Mono Retina"
font-family-bold = "Berka Mono Retina"
font-family-italic = "Berka Mono Retina"
font-family-bold-italic = "Berka Mono Retina"
```

For Focus, replace the family name with:

```conf
font-family = "Berka Mono Focus"
font-family-bold = "Berka Mono Focus"
font-family-italic = "Berka Mono Focus"
font-family-bold-italic = "Berka Mono Focus"
```

## Kitty

```conf
font_family      family="Berka Mono Closer"
bold_font        family="Berka Mono Closer" style="Bold"
italic_font      family="Berka Mono Closer" style="Italic"
bold_italic_font family="Berka Mono Closer" style="Bold Italic"
font_size        15.0
disable_ligatures never
```

Full example: [examples/kitty.conf](examples/kitty.conf)

For Compact, replace the family name with:

```conf
font_family      family="Berka Mono Closer Compact"
bold_font        family="Berka Mono Closer Compact" style="Bold"
italic_font      family="Berka Mono Closer Compact" style="Italic"
bold_italic_font family="Berka Mono Closer Compact" style="Bold Italic"
```

For SemiCondensed, replace the family name with:

```conf
font_family      family="Berka Mono Closer SemiCondensed"
bold_font        family="Berka Mono Closer SemiCondensed" style="Bold"
italic_font      family="Berka Mono Closer SemiCondensed" style="Italic"
bold_italic_font family="Berka Mono Closer SemiCondensed" style="Bold Italic"
```

For Narrow, replace the family name with:

```conf
font_family      family="Berka Mono Closer Narrow"
bold_font        family="Berka Mono Closer Narrow" style="Bold"
italic_font      family="Berka Mono Closer Narrow" style="Italic"
bold_italic_font family="Berka Mono Closer Narrow" style="Bold Italic"
```

For Control, replace the family name with:

```conf
font_family      family="Berka Mono Control"
bold_font        family="Berka Mono Control" style="Bold"
italic_font      family="Berka Mono Control" style="Italic"
bold_italic_font family="Berka Mono Control" style="Bold Italic"
```

For Retina, replace the family name with:

```conf
font_family      family="Berka Mono Retina"
bold_font        family="Berka Mono Retina" style="Bold"
italic_font      family="Berka Mono Retina" style="Italic"
bold_italic_font family="Berka Mono Retina" style="Bold Italic"
```

For Focus, replace the family name with:

```conf
font_family      family="Berka Mono Focus"
bold_font        family="Berka Mono Focus" style="Bold"
italic_font      family="Berka Mono Focus" style="Italic"
bold_italic_font family="Berka Mono Focus" style="Bold Italic"
```

## Build From Source

Requirements:

- Node.js 16 or newer
- npm
- `ttfautohint`
- Python 3 with `fonttools` for WOFF2 generation
- git

On macOS:

```sh
brew install ttfautohint
```

Build:

```sh
git clone --depth 1 https://github.com/be5invis/Iosevka.git
cd Iosevka
cp /path/to/berka-mono-closer/sources/private-build-plans.toml ./private-build-plans.toml
npm install
npm run build -- ttf::BerkaMonoCloser --jCmd=2
cp /path/to/berka-mono-closer/sources/compact/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoCloserCompact --jCmd=2
cp /path/to/berka-mono-closer/sources/semi-condensed/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoCloserSemiCondensed --jCmd=2
cp /path/to/berka-mono-closer/sources/narrow/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoCloserNarrow --jCmd=2
cp /path/to/berka-mono-closer/sources/control/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoControl --jCmd=2
cp /path/to/berka-mono-closer/sources/retina/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoRetina --jCmd=2
cp /path/to/berka-mono-closer/sources/focus/private-build-plans.toml ./private-build-plans.toml
npm run build -- ttf::BerkaMonoFocus --jCmd=2
```

The generated files will be in:

```text
dist/BerkaMonoCloser/TTF/
dist/BerkaMonoCloserCompact/TTF/
dist/BerkaMonoCloserSemiCondensed/TTF/
dist/BerkaMonoCloserNarrow/TTF/
dist/BerkaMonoControl/TTF/
dist/BerkaMonoRetina/TTF/
dist/BerkaMonoFocus/TTF/
```

You can also run:

```sh
./scripts/build.sh /path/to/Iosevka
```

The script copies each family-specific build plan before building that family, including `sources/narrow/private-build-plans.toml` for `Berka Mono Closer Narrow`, `sources/retina/private-build-plans.toml` for `Berka Mono Retina`, and `sources/focus/private-build-plans.toml` for `Berka Mono Focus`.

Generate WOFF2 files from the checked-in TTF files:

```sh
./scripts/build-woff2.sh
```

## Legal Notes

Berka Mono Closer is a modified build of Iosevka and is distributed under the SIL Open Font License 1.1, matching Iosevka's license.

What makes this legal:

- The source is Iosevka, an OFL-licensed font project.
- The font is generated from Iosevka's documented custom build configuration.
- The name is changed to `Berka Mono Closer`, so it does not use Iosevka's reserved font name as the primary family name.
- No commercial font software, outlines, metrics files, or binaries are included.
- The design goal is a general visual direction: calm, wide, rectangular, readable coding text. It is not a clone of any proprietary font.
- The Control variant is guided by public high-level design language from a datasheet, but it is generated only from Iosevka source and documented custom-build parameters.
- The Focus variant is an original coding-readability tuning built from Iosevka parameters for ambiguity reduction, compact scan density, and restrained ligatures.

This project is not affiliated with, endorsed by, or derived from Berkeley Mono or US Graphics Company. Berkeley Mono is a separate commercial font.

## License

Licensed under the SIL Open Font License 1.1. See [LICENSE](LICENSE).
