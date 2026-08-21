# Berka Mono Instrument Ligature Audit

This audit checks Berka Mono Instrument against a programming-sequence catalog
derived from public TX-02 datasheet examples. It is not a TX-02 clone audit:
Berka Mono Instrument uses Iosevka source, Iosevka build parameters, and
Iosevka ligature groups only.

## Current Result

Audited font:

```text
fonts/ttf-instrument/BerkaMonoInstrument-Regular.ttf
```

Result:

```text
total=157
covered=122
missing=35
```

The audit compares HarfBuzz shaping with `calt`, `liga`, and `clig` enabled
against shaping with those features disabled. A sequence counts as covered when
the shaped glyph stream changes under normal OpenType shaping.

## Added Iosevka Groups

Instrument starts from Iosevka `default-calt` and adds:

```text
counter-arrow-l
counter-arrow-r
center-op-influence-dot
center-op-trigger-bar-l
center-op-trigger-bar-r
slasheq
logic
brack-bar
plus-plus
minus-minus
underscore-underscore
hash-hash
tilde-tilde
```

These groups cover useful coding cases without copying proprietary font
outlines, metrics, binaries, or names.

The `brace-bar` group is intentionally excluded because joining `{|` and `|}`
makes the bar collide visually with the curly brace at Instrument's compact
cell width.

## Residual Sequences

These audited sequences are not currently transformed by Berka Mono Instrument:

```text
?=
**
***
<$
$>
<$>
<+
+>
<+>
#(
#{
#[
]#
#!
#?
#=
#_
#_(
[<
>]
{{
}}
www
@_
&&
&&&
&=
~@
^=
!~
%%
#:
#{}
{|
|}
```

Most of these are language-specific reader, template, shell, or decorative
forms that Iosevka does not expose as normal safe `calt` groups. Adding them
properly would require a custom OpenType generation layer, not only a build-plan
change.
