# 02 - Architecture

> **Naming and scope corrected.** A CREXX namespace is a single token, so modules are `cretext`, `crenum`, `crecond`, ... (not `cre..text`). CRE is a thin contract, profile and conformance layer over the existing library family, with new code only where the library has a gap. Exposed names are collision-prone: a module exposes only its documented API (found when LOGO's `cp` collided with a helper).

## Layers

```
  Languages (personalities)   Rexx BIFs | Pascal RTL | BASIC | SNOBOL | Lisp | ...
  ---------------------------------------------------------------------------
  CRE services                cretext  crenum  crecond  cremsg  creio
                              crecoll  cremath cretime  creprog creenv
  ---------------------------------------------------------------------------
  Host layer                  capability query + providers (per platform)
  ---------------------------------------------------------------------------
  CREXX VM, RXAS, RXPA        existing
  ---------------------------------------------------------------------------
  Any platform with a CREXX VM
```

Two tiers above the VM, as in IBM LE (common library plus language-specific
libraries):

- **CRE core**: strict, typed, language-neutral services. No Rexx looseness.
- **Personalities**: thin libraries that give each language its own surface
  (Rexx built-ins, a Pascal runtime, BASIC statements) by calling CRE.

The Rexx built-ins become a personality over CRE, not a special case.

## Platform neutrality

CRE names no platform. Everything that varies between platforms is a
**capability** reported by the host layer, and CRE services behave identically
wherever the capability exists.

### Text and encoding

- Inside CRE, text is Unicode text: CREXX `.string` (valid UTF-8, codepoint-level
  operations). Bytes are `.binary`. No CRE service accepts or returns "bytes that
  are really text".
- Moving between text and bytes happens only through `cretext` codecs:
  `encode(text, charset) -> .binary` and `decode(.binary, charset) -> text`.
  Charsets are named (UTF-8, ISO-8859-1, UTF-16, IBM code pages, ...). UTF-8 is
  always available; the rest are discoverable.
- Text streams carry a charset, defaulted from the host. Binary streams carry
  bytes. A program never sees the host's native encoding.
- Character classification and case mapping use Unicode properties, never
  numeric ranges or hard-coded literal sets. This removes the workarounds the
  C89 implementations carry today (see the inventory).
- Collation defaults to codepoint order; locale-aware collation is an optional
  capability.

### Numbers

- Integer width is a capability (`int.bits`), not an assumption. CRE services do
  not rely on 64-bit integers; `crenum` provides exact wide-integer
  arithmetic (big integers) so results do not depend on the machine word.
  (Release 1 of CREXX fixes `rxinteger` at signed 64-bit; the CREXX roadmap is
  still evaluating a narrower profile. CRE follows whatever the project decides.)
- Binary floating point and decimal arithmetic are both specified. Special
  values (NaN, infinity) are a capability; where absent, operations raise a
  defined condition instead of returning them.
- Byte order is never implicit: pack/unpack takes an explicit endianness.

### Time, files, locale

- Time is a UTC instant plus an optional zone from a provider; local zone comes
  from the host.
- Paths are structured (list of components plus a root kind), not strings with
  separators. Line endings are a stream property, not a program concern.
- Record-oriented files (fixed/variable records, indexed, relative) are an
  optional capability, needed by COBOL and PL/I and available wherever a host
  can provide them.
- Locale (number/date formats, messages language) is a capability with a
  neutral default.

### Concurrency and network

Threads, tasks, sockets and HTTP are optional capabilities. Programs query
them; unsupported use raises a defined condition.

## Capabilities and profiles

`creenv` exposes the capability list (`has("net")`, `int.bits`, `charsets`,
`records`, ...) and the CRE version. A **profile** is a named set of modules a
platform claims:

- **CRE-Core**: required everywhere. `prog`, `cond`, `msg`, `text` (UTF-8 plus
  classification and case), `num` (conversion, formatting, exact integers),
  `coll`, `io` (console, sequential text and binary streams), `env`.
- **CRE-Extended** modules, each independently claimable: `math` (transcendental),
  `time` (zones), `locale`, `unicode-full`, `records`, `net`, `threads`,
  `regex`.

Profiles are defined by capability, never by platform name. A platform is
supported when it passes the conformance suite for the profile it claims.

## Packaging

No new linking mechanism is needed.

- CRE is a set of `.rxbin` libraries under the `cre..` namespace, imported by
  namespace like any other CREXX library, with native RXPA plugins behind them
  where speed or the host demands.
- Platform differences sit behind interfaces. The existing interface and
  factory-provider mechanism (providers selected by `match` score) lets one CRE
  interface have a different provider per platform, and lets an application
  swap a provider.
- Cross-file inlining (`META_INLINE`) should make thin personality wrappers
  over CRE close to free in compiled code. Interpreters written in CREXX call
  CRE as ordinary procedures.
- Versioning: interfaces are additive within a major version; the CRE version is
  recorded in library metadata and queryable at runtime.

## Relationship to existing CREXX levels

| Item | Relationship to CRE |
|---|---|
| Level B | The language CRE and its tests are written in |
| Level C / RexxScript | Personalities: Classic BIFs built over CRE |
| Level G | Provider, concurrency, HTTP, UI, LLM, Unicode: candidates for CRE-Extended modules; must be reconciled, not duplicated |
| Level L | Language-engineering tooling (lexers, parsers): the *frontend* counterpart of CRE, which is the runtime side |

## Open questions

1. Does CRE belong inside the CREXX distribution (as part of Level G) or ship as
   a companion library? Needs a decision from the CREXX architect.
2. How much of the condition model (doc 03) needs VM support versus library
   conventions?
3. Should a C89 `libcre` exist for hosts without a CREXX VM, so the C89
   implementations share the same specification? The spec is language-neutral,
   so this is possible, but it is a separate decision.
