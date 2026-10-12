# 01 - Vision

## The problem

Each language implemented on CREXX (Rexx Levels B/C/G/L, RexxScript, and the
LOGO, Pascal, BASIC, SNOBOL, Smalltalk, Lisp, PL/I, COBOL ... implementations)
needs the same basic services: string handling, number formatting, date and
time, file and stream I/O, collections, error handling, messages. Today each
implementation either reimplements them or borrows Rexx-flavoured functions
whose semantics (1-based indexing, loose comparison, string-first typing) do
not suit other languages.

Result: duplicated work, subtly different behaviour between languages, and no
safe way for a program in one language to hand data or errors to another.

## The idea

A common runtime environment, CRE, shared by every language on the VM, in the
way IBM's z/OS Language Environment is shared by COBOL, PL/I, C and Fortran.

CREXX becomes:

1. the **core system**: VM, RXAS, toolchain, **and** the CRE runtime services;
2. **one of many languages** on top of that core.

## What we take from IBM Language Environment

LE's architecture is built from four models: program management, condition
handling, message services and storage management. It consists of a common
execution library plus thin language-specific libraries, and it documents the
compiler-writer interfaces between them. Its payoff is that every language gets
the same callable services, so data and resources created in one language can
be used or released by another, and messages from all languages go to one
destination.

CRE adopts the same shape:

| LE concept | CRE counterpart |
|---|---|
| Program management | Enclave/entry contract: start-up, arguments, exit, return code, initializers |
| Condition handling | One language-neutral condition model that each language maps onto |
| Message services | Shared message catalogs and output destinations |
| Storage management | Common value model and ownership rules for data shared across languages |
| Common execution library | `cre*` core libraries |
| Language-specific libraries | Personality layers (Rexx BIFs, a Pascal RTL, ...) built over CRE |
| Compiler-writer interfaces | The CRE compiler-writer interface (doc 05) |
| Callable services | Namespaced, typed, versioned procedures |

## What we deliberately do not copy

- LE's tie to one operating system and one machine architecture. CRE is
  platform-neutral (below).
- An assembler-centric calling interface. CRE services are ordinary typed
  CREXX procedures, discoverable through `.rxbin` metadata.
- A large service surface from day one. CRE starts with what is demonstrably
  shared.

## Platform neutrality (a hard requirement)

CRE must work on any platform with a CREXX VM: desktop, server, embedded,
browser/WebAssembly, mainframe, or anything else. Consequences:

- **No platform in any API.** Nothing in CRE names an OS, a filesystem layout,
  a machine word size or a character encoding.
- **Text is Unicode text inside CRE.** CREXX's `.string` is valid UTF-8 text with
  codepoint-level operations, and `.binary` is arbitrary bytes. Converting between
  external encodings (EBCDIC code pages, Latin-1, UTF-16, ...) and internal text
  happens at the I/O boundary through codecs. CREXX already follows this
  pattern: its text adapter and `-E` encoding selector work at the file
  boundary, not inside the VM.
- **Differences are capabilities, not assumptions.** Integer width, byte order,
  availability of threads, sockets, a filesystem, a clock, a locale: CRE reports
  these through a capability query and its services behave identically wherever
  a capability is present.
- **One conformance suite, every platform.** A platform is supported when it
  passes the suite for the profile it claims.

## Non-goals

- Replacing the VM, RXAS or the Rexx language definitions.
- Forcing languages to share syntax or semantics. Only runtime services are
  shared; each language keeps its own rules in its personality layer.
- Emulating capabilities a platform lacks.

## Success criteria

1. A new language implementation reaches useful I/O, string, number, time,
   error and message behaviour by importing CRE, with no reimplementation.
2. The same program behaves the same on every platform that claims the
   relevant profile.
3. A Pascal program can call a Rexx routine, receive its conditions, and share
   its strings and collections without conversion code.
4. The Rexx built-ins are themselves a CRE client, which proves the layering.
