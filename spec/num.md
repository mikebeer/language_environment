# crenum v0 (draft)

Namespace `crenum`. Source: `src/crenum.crexx`. Cases: `conformance/cases/num/crenum.cases`.

## Scope

CREXX already converts and formats numbers. Observed on the VM (beta 3):

- `s as .int` accepts optional sign and ASCII digits, and also accepts
  surrounding blanks; it rejects `0x10`, `1_000`, non-ASCII digits, and the empty string.
  A value that does not fit raises CONVERSION_ERROR, not OUT_OF_RANGE.
- `s as .decimal` accepts `inf` and `nan`, and rejects surrounding blanks.
  (The int and decimal rules differ on blanks.)
- `format(x,,n)` rounds half away from zero.

Languages need one rule, so `crenum` fixes the syntax once and states failures
in terms of conditions (`spec/cond.md`).

## Procedures

| Procedure | Contract |
|---|---|
| `isint(s)` | 1 if `s` is an optional `+`/`-` followed by one or more ASCII digits, nothing else (no blanks), else 0 |
| `isdecimal(s)` | 1 if `s` is a plain decimal: optional sign, digits with an optional point (`.5`, `5.`, `1.5`), optional exponent `e`/`E` with optional sign and digits. No blanks, no `inf`, no `nan`, no radix prefix, no digit separators |
| `parseint(s)` | `.int`. Not `isint`: CONVERSION_ERROR. `isint` but not representable: OUT_OF_RANGE |
| `fixed(x, places)` | `.string`. `x` is a string accepted by `isdecimal`, else CONVERSION_ERROR. `places < 0`: INVALID_ARGUMENTS. Result in fixed notation with exactly `places` decimals, rounded half away from zero, never `-0`/`-0.00`. If the result would need exponent form: OUT_OF_RANGE |

All syntax is ASCII and independent of locale. Decimal point is `.`.

## Known gaps (not in v0)

- Float formatting and shortest round-trip output. The survey found a dozen
  private formatters; one rule needs agreement on rounding and exponent form.
- Radix conversion and width/padding formats.
- Exact big integers (Smalltalk and Python implement their own).
- Large values in `fixed`: `format` switches to exponent form at the working
  digit limit, so `fixed` raises OUT_OF_RANGE there. It should instead produce
  the full digits, which needs decimal arithmetic.
