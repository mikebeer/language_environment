# cretext v0 (draft)

Namespace `cretext`. Source: `src/cretext.crexx`. Cases: `conformance/cases/text/cretext.cases`.

## Scope

CRE does not re-specify what CREXX already provides. For these, use the existing
library and the CREXX documentation is the specification:

| Need | Use |
|---|---|
| Length, substring, search, case of ASCII, padding | `rxfnsb` (`length`, `substr`, `pos`, `upper`, ...) |
| Encoding and decoding (UTF-8, UTF-16, Latin-1, EBCDIC pages, ...) | `rxunicode..encode` / `rxunicode..decode` |
| Normalisation, full case folding, grapheme clusters | `rxunicode` |
| Codepoint value of a character | `c2d(c)`; character from codepoint `d2c(n)` |

`cretext` adds only what is missing.

## Text model

A `.string` is valid text indexed by Unicode codepoint (1-based, as in `rxfnsb`).
`.binary` is bytes. Encodings appear only at the boundary (`rxunicode`).
Byte offsets mean offsets in the UTF-8 form of a string, zero-based. This is the
position model of Level L, so a Level L position can be turned into a CRE index.

## Procedures

Classification takes one character (a `.string` of length 1) and returns `.int`
0 or 1. Any argument that is not exactly one character returns 0.
In v0 classification is defined for ASCII only; every codepoint above U+007F
returns 0 for every class. A later version may extend this with Unicode
properties, using the same data as Level L (Unicode 17.0.0). Callers must not
rely on non-ASCII returning 0 once that extension exists.

| Procedure | True for |
|---|---|
| `isdigit(c)` | U+0030..U+0039 |
| `isupper(c)` / `islower(c)` | A-Z / a-z |
| `isalpha(c)` | A-Z, a-z |
| `isalnum(c)` | `isalpha` or `isdigit` |
| `isspace(c)` | U+0020, U+0009..U+000D |

Offsets:

| Procedure | Result |
|---|---|
| `bytelen(s)` | Number of bytes of the UTF-8 form of `s` |
| `cptobyte(s, i)` | Zero-based byte offset of codepoint `i` (1-based). `i = length(s)+1` gives `bytelen(s)`. Otherwise out of range: -1 |
| `bytetocp(s, off)` | 1-based codepoint index at zero-based byte offset `off`. `off = bytelen(s)` gives `length(s)+1`. Not on a codepoint boundary or out of range: -1 |

The offset procedures return -1 rather than raising, because they are used while
scanning untrusted positions. `cptobyte` and `bytetocp` are inverses over the
valid domain.

## Open points

- Performance: v0 walks the string once per call, O(n). A Level L language
  that converts many positions should convert once, or CRE should add an indexed
  form. Decide after measuring a real port.
- Non-ASCII classification (see above).
