# 07 - Alignment with CREXX Level L

Source: the *cREXX / Level L user guide* (spec language, generated lexers and
parsers, runtime API, errors and recovery). Sections read so far: overview,
lexical rules and Unicode, runtime API, trees, error messages and recovery.
**Not yet reviewed:** command line and build integration, resource limits, the
RexxScript example, troubleshooting. Conclusions below are provisional for
those areas.

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
   both needs a defined conversion. Proposal: `cretext` gains `bytetocp(s, off)`
   and `cptobyte(s, idx)` (for `.string`) with conformance cases for multi-byte
   text. This is a real gap, not duplication.
2. **One Unicode data source.** Level L carries Unicode 17.0.0 property data for
   generated lexers; CRE wants runtime classification. They must not carry two
   different versions. Proposal: `cre` capability query reports
   `unicode.version`, and runtime classification reuses Level L's property data
   (or the same tables) so a generated lexer and a runtime check agree on what a
   letter is.
3. **Normalisation and case folding.** Level L explicitly leaves these to the
   application ("implement these explicitly in your application's name
   handling"). Every Level L language with case-insensitive names needs them.
   This is a strong reason for an Ext module (`creunicode`) built on `rxunicode`.
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
- `creunicode` moves from "later" to "needed soon" (points 2 and 3).
- `crecond` includes the status-to-signal helper (point 4); it does not replace
  Level L statuses.
- Review the unread Level L sections and revise this note before the specs are
  frozen.
