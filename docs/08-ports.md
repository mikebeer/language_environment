# 08 - Language ports onto CRE

Each port is a branch `cre-port` in the language's own repository. `main` of every
language is untouched. Each branch includes this repository as the git submodule
`cre`, so a clone with `--recurse-submodules` builds and runs.

| Language | Branch | Tests before | Tests after | Interpreter lines (before, after) |
|---|---|---|---|---|
| LOGO | [mikebeer/LOGO `cre-port`](https://github.com/mikebeer/LOGO/tree/cre-port) | 4 examples + demo | SVG output byte-identical, demo identical | 1202, 1192 |
| BASIC | [mikebeer/basic `cre-port`](https://github.com/mikebeer/basic/tree/cre-port) | 13 of 13 | 13 of 13 | 4987, 4955 |
| SNOBOL4 | [mikebeer/snobol `cre-port`](https://github.com/mikebeer/snobol/tree/cre-port) | 10 of 10 | 10 of 10 | 3815, 3781 |

All runs on the CREXX VM `1.0.0-beta.3` built from source, by each repository's own
`run_tests.sh` (or the example outputs for LOGO). The CRE conformance suite
passes at the same time (108 cases: text 46, number 49, condition 10, streams 3).

## What moved to CRE

| Was private in each language | Now |
|---|---|
| Digit and letter tests (`isdigitc`, `isdigit`, `isdig`, `isalpha`, `isletter`) | `cretext..isdigit`, `cretext..isalpha`, `cretext..isspace` |
| Float literal normalisation (`numtofloat`, 2 identical copies) | `crenum..parsefloat` |
| Float to text with `E` exponent (`fmtnum`, `fmtreal`) | `crenum..realtext` (the language adds its own rules on top) |
| `h_out`/`h_err` opening, `outs`, `errs`, `flush_out`, `fwrite`/`fflush` | `creio..out`, `creio..err`, `creio..flush`, `creio..hout`, `creio..herr` |
| LOGO number test (`datatype`) | `crenum..isdecimal` |

## What stayed in the language, on purpose

- Error models: `rt_error`/`report_error`/`handle_error` (BASIC `ON ERROR`, `ERR`,
  `ERL`), `snerr` (SNOBOL error keywords), `lerror` (LOGO). They carry language
  semantics. They should map onto `.signal` (`spec/cond.md`); that is the next
  large piece, not done here.
- BASIC `VAL` prefix scanning, identifier character sets (`_`, `.`), string
  comparison rules (`>>=`), `PRINT USING`, SNOBOL's "real" text rule (always has a
  point).
- File I/O (`fopen`, `freadline`, `feof`, `fclose`) in BASIC and SNOBOL. Both
  repeat the same pattern; this is the best candidate for the next CRE module.

## Findings

1. **Exposed names collide.** A namespace exposes every name on its `expose` line,
   and Level B has no private module state. Two collisions appeared: `cp`
   (LOGO's variable against a helper) and `isalnum` (BASIC's version against
   `cretext..isalnum`; compiler warning `SHADOWING`). Rules adopted: CRE modules
   expose only their documented API; state variables carry the module prefix
   (`creio_hout`); a language renames its own clashing helper (BASIC `isalnum`
   became `isidch`).
2. **Build order.** `crexx` compiles CRE modules first; the language then uses
   `-i cre/src` to import and `-l cre/src/<module>.rxbin` to run. Listing the CRE
   sources after the main file does not work. The launchers do this.
3. **Savings are real but small** (10 to 34 lines per interpreter). The gain is
   one tested definition instead of three, not line count.
4. **No behaviour changes found** by the existing test suites. LOGO's whitespace
   test now also counts VT and FF, and its number test no longer accepts blanks.
5. **Generated source.** SNOBOL's `snobol.crexx` is generated from `src/`; the
   port edits `src/` and regenerates with `build.py`.
