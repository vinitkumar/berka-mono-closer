#!/usr/bin/env python3
"""Verify the Berka Mono Plain contract on the checked-in TTF files.

Checks, per file:
  1. No ligature features (calt, liga, clig, dlig) and no cv##/ss## toggles.
  2. Every non-empty glyph advance equals the cell width (strict monospace).
  3. Every audited operator sequence shapes to one glyph per character.

Requires fontTools and the HarfBuzz `hb-shape` CLI.
"""
import glob
import os
import subprocess
import sys

from fontTools.ttLib import TTFont

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_GLOB = os.path.join(REPO_DIR, "fonts", "ttf-plain", "*.ttf")
CELL_WIDTH = 590
FORBIDDEN_FEATURES = {"calt", "liga", "clig", "dlig"}

# Sequences that ligate in Instrument. Plain must leave every one of them alone.
SEQUENCES = [
    "->", "<-", "=>", "<=", ">=", "!=", "!==", "==", "===", "::", ":::",
    "<>", "<->", "<=>", "-->", "<--", "==>", "<==", "|>", "<|", "<|>",
    "||", "&&", "++", "--", "**", "//", "/*", "*/", "/=", "//=",
    "<<", ">>", "<<<", ">>>", "..", "...", "..<", ":=", "=:=",
    "{|", "|}", "[|", "|]", "<$>", "<*>", "<+>", "~>", "<~", "~~", "~~~",
    "##", "###", "__", "?.", "??", "?:", "<!--", "-->", "%%",
]


def font_features(font):
    if "GSUB" not in font:
        return set()

    return {rec.FeatureTag for rec in font["GSUB"].table.FeatureList.FeatureRecord}


def check_features(font):
    feats = font_features(font)
    bad = sorted(feats & FORBIDDEN_FEATURES)
    bad += sorted(t for t in feats if t[:2] in ("cv", "ss"))
    return [f"forbidden feature {tag}" for tag in bad]


def check_widths(font):
    hmtx = font["hmtx"]
    widths = {hmtx[name][0] for name in font.getGlyphOrder()}
    widths.discard(0)
    if widths == {CELL_WIDTH}:
        return []

    return [f"glyph advances {sorted(widths)} != [{CELL_WIDTH}]"]


def shaped_glyph_count(path, text):
    out = subprocess.run(
        ["hb-shape", "--no-glyph-names", "--no-positions", "--no-clusters", f"--text={text}", path],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    return len(out.strip("[]").split("|"))


def check_sequences(path):
    problems = []
    for seq in SEQUENCES:
        count = shaped_glyph_count(path, seq)
        if count != len(seq):
            problems.append(f"sequence {seq!r} shaped to {count} glyphs")

    return problems


def main():
    paths = sorted(glob.glob(FONT_GLOB))
    if not paths:
        print(f"no fonts found at {FONT_GLOB}", file=sys.stderr)
        return 1

    failed = False
    for path in paths:
        font = TTFont(path)
        problems = check_features(font) + check_widths(font) + check_sequences(path)
        name = os.path.basename(path)
        if problems:
            failed = True
            print(f"FAIL {name}")
            for problem in problems:
                print(f"  {problem}")
            continue

        print(f"ok   {name}")

    print(f"checked {len(paths)} files, {len(SEQUENCES)} sequences each")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
