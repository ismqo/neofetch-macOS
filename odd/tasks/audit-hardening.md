Objective: fix the audit's security, privacy and performance findings, with a regression test suite first.
Branch: fix/audit-hardening (base: main a1cf6c0). Delivery: ask-on-risk. Test runner: `make test` (tests/run.sh, bash 3.2).

## Specs

- S1: Tests first: "I'd add the tests from the previous suggestion first, so each fix can be checked."
  Fake system tools on PATH (system_profiler, ioreg, sysctl, uname, df, ...) give deterministic output;
  golden outputs for the default config, --json, field-only runs, --customize saves, custom-code
  configs, and an Intel/fallback path; `make test` runs it under bash 3.2 with no extra dependencies.
- S2: Disk parsing: "read the columns from the left and only accept a number as the percentage."
  Mount points with spaces show the right size/percent; a non-numeric percent never reaches arithmetic.
- S3: Escape-code injection: "print detected values with `%s` and strip control characters."
  Color sequences built by neofetch still render.
- S4: Fewer subshells: "make `trim`/`strip_sequences` set a variable instead of printing."
  Output unchanged; fewer forks per run.
- S5: Small items: "remove `eval_unsafe_arith`, clean up the `--customize` temp file on Ctrl-C, make the
  Makefile's home lookup safer, and fix the Shell version bug."

## Tasks

- T1 [S1] inline — test harness + golden outputs. Status: done (244c64d, 44f087e; RDD approved x2).
- T2 [S2] inline — disk parsing. Status: done (RED: garbled line + injected file; GREEN: 24/24).
- T3 [S3] inline — escape sanitization. Status: done (RED: ESC bytes in 5 cases; GREEN: 32/32; colored output unchanged).
- T4 [S4] inline — subshell reduction. Status: done (35/35 identical; --stdout 250->221ms, logo 253->215ms, cheap fields 74->47ms).
- T5 [S5] inline — small items. Status: done (d67afdd, a37d5cf; RED shown on old code for shell + interrupt; 41/41).
- T6 [S1-S5] delegated verify at feature end (Risk items 2/3/5). Status: done — S1-S5 met; 1 blocker (B1: config \e colors on disk labels printed literally) fixed in 41d1f3c and rechecked.

Route: all inline — one file (`neofetch`) shared by every unit, so no parallel writers.

## Log

- L1 (2026-10-24): "can you find for security, privacy and performance concerns?" → audit; user: "yes"
  to "Should I implement these? I'd add the tests from the previous suggestion first, so each fix can
  be checked."
- L2: Commits: 244c64d, 44f087e (tests; RDD approved), 99e2b4a (disk; RDD approved), ed493bd (escapes;
  RDD approved), 6756e58 (escape-before-bar fix; RDD declined), 09376fe (perf; under budget),
  d67afdd (shell + interrupt; slice RDD declined), a37d5cf (Makefile; RDD declined).
  Suite: 41/41. Timing: --stdout 250->221ms, logo 253->215ms.
- L3: Verifier: S1-S5 met; real-machine smoke identical to baseline (--stdout 0.24s -> 0.17s).
  B1 fixed in 41d1f3c (RDD declined), recheck passed, 42/42. Advisories left: `XDG_CONFIG_HOME=/`
  prints a misleading "not an absolute path" skip (harmless); sudo cleanup skips user names outside
  [A-Za-z0-9._-] (fails safe); `$(strip_sequences ...)` no longer prints (internal helper).
