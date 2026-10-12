# 03 - Condition model

Every implementation in the survey has its own error mechanism and its own
message texts. LE solves this with one condition model that languages map onto.
CRE does the same. This is the draft.

## Current state (from the survey)

| Language | Mechanism today |
|---|---|
| BASIC | `ON ERROR`, `RESUME`, error numbers and messages (`handle_error`, `do_onerror`, `do_resume`) |
| Common Lisp | `handler-case`, conditions with `error` / `reporterr` |
| Smalltalk | exceptions: `do_signal`, `exc_matches`, `send_dnu` (doesNotUnderstand) |
| Python | `try/except/finally`, exception objects (`exec_try`, `exc_new`, `exc_matches`) |
| SNOBOL4 | `&ERRLIMIT`, `&ERRTYPE`; plus *failure*, which is control flow, not an error |
| xBase | `errset`, error objects, `errmessage` |
| Pascal, PL/M | runtime errors abort with a message (stack overflow, divide by zero, halt) |
| PL/I, COBOL | `ON` conditions; `ON SIZE ERROR`, file status codes (language features to be mapped) |
| Rexx | `SIGNAL ON ERROR/SYNTAX/NOVALUE/...` (to be mapped) |

## Design

**Condition token** (data, not code):

| Field | Meaning |
|---|---|
| facility | Short id of the origin (`CRE`, `RXV`, a language id) |
| number | Integer within the facility |
| severity | `INFO`, `WARNING`, `ERROR`, `SEVERE`, `FATAL` |
| message id | Key into a message catalog (see below) |
| inserts | Values substituted into the message |
| origin | Module, procedure, source position when known |
| payload | Optional language object (e.g. a Python exception instance) carried unchanged |

**Handler stack.** Handlers register per enclave in stack order and are removed
when the registering scope ends. Raising a condition walks the stack from the
innermost handler.

**Handler actions:**

- `RESUME` with a value (continue where the condition was raised)
- `PERCOLATE` (pass to the next handler)
- `UNWIND` to a named scope marker (what `try/except`, `ON ERROR GOTO` and
  `handler-case` need)

If no handler takes it, the **default action** depends on severity: report
through `cre..msg`, set the return code, and terminate for `SEVERE` and above.

**Failure is not a condition.** SNOBOL4 and Prolog-style failure, and ordinary
status results, are control flow in the language. CRE does not turn them into
conditions.

**Messages.** `cre..msg` provides catalogs keyed by facility and message id, with
locale selection (the compiler already ships catalogs for `en_GB`, `en_US`,
`de_DE`, `nl_NL`), and one output destination so messages from all languages
interleave in order. Languages add their own catalogs under their own facility.

## Mapping examples

| Language construct | CRE condition use |
|---|---|
| BASIC `ON ERROR GOTO` + `ERR` | handler with `UNWIND` to a label marker; `ERR` is the condition number |
| Lisp `handler-case` | handler matching facility/number, `UNWIND` to the form's marker; condition object in `payload` |
| Python `try/except` | handler per `except` clause, `UNWIND`; exception instance as `payload` |
| Smalltalk `on:do:` with `resume:` | `RESUME` or `UNWIND` as the handler block chooses |
| COBOL `ON SIZE ERROR` | local handler for the arithmetic overflow condition with `RESUME` |
| Pascal runtime error | default action: report and terminate |
| Rexx `SIGNAL ON SYNTAX` | handler for CRE and Rexx error conditions with `UNWIND` to the label |

## Cross-language rule

A condition raised in code written in one language and handled in another
travels as the same token. The `payload` is opaque to other languages; they see
facility, number, severity and message.

## Open questions

1. What does the VM provide for non-local exit and handler scoping today? CRE
   should use it rather than invent a second mechanism. This needs input from the
   CREXX architect.
2. Cost model: handlers must be cheap on the no-error path.
3. Standard condition numbers for the shared runtime errors (conversion, range,
   divide by zero, end of file, I/O error, out of memory, capability missing).
