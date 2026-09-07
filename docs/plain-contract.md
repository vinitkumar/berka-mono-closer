# Berka Mono Plain Contract

Berka Mono Plain is Berka Mono Instrument with all contextual shaping removed.
It exists for places where ligatures get in the way: terminals, diff and merge
tools, pair-programming screens, teaching material, and editors that either
lack ligature support or render it inconsistently.

## Guarantees

Every file in `fonts/ttf-plain/` satisfies these checks:

1. The `GSUB` table contains no `calt`, `liga`, `clig`, or `dlig` feature, and
   no `cv##` or `ss##` feature.
2. Every glyph with a non-zero advance is exactly 590 units wide. There are no
   double-width glyphs, which is what fontconfig requires to classify a font as
   monospace.
3. Every audited operator sequence shapes to one glyph per character under
   HarfBuzz with default features.

Run the check:

```sh
python3 scripts/check-plain.py
```

Requirements: `fonttools` and the HarfBuzz `hb-shape` CLI (`brew install
harfbuzz` on macOS).

## Relationship To Instrument

| Property | Instrument | Plain |
| --- | ---: | ---: |
| Cell width | 590 | 590 |
| Weights (shape) | 420, 460, 520, 615, 705 | same |
| Leading | 1165 | 1165 |
| Italic | oblique 6° | oblique 9° |
| Glyph shapes | Berka set | same, except `g`, `r`, `#`, and dots |
| Ligatures | expanded `calt` | none |
| `cv##` / `ss##` | yes | no |
| Glyph count | 46,821 | 8,785 |
| Regular TTF | ~10 MB | ~1.4 MB |
| Regular WOFF2 | ~1.6 MB | ~360 KB |

Because the metrics match, switching an editor between the two families never
changes line wrapping or column alignment.

## What Was Dropped

- The double-width long arrows and tacks (`U+27DD`, `U+27DE`,
  `U+27F5`..`U+27FF`, `U+2B33`, `U+1F8D0`..`U+1F8D8`). Iosevka removes them
  under `spacing = "fixed"` because they cannot fit one cell.
- The `NWID` and `WWID` width-selection features, which only matter when
  double-width glyphs exist.
- Exported glyph names. They are only needed for ligature support in Kitty.

## Deliberate Choices

- Square dots (`punctuation-dot`, `tittle`, `diacritic-dot`). Round dots blur
  into grey blobs at 11px to 13px on non-Retina displays; square dots land on
  whole pixels and match the rectangular Berka voice.
- `periodSize` raised 10% over Iosevka's weight curve. Without ligatures,
  `.` `,` `:` `;` are the whole signal in `a.b.c` and `x::y`, and the default
  period is a single grey pixel at 12px.
- `g = "single-storey-serifless"`. The double-storey `g` collapses at 13px
  because two bowls share about nine pixels. `g` and `q` stay distinct: `q`
  keeps a straight stem, `g` has a hook.
- `r = "hookless-base-serifed"`. The base serif fills the right of the cell
  and puts a visible gap before a following `n`, so `rn` does not read as `m`.
- `number-sign = "upright-open"`. Upright strokes land on the pixel grid.
- Italic angle 9° instead of Instrument's 6°. Six degrees is barely detectable
  at 12px, so comments stopped looking italic.
- Kept after testing: low `~` and low `*` are already centred on the operator
  axis (the "high" variants sit at cap height), and x-height stays at 520 (see
  below).
- Straight `'` and `` ` ``, low `~`, upright `|` in italic, high `_`. These
  are the Instrument choices and matter more without ligatures, because each
  character has to be recognisable on its own.

## Tested And Rejected

- `xHeight = 540`. Built as a Regular-only trial and compared with 520 at
  12px and 13px. Twenty units is a quarter of a pixel at 13px and rounds
  away, so the lowercase does not get taller on screen, while the ascender
  gap on `b h l d` and the `1Il` set visibly shrinks. Not worth it.
- `tilde = "high"` and `asterisk = "penta-mid"`. The low tilde and low
  asterisk already sit on the operator axis next to `-` and `=`; the high
  tilde is at cap height like a diacritic.
- Leading 1200. Plain would stop being a metric drop-in for Instrument.
