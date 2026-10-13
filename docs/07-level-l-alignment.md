# 07 - Alignment with CREXX Level L

Source: the *cREXX / Level L user guide*, read in full (overview, spec language,
lexical rules and Unicode, comments, parser rules and operators, token stages and
regions, runtime API, trees and projection, errors and recovery, command line and
build, resource limits, the RexxScript example, troubleshooting, glossary).

## Verdict

CRE and Level L are compatible, and mostly complementary. Level L generates the
front end of a language (lexer, parser, tree). CRE supplies what the generated
language needs at run time (text, numbers, conditions, I/O). They meet at four
points: text and offsets, Unicode data, errors and diagnostics, and naming.

## Where they already agree

| Topic | Level L | CRE | Result |
|---|---|---|---|
| Text model | Source is `.binary`; `scan: lexer` (utf8) matches Unicode scalar values; NUL is data | `.string` is valid UTF-8 text, `.binary` is bytes, encodings only at the boundary | Same model |
| Namespaces | Single-token lowercase (`llcore`, `lllanguage`, `lltree`, `llsource`) | `cretext`, `crenum`, `crecond` | Same convention |
| Base library | Generated code imports `rxfnsb` | CRE wraps `rxfnsb`/`rxunicode`/`rxfloat` | Same base |
| Unicode data | `unicode.XID_Start` etc., Unicode 17.0.0, consistent across host locales | Classification should not depend on host locale | Same intent |
| Platform neutrality | Positions are byte offsets in the original source on every platform | No platform, encoding or word size in any API | Same intent |

## Points that need a decision

1. **Byte offsets versus codepoint indices.** Level L reports every position as
   a zero-based byte offset; `cretext` indexes by codepoint. A language built on
   both needs a defined conversion. Proposal: `creutf8` provides `bytetocp(s, off)`
   and `cptobyte(s, idx)` (for `.string`) with conformance cases for multi-byte
   text. This is a real gap, not duplication.
2. **One Unicode data source.** Level L carries Unicode 17.0.0 property data for
   generated lexers; CRE wants runtime classification. They must not carry two
   different versions. Proposal: `cre` capability query reports
   `unicode.version`, and runtime classification reuses Level L's property data
   (or the same tables) so a generated lexer and a runtime check agree on what a
   letter is.
3. **Normalisation and case folding.** Level L leaves these to the application. CREXX's `rxunicode` already provides them (`toNFC`, `toCasefold`, graphemes, `version()`), so no CRE module is needed; Level L languages should call `rxunicode` for name comparison. Open check: `rxunicode..version()` and Level L's `unicodeversion()` should agree.
4. **Errors: status codes versus signals.** Level L reports parse failures as
   request status (0, 1, 2, 3, 5) plus `offset()` and `error()`, not as `.signal`.
   That is correct for a parser and CRE should not override it. CRE conditions
   cover run-time errors. Proposal: a small helper maps a Level L status to a
   `.signal` for languages that want parse errors to surface as conditions;
   recovery mode (status 1, several diagnostics) stays status-based.
5. **Diagnostics and message templates.** Level L has `llsource..diagnostic(source,
   offset, name, message)` and templates with `{found}`, `{expected}`, `{rule}`,
   `{{`/`}}`. CRE message services should reuse that diagnostic format for
   source-position messages and adopt the same template syntax for catalogs,
   instead of defining a second one.
6. **Resource limits.** Level L has `.lllimits..policy` with a distinct "limit
   exhausted" status. CRE could use the same policy-object pattern for run-time
   limits (not yet reviewed in detail).

## Division of labour

- **Level L:** lexing, parsing, trees, parse-error recovery, parse diagnostics.
- **CRE:** text, numbers, conditions at run time, message catalogs, I/O,
  program start and exit, capability query.
- **The language itself:** semantics that sit between the two.

A Level L language would import its generated namespace plus `cretext`,
`crenum` and `crecond`. A hand-written interpreter (LOGO, BASIC, ...) imports
the same CRE modules, so both kinds share one runtime.

## Consequences for the plan

- Spec work in `cretext` includes the offset conversion (point 1).
- No `creunicode` module: `rxunicode` covers it. CRE only reports the Unicode data version and checks it matches Level L (point 2).
- `crecond` includes the status-to-signal helper (point 4); it does not replace
  Level L statuses.
- Review the unread Level L sections and revise this note before the specs are
  frozen.

## Further alignment points from the full read

7. **Diagnostics already count codepoints.** `llsource..diagnostic` converts a byte
   offset to a one-based line and column, columns counting Unicode scalar values,
   and recognises CRLF, CR and LF. That is the same unit as `cretext` indexing, so
   CRE should call it rather than duplicate it, and `creutf8..bytetocp` must agree with it.
8. **Keywords are ASCII case-insensitive by design.** Level L token stages compare
   text "ignoring ASCII case"; names keep their spelling and Unicode normalisation
   or folding is the application's job (use `rxunicode`). This matches cretext v0
   classification being ASCII-only; BASIC and SNOBOL keywords need nothing more.
9. **Status codes, not signals, for the front end** (0 success, 1 invalid input,
   2 resource allowance exhausted, 3 invalid configuration, 5 no unique tree;
   recovery adds 4). A CRE language should report front-end failures the same
   way and raise `.signal` only for run-time errors.
10. **Build integration.** Level L is built with `levell spec --rxas` (exit 0, 1, 2),
    written safely through `lib/rxfnsl/tools/generate.cmake`, then assembled and
    linked like any module. CRE libraries are ordinary `.rxbin` modules, so a
    Level L language links them the same way; no special support is needed.
11. **Fixed limits to respect.** Token IDs 1-255; recursion depth ceilings 128
    (specification) and 512 (LL, PEG, Pratt, forests); `source.bytes` default
    1,048,576. CRE services used on the parse path must not assume larger inputs.
12. **Value semantics copy.** Definitions, requests and trees are values; passing a
    whole tree by value can copy it. CRE collection and text services that accept
    trees or large strings should be documented with their copy behaviour.
13. **Positions are original-source byte offsets, comments and whitespace
    included.** A CRE interpreter that keeps line numbers (BASIC) can derive them
    from offsets instead of re-scanning.
14. **Optional future step.** BASIC's and SNOBOL's hand-written tokenizers could be
    replaced by Level L lexers. That is a separate decision from the CRE port and
    is not part of it.

## Result of the review

No conflict was found. Everything in Level L that touches runtime services
(Unicode data, diagnostics, status model, namespace style) is either already used
by CRE or listed above as an alignment rule. Decisions 1 to 6 are unchanged.
