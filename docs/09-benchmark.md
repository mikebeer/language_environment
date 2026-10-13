# 09 - Benchmark: with CRE and without

Same interpreter, same VM (`1.0.0-beta.3` built from source), same inputs. "Without" is
`main` of each language repository; "with" is branch `cre-port` (CRE modules loaded as
separate `.rxbin` files). Wall time of one `rxvm` run, median of 9 runs, runs interleaved,
2-core cloud machine, so differences under about 3 to 5 percent are noise. Harness and raw
numbers: [../bench/](../bench/).

Workloads: every regression test of BASIC (13) and SNOBOL (10), the LOGO examples and demo (5),
and four synthetic programs written to stress what CRE changed (20,000 lines of output; 40,000
number parses; a 3,000-line LOGO program). Output means standard output and error, exit code,
and for LOGO the SVG file.

## 1. Results

All 32 workloads give **identical output** with and without CRE (byte for byte, same exit codes).

## 2. Speed

| Language | Workloads | Total without | Total with | Total change | Geometric mean change |
|---|---|---|---|---|---|
| basic | 15 | 2.69s | 2.87s | +6.6% | +3.8% |
| snobol | 11 | 1.57s | 1.62s | +3.3% | +3.2% |
| logo | 6 | 1.06s | 1.07s | +0.9% | +2.5% |

Worst cases: BASIC number parsing (`VAL` 40,000 times) is **18% slower**; output of 20,000
lines is 3 to 4% slower; LOGO's example `tree` is 12% slower on one run (it is a 0.1 s program,
so this is mostly noise). Small programs pay about 3 ms to load four extra modules.

| Language | Workload | Without (s) | With (s) | Change | Output |
|---|---|---|---|---|---|
| basic | tests/errors_files_misc | 0.114 | 0.116 | +1.3% | identical |
| basic | tests/fb_basics | 0.112 | 0.114 | +1.5% | identical |
| basic | tests/fileio | 0.104 | 0.114 | +9.2% | identical |
| basic | tests/hanoi | 0.109 | 0.113 | +3.8% | identical |
| basic | tests/hello | 0.111 | 0.107 | -3.5% | identical |
| basic | tests/input | 0.101 | 0.102 | +1.3% | identical |
| basic | tests/mandel | 0.304 | 0.328 | +7.8% | identical |
| basic | tests/ms_basics | 0.104 | 0.105 | +0.8% | identical |
| basic | tests/primes | 0.103 | 0.105 | +1.7% | identical |
| basic | tests/procs_arrays | 0.109 | 0.113 | +3.5% | identical |
| basic | tests/strings | 0.104 | 0.107 | +2.5% | identical |
| basic | tests/subs | 0.170 | 0.174 | +1.8% | identical |
| basic | tests/using | 0.101 | 0.107 | +6.0% | identical |
| basic | synthetic/out | 0.460 | 0.475 | +3.2% | identical |
| basic | synthetic/parse | 0.582 | 0.688 | +18.3% | identical |
| snobol | tests/calc | 0.085 | 0.089 | +4.4% | identical |
| snobol | tests/errors | 0.083 | 0.086 | +3.0% | identical |
| snobol | tests/features | 0.280 | 0.287 | +2.4% | identical |
| snobol | tests/fold | 0.083 | 0.087 | +5.0% | identical |
| snobol | tests/functions | 0.108 | 0.108 | -0.2% | identical |
| snobol | tests/hello | 0.083 | 0.086 | +2.9% | identical |
| snobol | tests/patterns | 0.090 | 0.091 | +1.0% | identical |
| snobol | tests/roman | 0.088 | 0.092 | +4.8% | identical |
| snobol | tests/sieve | 0.091 | 0.095 | +4.8% | identical |
| snobol | tests/wordfreq | 0.087 | 0.090 | +3.6% | identical |
| snobol | synthetic/out | 0.492 | 0.512 | +4.1% | identical |
| logo | examples/fact | 0.091 | 0.092 | +0.5% | identical |
| logo | examples/spiral | 0.096 | 0.100 | +4.6% | identical |
| logo | examples/star | 0.088 | 0.090 | +2.1% | identical |
| logo | examples/tree | 0.104 | 0.116 | +11.9% | identical |
| logo | demo | 0.105 | 0.102 | -2.3% | identical |
| logo | synthetic/big | 0.577 | 0.570 | -1.2% | identical |

## 3. What happened on the way

1. **First measurement: every run 0.36 s slower.** `cretext` imported `rxunicode` for the byte
   offset functions, and loading `rxunicode` costs about 0.36 s at start-up. Fixed by moving those
   functions to their own module `creutf8`. Rule: a CRE module must not import anything heavy
   that the common path does not need. First-pass numbers are kept in
   `bench/results_first_pass_with_rxunicode_in_cretext.json`.
2. **Number parsing: 37% slower, then 77% slower, now 18%.** A character loop costs about 4 us per
   call on this VM and a `signal` block about 11 us just to enter. The final `isdecimal` uses a few
   built-in string calls, and `parsefloat` uses one `verify` call plus the runtime's own
   conversion. Both were checked against the original character-loop version on all 813,616
   strings of length 0 to 5 over the alphabet `0-9 + - . e E`: no differences.

## 4. Gains and losses

| | Gain | Loss |
|---|---|---|
| Results | Identical on all 32 workloads. LOGO and the other two now share one definition of what a number is | LOGO: whitespace now includes VT and FF; numbers with surrounding blanks no longer pass |
| Speed | Output and run-time behaviour unchanged for ordinary programs | 3 to 4% slower on average; 18% on number-parse-heavy BASIC; about 3 ms extra start-up |
| Code | 10 to 34 fewer lines per interpreter; duplicated output, character-class and float-literal code removed; 108 conformance cases cover the shared code | Each language now depends on a submodule and a build step; module sizes add 4 to 7% to the compiled size |
| Maintenance | A fix to number syntax or output handling is made once | Exposed names can collide (found twice); an API change in CRE can break three languages |
| Not yet | | Error models and file I/O are still private to each language, so most of the duplication remains |

## 5. Caveats

- One machine, one VM build, two cores; no repeated sessions. Treat differences under 5% as noise.
- Separate `.rxbin` files were measured. Linking everything into one file gave the same start-up
  time in one spot check (SNOBOL hello); cross-file inlining was not studied.
- The synthetic programs are chosen to hit the changed code; real programs sit between them
  and the regression tests.
- The CRE modules are validated, not tuned. The cost model above (about 0.5 us per string
  built-in, 11 us per signal block) suggests where more time can be saved.
