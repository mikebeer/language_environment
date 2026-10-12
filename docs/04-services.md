# 04 - Service catalog (draft v0)

> **Corrected after checking the CREXX standard library.** `rxunicode` already provides codecs, normalisation, full case folding and grapheme handling; `rxfnsb`, `rxfloat`, `rxdecimal` and the collection and datetime classes already cover much of the rest. Rows below that say "codecs", "normalisation" or similar mean *use the existing library*; CRE adds only the real gaps. v0 specs: [text](../spec/text.md), [num](../spec/num.md), [cond](../spec/cond.md).

Proposed `cre*` modules, ordered by the ranking in
[../inventory/INVENTORY.md](../inventory/INVENTORY.md). Everything here is a
proposal. "Profile" says where the module sits: **Core** is required on every
platform, **Ext** is an independently claimable extension.

All services are typed CREXX procedures. Text arguments are `.string`
(Unicode text); bytes are `.binary`. No signature mentions a platform, an
encoding or a machine word size.

| Module | Profile | Provides | Replaces (survey evidence) |
|---|---|---|---|
| `creenv` | Core | CRE version; capability query (`has`, `int.bits`, `charsets`); platform-neutral identity string for diagnostics only | Per-repo `CMS`/`EBCDIC`/`APL_HAVE_DIRENT`-style switches |
| `creprog` | Core | Enclave start-up and exit: arguments, return code, exit handlers, `halt`; the REPL loop helper | `init`, `boot`, `usage`, `repl*` in 6/9; `halt`/`exit` in Pascal, PL/M |
| `crecond` | Core | Condition tokens, handler stack, raise/resume/percolate/unwind (doc 03) | Nine private error models |
| `cremsg` | Core | Message catalogs, locale selection, one output destination | Private error texts in every repo |
| `cretext` | Core | Codecs (`encode`/`decode`); character classification and case by Unicode property; trim, pad, split/join, substring by codepoint, search, compare; builder for efficient concatenation | `isdigit`/`isletter`/`isalnum`/`isspace` in 9/9; `padleft`, `fmtpad`, `split_str`, `strcmp`; Pascal/PL/M string routines in `pasrt`/`plmrt` |
| `crenum` | Core | Parse and format integers, floats, decimals (radix, width, precision, rounding, exponent form, special values); exact integer arithmetic of any size; decimal arithmetic with defined rounding; checked conversion with conditions | `tonum`/`str2num`/`intval` 9/9; the dozen float formatters; `big_*`/`mag_*` in Smalltalk and Python; decimal needs of COBOL and PL/I |
| `creio` | Core | Console and file streams, text and binary, with explicit charset, buffering and flush; standard handles; line handling; structured paths; existence, delete, rename, directory listing where the host has one | `flush_out`/`errs`/`outs` 8/9; `file_*`, `open_file`, `read_file` 5/9 |
| `crecoll` | Core | List, map (hash), set, stable sort with comparator; ordered iteration | `dict_*`, `ht*`, `h*`, `tbl_*`; `msort`, `srt_sort` |
| `cremath` | Ext | Transcendental functions, power, rounding modes, pseudo-random generator with seed and algorithm identity | `lsin`/`lcos`/`lexp`/`lsqrt`/`lln`/`latan`, `psin`..., `sind`; `nextrand`, `prandom`, `rnd_next` |
| `cretime` | Ext | UTC instant, calendar fields, zones, parse/format, durations, sleep, monotonic clock | `datefmt`, `dtos`, `jdn2ymd`, `parsedate` (xBase); `do_sleep`; libc `time`/`strftime` in every C-family compiler |
| `crelocale` | Ext | Locale-aware number/date formats, collation, message language | None today; needed to avoid per-language reinvention |
| `creunicode` | Ext | Normalisation, full case folding, grapheme segmentation | Overlaps CREXX `rxunicode` (Level G); reconcile, do not duplicate |
| `crerecords` | Ext | Record-oriented files: fixed, variable, indexed, relative; locking where available | COBOL and PL/I file runtimes (`rt7_file.h`, `plirt.h`) |
| `crenet` | Ext | Sockets, name lookup, HTTP client | `l_sock`, `prim_net`; overlaps Level G HTTP |
| `crethread` | Ext | Tasks, channels, synchronisation | Overlaps Level G concurrency |
| `creregex` | Ext | Regular expressions with a stated dialect | CREXX `RxLite`; Python regex module; SNOBOL patterns stay language-specific |

## Rules for what belongs in CRE

1. At least two implementations need it, or the VM already owns it.
2. It can be specified without naming a platform or encoding.
3. Its behaviour can be tested by a language-neutral conformance case.
4. Language syntax and language semantics stay in the personality. For example,
   Rexx loose comparison, BASIC `PRINT USING`, SNOBOL pattern matching and Lisp
   `format` directives are personality features built on CRE primitives
   (`format` directives call `crenum` formatting; they are not CRE).

## Not in CRE

- Tokenizers, parsers, code generators (Level L territory).
- Object models and garbage collection of a particular language (Smalltalk
  objects, Python objects, Lisp cells). CRE only fixes how *shared* values
  (text, bytes, numbers, collections) are owned and passed between languages.
- Language-specific built-ins (SNOBOL `ARBNO`, PL/M `SHL`, Lisp `loop`).

## Interop value model (to be specified with Level G ownership work)

For a Pascal program to call a Rexx routine and share a string or list, CRE has
to state who owns a value, when it is copied, and what happens on mutation. The
CREXX roadmap lists nested-container ownership as open design in Level G; CRE
should adopt whatever it selects rather than define a competing rule.
