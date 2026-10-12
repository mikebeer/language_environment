# CREXX Language Environment (CRE)

A proposal and working repository for a **common runtime environment** that any
language running on a CREXX VM can share, modelled on the IBM z/OS Language
Environment (LE).

CREXX would then be two things:

1. the **core system**: VM, RXAS, toolchain and the CRE runtime services; and
2. **one of potentially many languages** on top (Rexx Levels B/C/G/L, RexxScript,
   and the LOGO, Pascal, BASIC, SNOBOL, Smalltalk, PL/I, COBOL ... implementations).

Anything built on CRE runs on **any platform that has a CREXX VM**. CRE makes no
assumption about operating system, CPU, word size, byte order or character
encoding. Platform differences are isolated in a thin host layer beneath CRE
(see [docs/02-architecture.md](docs/02-architecture.md)), so language
implementations never contain platform-specific code.

## Status

Draft 0. Design only; no CRE code yet. Nothing here is accepted by the CREXX
project (Adrian Sutherland is chief architect). Treat it as input to that
discussion.

## Contents

| Path | Purpose |
|---|---|
| [docs/01-vision.md](docs/01-vision.md) | Goals, non-goals, the LE lessons we copy and the ones we do not |
| [docs/02-architecture.md](docs/02-architecture.md) | Layers, the two-tier split, profiles, packaging |
| [docs/03-conditions.md](docs/03-conditions.md) | The language-neutral condition model, with per-language mappings |
| [docs/04-services.md](docs/04-services.md) | Draft v0 service catalog (`cre..*` namespaces) |
| [docs/05-compiler-writer-interface.md](docs/05-compiler-writer-interface.md) | What a new frontend must follow (outline and open questions) |
| [docs/06-roadmap.md](docs/06-roadmap.md) | Phases, alignment with the CREXX release train, open decisions |
| [inventory/INVENTORY.md](inventory/INVENTORY.md) | Survey of 12 language repos: what they duplicate, and what platform differences they each work around |
| [conformance/README.md](conformance/README.md) | Plan for the conformance suite |

## Principles

- **Extract, don't speculate.** A service enters CRE v0 only if at least two
  language implementations need it, or the VM already owns it.
- **Strict core, personalities on top.** CRE core is typed and language-neutral.
  Rexx looseness (1-based, loose comparison, string-first) lives in the Rexx
  personality layer over CRE, as COBOL's runtime sits over LE's common library.
- **Use what CREXX already has.** Namespaces, typed `.rxbin` metadata, RXPA
  plugins, interface/factory providers and cross-file inlining. No new linking
  mechanism.
- **Platform-neutral by construction.** No CRE API names an OS, an encoding or a
  machine word size. Text is Unicode text inside CRE; external encodings
  (EBCDIC, Latin-1, UTF-16, ...) are handled by codecs at the I/O boundary.
  Integer width, byte order, threads, filesystems and locale are *capabilities*
  that CRE reports, not assumptions it makes.
- **Honest capabilities.** Profiles (Core / Extended) are defined by capability,
  not by platform, and are discoverable at runtime. Unsupported services fail
  cleanly, never silently.
