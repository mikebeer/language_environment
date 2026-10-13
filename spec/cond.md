# crecond v0 (draft)

Namespace `crecond`. Source: `src/crecond.crexx`. Cases: `conformance/cases/cond/crecond.cases`.

## Decision: use `.signal`

CREXX already has conditions: `.signal` objects with a name, message and payload,
`signal on ... call` handlers returning `.signalaction`, block `ON SIGNAL`
clauses, and inheritance of handlers through the call tree. CRE does not add a
second mechanism. A language implemented over CRE reports and handles errors
with `.signal`.

## Convention

CRE procedures report failure by raising a standard CREXX signal name with a
short stable message:

| Situation | Signal | Message (v0) |
|---|---|---|
| Text is not a valid number | `CONVERSION_ERROR` | `not an integer`, `not a decimal number` |
| Valid number that does not fit | `OUT_OF_RANGE` | `integer does not fit`, `needs exponent form` |
| Argument not allowed | `INVALID_ARGUMENTS` | what is wrong |
| Division by zero | `DIVISION_BY_ZERO` | (runtime) |
| Bad encoded text | `UNICODE_ERROR` | (rxunicode) |
| Anything else | `FAILURE` or `ERROR` | free text |

A handler must test the signal name, not the message. Messages are for people
and may be translated later.

Query-style procedures that are used while scanning untrusted data
(`cretext..cptobyte`, `bytetocp`) return -1 instead of raising.

## Procedures

| Procedure | Contract |
|---|---|
| `raise(name, text)` | Raises signal `name` (any case) with `text` as message |
| `describe(c)` | `.string`: `NAME: message`, or `NAME` if the message is empty |
| `named(c, name)` | 1 if the signal's name equals `name` (case-insensitive) |

Observed on the VM: `c.name()` carries trailing blanks, so CRE always strips it.
A literal signal name must be upper case when built dynamically.

## Not in v0

- A language-neutral payload record (code, severity, source position). Level L
  diagnostics already have a position model; align with it first
  (`docs/07-level-l-alignment.md`).
- Message catalogs and localisation.
- Mapping of language-specific constructs (BASIC `ON ERROR`, Pascal exceptions,
  PL/I conditions) onto `.signal` names. The inventory lists the nine private
  error models to map.
