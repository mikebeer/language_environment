# Inventory: what the language implementations duplicate

Survey of the language repositories under `github.com/mikebeer/`, taken from
shallow clones on 2026-10-12. Purpose: find the services that more than one
implementation reimplements, so that CRE v0 is extracted from real need.

Method: file listings and line counts, procedure names pulled from every
`.crexx` source (pattern-matched into service categories), and reading the
READMEs and porting notes. Counts show *presence*, not behavioural equivalence;
equivalence is the first job of the conformance suite.

## The repositories

Two families exist.

**CREXX-hosted (Level B, run on the CREXX VM)**

| Repo | What it is | CREXX source |
|---|---|---|
| `LOGO` | LOGO interpreter | 1.2k lines |
| `pascal` | Pascal compiler to RXAS, plus runtime `pasrt` | 2.6k + 0.5k |
| `basic` | BASIC interpreter (GW-BASIC/QuickBASIC/FreeBASIC subset) | 5.0k |
| `snobol` | SNOBOL4 interpreter | 3.8k |
| `smalltalk` | Smalltalk-80 interpreter (also a C89 port, 14.5k lines C) | 5.5k |
| `lisp` | Common Lisp subset interpreter, about 220 built-ins | 7.0k |
| `PLM` | PL/M-80 compiler to RXAS, plus runtime `plmrt`, simulated 64 KB machine | 2.2k + 0.2k |
| `xbase` | xBase/Harbour interpreter (also C89, 14.3k lines C) | 11.2k |
| `python` | Python subset interpreter (also C89, about 112k lines C) | 24.4k |

**C89 (portable C, no CREXX VM needed)**

| Repo | What it is | C source |
|---|---|---|
| `apl` | Word-glyph APL | 12.4k lines |
| `pli` | PL/I compiler (C89 translator) | 17.6k lines |
| `cobol` | COBOL compiler (C89 translator) | 22.8k lines |

`prolog` and `java` are empty repositories. `cpp` is the GCC/binutils toolchain
for VM/370plus, not a language implementation of this kind.

## Services reimplemented across the CREXX-hosted family

Number of procedures per repo that match each service (`.` = none found).

| Service | logo | pasc | basic | snob | small | lisp | plm | xbase | pyth | repos |
|---|---|---|---|---|---|---|---|---|---|---|
| char classes | 2 | 4 | 3 | 2 | 3 | 2 | 3 | 4 | 2 | **9/9** |
| number parsing | 1 | 1 | 3 | 3 | 1 | 3 | 1 | 3 | 1 | **9/9** |
| error / conditions | 1 | 2 | 6 | 1 | 3 | 3 | 2 | 5 | 12 | **9/9** |
| tokenizer | 2 | 5 | 1 | 1 | 6 | 2 | 3 | 6 | 4 | 9/9 |
| number formatting | 1 | 2 | 5 | 1 | 4 | 3 | . | 3 | 7 | 8/9 |
| buffered output | . | 1 | 3 | 2 | 2 | 1 | 1 | 2 | 2 | 8/9 |
| trig / math | 2 | 5 | . | . | . | 7 | 1 | 6 | 5 | 6/9 |
| REPL / start-up | . | . | 3 | 1 | 3 | 2 | . | 1 | 2 | 6/9 |
| memory / GC | . | . | . | 1 | 2 | 1 | 1 | 1 | 9 | 6/9 |
| padding / formatting | . | 6 | 2 | . | . | 2 | . | 3 | 2 | 5/9 |
| hash tables | . | . | . | 2 | 4 | 7 | . | 4 | 12 | 5/9 |
| random numbers | . | 3 | 2 | . | . | 1 | . | 1 | 1 | 5/9 |
| file I/O | . | . | 6 | 1 | 7 | . | . | 2 | 5 | 5/9 |
| sort | . | . | . | 3 | . | 1 | . | 2 | 1 | 4/9 |
| big integers | . | . | . | . | 13 | . | . | . | 18 | 2/9 |
| date / time | . | . | 1 | . | . | . | . | 8 | . | 2/9 |
| sockets | . | . | . | . | 1 | . | . | . | 1 | 2/9 |

Tokenizers are in every repo, but they are language-engineering tooling
(CREXX's planned Level L), not runtime services, so they are out of CRE scope.
Memory/GC is mostly each language's own object model and also stays with the
language, except for shared buffer and value-ownership rules.

## Concrete evidence of duplication

- **Buffered output.** `basic`, `snobol`, `smalltalk` and `python` each define
  their own `flush_out` around the same `assembler fflush` / `fwrite` on a handle
  (`h_out`); `smalltalk` and `python` add a private output buffer; `xbase` does
  the same with `charout`. Each also has a private `errs`/`outs` for stderr.
- **Character classes.** `isdigit`/`isdig` in `basic` and `snobol` are the same
  body (a range test on `"0".."9"`). `smalltalk` and `basic` each define
  `isletter` as ranges on `a-z`/`A-Z` (ASCII-only); `lisp` tests the numbers
  65..90 and 97..122. Nine copies, none Unicode-aware.
- **Error models.** Every implementation has its own: `basic` has `ON ERROR` /
  `RESUME` (`do_onerror`, `do_resume`, `handle_error`); `lisp` has `handler-case`;
  `smalltalk` has `exc_matches`, `send_dnu`, `do_signal`; `python` has
  `exec_try`, `exc_new`, `exc_matches`; `snobol` has `&ERRLIMIT`/`&ERRTYPE`;
  `xbase` has `errset`, `errmessage`; `pascal` and `PLM` abort with a message
  (`pstkovf`, `pdivzero`). Each also keeps its own message texts.
- **Number formatting.** At least a dozen float/integer formatters
  (`fmtreal`, `fmtfloat`, `fixedfmt`, `floattext`, `float_str`, `float_repr`,
  `pfmtr`, `fixed_str`, ...) that must agree on rounding, exponent form and
  special values but are written independently.
- **Big integers.** `smalltalk` (13 procedures, `mag_*`, `big_*`) and `python`
  (18, `big_*`) each implement arbitrary-precision arithmetic.
- **Math, hash tables, sort, random.** Separate implementations of sin/cos/exp/
  sqrt/ln/atan (`lisp`, `xbase`, `pascal`, `logo`), of hashing (`dict_*` in
  `smalltalk`/`python`, `ht*` in `lisp`, `h*` in `xbase`, `tbl_*` in `snobol`),
  of merge sort (`msort` in `lisp` and `xbase`, `srt_sort` in `snobol`), and of
  random-number generators (`prandom`, `nextrand`, `rnd_next`).
- **Language runtime libraries.** `pascal` and `PLM` compile to RXAS and call a
  hand-written runtime (`pasrt` ~500 lines, `plmrt` ~160): string copy/insert/
  delete/pos, number formatting, console input/output, random, halt. This is the
  closest thing to LE's language-specific library layer that already exists.

## What the C89 family shows about platform neutrality

The C implementations were written to run where the CREXX VM is not available
(including VM/370 CMS), and each carries its own workarounds for platform
differences. Those workarounds are exactly what a common host layer should
absorb once:

| Platform difference | How each implementation copes today |
|---|---|
| Character set | `apl`: character classes use literal sets, never ranges, and no codepoint arithmetic. `smalltalk` C port: same. `cobol`: a `COB_EBCDIC` macro in the runtime changes zoned-decimal sign handling. `python` C port: `PORTING.md` section 7 lists ASCII assumptions that remain and states the open question outright: translate at the boundaries, or decide strings are ASCII internally and translate on output. |
| Integer width | `apl`: no `long long`, no `stdint.h`, 32-bit `int` indices. `pli`: uses a 64-bit type via compiler extension (`pl_i64`). Different choices in different repos. |
| Floating point | `apl` assumes no NaN or infinity (notes cite hexadecimal floating point); division by zero is a domain error. |
| Linking / names | `apl`: all functions `static`, only `main` external. `python` embeds its library as C arrays because it cannot assume a filesystem layout. |
| Libc services | Every C implementation uses its own `sprintf`, `strtod`, `fopen`/`fseek`, `time`/`localtime`/`strftime`, `getenv`, `system`, `setjmp`/`longjmp`, `qsort` for the same purposes. |

The CREXX VM already settles the text question for CREXX-hosted code (`.string`
is valid UTF-8 with codepoint operations, `.binary` is bytes). CRE adopts that as
the model for every platform and puts encodings at the I/O boundary through
codecs. That answers the question `python/c/PORTING.md` leaves open.

## Ranking for CRE v0

Ranked by how many implementations need it and how costly it is to get right:

1. **Text and character services** (classification, case mapping, codecs): 9/9
   and the main place platform differences leak.
2. **Number conversion and formatting** (parse, print, rounding, float forms):
   9/9 and 8/9, and the main source of cross-language inconsistency.
3. **Conditions and messages**: 9/9, each with a private model.
4. **Console and stream I/O with buffering**: 8/9 plus 5/9 for files.
5. **Collections and sort** (hash map, list, merge sort): 5/9 and 4/9.
6. **Math and random**: 6/9 and 5/9.
7. **Big integers**: only 2/9 but about 30 procedures duplicated, and PL/I and
   COBOL (C family) need exact wide and decimal arithmetic too.
8. **Date and time**: 2/9 in CREXX-hosted code, but every C-family compiler
   (PL/I, COBOL, APL, Smalltalk) calls `time`/`localtime`/`strftime`.
9. **Program entry, REPL, exit codes**: 6/9.

## Caveats

- Procedure-name matching can miss differently named routines and can match
  unrelated ones. Treat the counts as a map of where to look.
- Only top-level READMEs, one porting guide and selected code were read; the
  per-language manuals were not.
- The C89 family is not yet part of the matrix because its code is not
  procedure-pattern comparable; its needs are summarised from libc usage and
  portability notes above.

## Standard-library cross-check and first port (added after building CRE v0)

Checking the CREXX library showed that part of the duplication above is repos
not using what already exists: `rxunicode` (codecs, normalisation, case folding,
graphemes), `rxfnsb`, `rxfloat`, `rxdecimal`, collections and datetime. CRE
therefore stays thin: a contract and conformance layer, with new code only for
gaps (character classification, byte/codepoint offsets, strict number syntax,
the failure convention).

**LOGO port** (branch `cre-port` in mikebeer/LOGO, one file, `logo.crexx`):

| Measure | Result |
|---|---|
| Lines | 8 added, 18 removed (net -10) |
| Replaced | `isws`, `isdigitc` (private) by `cretext..isspace`, `cretext..isdigit`; `datatype`-based `isnum` by `crenum..isdecimal` |
| Output | Four example programs: SVG byte-identical to before; built-in demo output identical |
| Behaviour change | Whitespace now also includes VT and FF (cretext definition); numbers no longer accept surrounding blanks or ones `datatype` accepted that `isdecimal` rejects |
| Finding | Exposed names collide across modules (`cp`); modules must expose only documented API |

The saving is small because LOGO's own helpers were small. The value is shared,
tested behaviour, not line count. The larger duplicates (error models, float
formatting, output plumbing) need `crecond` payloads and a float formatting
rule, which are not in v0.
