# 06 - Roadmap

## Phases

| Phase | Goal | Output |
|---|---|---|
| 0 | Evidence | [Inventory](../inventory/INVENTORY.md) of what the language repos duplicate. **Done (draft).** |
| 1 | Specify CRE-Core v0 | Specs for `env`, `prog`, `cond`, `msg`, `text`, `num`, `io`, `coll`, with language-neutral conformance cases written first |
| 2 | Reference implementation | Level B libraries (plus RXPA only where needed) passing the Core suite on the CREXX VM on at least two different platforms |
| 3 | Prove it on real languages | Port two implementations onto CRE: a small one (LOGO) and a mid-sized one (BASIC or SNOBOL). Measure lines removed and run time before and after. Port one compiler's runtime (`pasrt`) |
| 4 | Extensions | `math`, `time`, big integers and decimal (shared by Smalltalk, Python, COBOL, PL/I), `records`, reconciliation with Level G modules |
| 5 | Rexx as a client | Rexx built-ins implemented over CRE as a personality |
| 6 | Decide on C89 `libcre` | Whether the C89 implementations share the same specification |

Phase 1 begins with the three areas that are both most duplicated and most
platform-sensitive: **text, number conversion/formatting, and conditions**.

## Alignment with the CREXX release train

From the CREXX roadmap (dates are the project's planning targets):

| Milestone | Date | Relevance |
|---|---|---|
| Beta 4, core complete | 2026-11-30 | Last point to propose changes to core contracts |
| Beta 5, platform functionally complete | 2027-01-31 | Baseline Levels G and L; platform contracts frozen |
| Beta 6, performance beta | 2027-03-31 | Performance of selected candidates |
| Release 1 | 2027-05-01 | Tag and publish |

If CRE is to be part of Release 1, its contracts have to be settled by the
January 2027 freeze, so the proposal should reach the architect now. If not, CRE
can proceed as a companion library in this repository without touching the
platform freeze, and be offered for inclusion later.

## Decisions needed

1. **Scope and home.** In the CREXX distribution (with Level G/L) or companion?
   Who owns the interface definitions?
2. **Text model.** Confirm: Unicode text inside, codecs at the boundary,
   no platform or encoding in any API.
3. **Integer width.** Follow the CREXX decision on 64-bit versus a narrower
   profile; CRE stays correct through exact integers either way.
4. **Conditions.** Confirm what the VM offers for non-local exit and handlers.
5. **Overlaps.** Resolve against Level G (Unicode, concurrency, HTTP) and the
   class-library principles work before writing specs that would collide.
6. **C89 family.** Decide whether the specification also drives a C89 `libcre`.
7. **Name.** `CRE` is a working name; the namespace `cre..` needs confirming.

## First concrete steps

1. Review the inventory and this design with the CREXX architect.
2. Write the Core v0 specs for text, num and cond.
3. Write the conformance cases before the implementation.
4. Implement against two platforms to catch platform leaks early.
