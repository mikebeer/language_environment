# 10 - Performance suggestions for the CREXX VM and toolchain

Evidence base: the CRE benchmark (docs/09), a callgrind profile of the BASIC interpreter,
a micro-benchmark of VM operations, and an inlining experiment. One machine (2 cores),
Release build 1.0.0-beta.3. Differences under 5% are noise. Numbers are indicative, not a
formal benchmark.

## 1. Measured cost model (ns per operation, 200k iterations)

| Operation | ns | | Operation | ns |
|---|---|---|---|---|
| empty loop iteration | 10 | | string compare `a = b` | 40 |
| local call `f(x)` | 12 | | concat `a \|\| b` | 80 |
| imported call, not inlined | 19 | | `s as .float` | 12 |
| imported call, inlined `cretext.isdigit` (with single-char check) | 96 | | `x as .string` (float) | 302 |
| `length(s)` | 19 | | int array read / write | 16 / 12 |
| `c2d(ch)` | 9 | | string array write | 20 |
| `substr(s,i,1)` | 231 | | map write / read `sm[key]` | 80 / 110 |
| `left(s,3)` | 217 | | `fwrite` 20 bytes | 38 |
| `pos(needle,s)` | 118 | | **signal block entry, no signal** | **8,392** |
| `verify(s,set)` | 245 | | **signal raise + catch** | **9,050** |
| `upper(s)` | 161 | | module load (rxunicode) | ~360 ms |
| **`translate(s,o,i)`** | **1,290** | | | |

Callgrind (BASIC): about 700 VM instructions per procedure-call handler invocation;
`syncNumericContext` called about 1M times (1.3%); per-call runtime name resolution
(`resolve_runtime_procedure`, `runtime_proc_matches_signature`, `strncmp`); module
load/link about 15% of a 0.3 s program.

## 2. Inlining experiment (what the CRE costs and what inlining recovers)

Total wall time against the non-CRE baseline, same programs, same machine:

| Language | CRE (production cretext) | CRE, experimental inlinable cretext | Heavy workloads only |
|---|---|---|---|
| LOGO (6 programs) | +1.3% | -3.8% | big: +0.4% -> -7.4% |
| SNOBOL (11) | +1.4% | -0.2% | -0.1% -> -3.3% |
| BASIC (15) | +4.9% | +6.0% | no recovery (+7.4% / +7.3%) |

Findings:
- The inliner works across modules and exports templates for all six `cretext` functions
  once they are rewritten without early-return/helper shapes.
- With the production-safe body (single-character check plus range test) the call sites
  are still **not inlined**: the body exceeds the small-body budget. Only the experimental
  variant, which drops the single-character check, fits.
- Where it fits, LOGO and SNOBOL get faster than the baseline. BASIC does not benefit:
  its cost is number parsing and output, not character classification.
- Checked-in `cretext` uses the inline-friendly shape (24/24 conformance cases pass), so it
  benefits automatically if the budget is raised.

## 3. Suggestions, ordered by expected value

1. **Make the inline budget configurable and raise the default modestly.**
   Evidence: the six classification functions are 5-8 lines and miss the budget; the same
   code inlined gives -4% to -7% in tokenizer-heavy programs. Offer `rxc -inline-budget=N`
   and/or a per-procedure hint (e.g. `procedure ... inline`) so library authors can opt in.
2. **Inline across shapes that now block export.** `return length(...)`, helper calls and
   early returns prevent templates being exported. Supporting them (or documenting the
   accepted shapes in inlining_design.md) lets libraries be written naturally.
3. **Make signal blocks cheap.** Block entry costs about 8.4 us even when nothing is
   raised, 300-800x a normal operation. Any language that uses `signal on` for error
   handling pays this per statement/call. Candidate causes to check: per-entry allocation
   or copying of handler tables. A zero-cost-until-raised design (table lookup at raise
   time) would remove it. This is the largest single outlier in the table.
4. **Speed up `translate` (1.3 us), `verify` (0.25 us), `substr` (0.23 us), `left`
   (0.22 us).** These are 10-100x a local call. Likely allocation per call and
   codepoint-index scans; an ASCII fast path (byte index equals codepoint index when the
   string is known ASCII, flagged at creation) would help `substr(s,i,1)` in every
   tokenizer. Caching "is ASCII" or a codepoint-to-byte index on the string object is the
   idea to evaluate.
5. **Reduce per-call overhead in the call handler.** About 700 VM instructions per
   `CALL_REG_FUNC`; `syncNumericContext` runs on every call (about 1M times in one run).
   Sync only when a numeric option changed or the callee uses decimals.
6. **Cache runtime name resolution.** `resolve_runtime_procedure` and signature matching
   with `strncmp` run on calls. Resolve once at link/load time or memoise per call site.
7. **Cheaper module load and link.** Module load/link is about 15% of a 0.3 s program, and
   importing `rxunicode` costs about 0.36 s. Options: lazy load of modules only referenced
   in cold paths; load `rxunicode` on first use; rebuild the interface registry lazily.
   Linking all modules into one image gave no measurable gain in a spot check, so the cost
   is in load/registry work, not file count.
8. **Cheaper float to string (0.3 us) and string to float.** Float formatting is 25x the
   parse cost; a shortest-round-trip algorithm (Ryu-style) could replace a general
   formatter if that is what is used.
9. **Map access (80/110 ns) vs int arrays (12/16 ns).** Hash of the key string per access;
   caching the hash in the string object would help repeated keys (symbol tables).
10. **Keep inline templates in release images by default or document `rxlink -i`.**
    Images normally strip `META_INLINE`; shipping libraries as `.rxbin` with templates
    kept is what makes cross-module inlining possible.
11. **Provide a benchmark suite in the repo** with the micro-operations above, so VM changes
    can be tracked (this document's table is reproducible from `bench/` and the VM script).

## 4. Where the performance gain comes from

The VM. A language environment is the channel: once the VM or inliner gets faster at
calls, string built-ins and signal handling, every language on CRE benefits without
change, and the shared module is the one place to tune library code.

## 5. Caveats

- Single machine, two cores, no repeated sessions; micro-benchmark loops may be affected
  by the optimiser (results are accumulated to prevent dead-code elimination).
- The "experimental inlinable" cretext drops the single-character check and is **not**
  production-safe; it is evidence only.
- Callgrind attribution is from one BASIC workload.

A Word version with five-language timings and before/after samples: [CREXX-VM-performance-suggestions.docx](CREXX-VM-performance-suggestions.docx). Micro-benchmark sources: bench/vm/.
