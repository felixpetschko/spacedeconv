# Validation on 2026-09-24

One default suite was run against the local source in `spacedeconv-env`:

- 67 test blocks; 557 successful assertions.
- No failed numerical/structural assertions; one backend error.
- Eight explicitly skipped tests; eleven recorded warnings.
- Wall time about 295 seconds, including package loading, with single-threaded
  BLAS/OpenMP. Timing applies to this environment and the tests actually run;
  installing missing backends will increase it.

All 40 exported functions have test cases, plus the exported method registry.
This is an API inventory, not a measured statement of 100% line/branch coverage.
No covr measurement was run (covr is not installed in the current environment).

## Remaining error

SPOTlight's automatic marker calculation fails inside `scran::scoreMarkers()` /
`.cross_reference_to_desired()` with `'match' requires vector arguments` in the
installed environment (scran 1.30.0). It also fails when called directly on the
fixture with either character or factor group labels. The test deliberately
reports an error rather than hiding it with a skip.

The separate real SPOTlight test with explicitly supplied markers passes,
including dominant-cell-type recovery. In total, 16 distinct deconvolution
methods completed a successful real run; SPOTlight's automatic path still needs
investigation despite its supplied-marker path working.

## Not executed

- CIBERSORT and CIBERSORT absolute: licensed script and signature paths missing.
- CARD: the installed CARD backend attempts to load MuSiC, which is absent.
- DOT: its upstream R package, `DOTr`, is absent.
- AUCell, fgsea, MDT and VIPER activity scoring: AUCell, fgsea, ranger and viper,
  respectively, are absent.

Missing requirements are not counted as successful tests. The runner returns a
nonzero status for errors or incomplete coverage. No existing environment
packages were upgraded or replaced during this work.

Warnings include upstream GSVA deprecations, PCA sizing on small fixtures,
constant expression genes, and missing markers for some mMCPcounter populations.
The mouse fixture does not validate every mMCPcounter population. These tests
check basic software behavior; they are not a benchmark of biological accuracy.

## Artifacts

The ignored `test-results/final/` directory contains `results.csv`, `results.rds`,
`issues.txt` and `session-info.txt`. The full log is `test-results/final.log`.
These are local validation artifacts, not tracked source files.

Two deliberate in-memory mutations were detected: positional spot assignment
and incorrect aggregation. R/Python syntax and `git diff --check` were also
checked. No full `R CMD check` was run, and GitHub CI remains disabled.
