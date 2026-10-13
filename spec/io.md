# creio v0 (draft)

Namespace `creio`. Source: `src/creio.crexx`. Test: `conformance/driver/run_io.sh`.

## Why

BASIC, SNOBOL, Smalltalk and Python each open the standard handles themselves and
repeat the same `fwrite`/`fflush` sequence in private `outs`, `errs` and
`flush_out` procedures. The inventory shows the same body in four repos.

## Procedures

| Procedure | Contract |
|---|---|
| `out(text)` | Write `text` (a `.string`, UTF-8) to standard output |
| `err(text)` | Flush standard output, write `text` to standard error, flush standard error. Output and error text therefore appear in program order when both go to one terminal |
| `flush()` | Flush standard output |
| `hout()` / `herr()` | `.int` stream handles of standard output / error, for programs (SNOBOL, BASIC file units) that keep a table of units and write with `assembler fwrite handle, text`. Opened on first use |

Handles are opened on first use. No end-of-line translation is done: the caller
supplies line endings (`'0a'x`).

## Notes

- The module state is two namespace variables, `creio_hout` and `creio_herr`.
  Level B has no module-private variables: every name in the `namespace ... expose`
  list is visible to importers, so state names carry the module prefix.
- Needs `import _rxsysb` for `_open`; callers do not.
- Standard input, files and binary streams are not in v0. Programs keep their own
  file handling; the survey shows each language's file layer differs more than its
  console layer.
- Encoding: text is written as the platform's stream expects UTF-8. Other
  encodings are an `rxunicode..encode` step before writing bytes, not a creio option.
