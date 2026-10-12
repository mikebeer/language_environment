# Conformance suite (plan)

CRE is defined by behaviour, so behaviour is tested. The suite has to be
language-neutral and platform-neutral: the same cases run on every platform that
claims a profile, and the results must be identical.

## Principles

- **Specification by example.** Each service has cases with inputs and exact
  expected outputs (text, numbers, condition tokens). Where a platform cannot
  provide a capability, the expected result is the defined "capability missing"
  condition, not a silent difference.
- **Character-set independent.** Test data is expressed as Unicode code points
  and, for codec tests, as explicit byte sequences. No case depends on a
  platform's native encoding.
- **Written first.** Cases for a module exist before its implementation.
- **One suite, many consumers.** Cases are plain data (input, expected) plus a
  small driver written in CREXX Level B; the same data can drive a C89 harness if
  a `libcre` is built. This mirrors the common consumer suite the CREXX project
  uses for its LLM provider interface.
- **Profile reports.** A run produces a report stating which profile and which
  extension modules the platform passes.

## Layout (planned)

```
conformance/
  cases/text/        classification, case, codecs, comparison
  cases/num/         parse, format, rounding, exact integers, decimal
  cases/cond/        raise, handler order, resume, unwind, defaults
  cases/io/          streams, charsets, buffering, paths
  driver/            Level B runner and report writer
```

## First cases to write

1. Number formatting: the cases that today differ between `fmtreal`, `fmtfloat`,
   `float_str`, `float_repr` and `fixedfmt`: rounding, exponent form, negative
   zero, very large and very small values, special values.
2. Character classification for ASCII, Latin-1 supplement and a non-Latin script,
   to replace nine ASCII-only copies.
3. Codec round trips for UTF-8, ISO-8859-1 and UTF-16, plus a deliberately
   invalid byte sequence.
4. Condition handler ordering across a call chain written in two languages.
