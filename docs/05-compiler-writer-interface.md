# 05 - Compiler-writer interface (outline)

IBM documents low-level compiler-writer interfaces (CWIs) between the common
runtime and each language's runtime. CRE needs the equivalent: the rules a new
frontend follows to use CRE correctly. This document is an outline with the
questions that need answers from the CREXX architect. It records what the
existing implementations already do, so the interface standardises practice
rather than inventing it.

## Two kinds of frontend

| Kind | Examples | How it uses the runtime today |
|---|---|---|
| Interpreter written in CREXX | LOGO, BASIC, SNOBOL, Lisp, Smalltalk, xBase, Python | Calls CREXX built-ins and a few direct VM instructions (`assembler fflush`, `assembler fwrite` on standard handles) |
| Compiler emitting RXAS | Pascal, PL/M | Emits assembler and calls a hand-written runtime library (`pasrt`, `plmrt`) through a runtime-call convention |

CRE has to serve both: ordinary imports for the first, a defined call and
linkage convention for the second.

## Sections to specify

1. **Entry and exit.** The `main` entry contract, how arguments arrive, return
   code, exit handlers, once-only module initializers. CREXX already provides an
   implicit `main` with hidden arguments and `.initializer` procedures; CRE
   documents how a frontend uses them.
2. **Calling convention.** Argument passing (value, reference, optional,
   variadic), return values, who owns returned values. Source: the CREXX
   compiler's call ABI flags in the register status word.
3. **Types.** Mapping of language types to `.int`, `.float`, `.decimal`,
   `.string`, `.binary`, arrays, objects. Integer width is a queried capability.
4. **Text.** All text is `.string` (Unicode). Charset conversion only through
   `cretext` codecs at I/O boundaries.
5. **Conditions.** How a frontend registers handlers, raises conditions, and maps
   its error constructs (doc 03).
6. **Values shared across languages.** Ownership, copy and mutation rules for
   strings, bytes, arrays and collections (depends on the Level G ownership
   decision).
7. **Standard handles.** One definition of stdin, stdout, stderr and how a
   frontend reaches them, replacing per-implementation `h_out`/`h_err` plumbing.
8. **Runtime-call convention for generated code.** The equivalent of `rtcall` in
   the Pascal and PL/M compilers: how emitted RXAS reaches a runtime library,
   linking, and the metadata a language library publishes so another language can
   import it.
9. **Capabilities.** How a frontend queries a capability and what it must do when
   it is absent.
10. **Metadata and versioning.** Namespace, library version, interface version
    and the compatibility rule recorded in `.rxbin` metadata.
11. **Conformance.** What a frontend runs to claim support (see
    [../conformance/README.md](../conformance/README.md)).

## Questions for the CREXX architect

1. Which of these are already specified in the CREXX documents? The
   architecture notes cover the call ABI flags, initializers, imports and
   metadata; they do not describe a runtime-call convention for foreign
   frontends.
2. What does the VM offer for non-local exit and handler scoping (needed by
   doc 03)?
3. Is a stable public subset of RXAS for third-party frontends intended, or is
   RXAS an internal interface that may change? CRE's compiler-writer interface
   can only be as stable as what it sits on.
4. Where do standard handles and buffered output belong, VM or library?
