# Testing spacedeconv

There is one testthat suite, including real calls to every method in
`deconvolution_methods`. No release-only switch or opt-in method tests.

From the repository root:

```r
devtools::test()
```

For an additional CSV with per-test timings, RDS results and R/Python versions:

```sh
conda run --no-capture-output -p /scratch/c9881013/.conda_envs/spacedeconv-env \
  Rscript tools/test.R
```

The report is written to the ignored `test-results/` directory. An optional
first argument selects a different report directory. The runner exits with 1
for failures, 2 for an otherwise successful but incomplete (skipped) run, and 0
only when all tests execute successfully. `devtools::test()` uses testthat's
normal reporting/exit behavior and still displays skips.

## Environment and resources

Use a prepared R/Python environment with spacedeconv's dependencies. The package
currently requires its configured Conda environment even for R-only functions.
Tests must not install packages. On an HPC cluster run the same command inside
an appropriate CPU allocation. RCTD uses one core; some backends may create their
own workers. The report runner limits BLAS/OpenMP threads. Runtime includes real
model fitting and must be measured on the target environment.

CIBERSORT requires user-provided licensed files. Set these locally, never commit
them or credentials:

```sh
export SPACEDECONV_CIBERSORT_SCRIPT=/path/to/CIBERSORT.R
export SPACEDECONV_CIBERSORT_MATRIX=/path/to/LM22.txt
```

Missing licensed files or optional method packages produce an explicit skip.
Backend errors and numerical failures are failures, never converted into skips.
A run with skips is **not complete method coverage**.

## What the suite checks

- Small deterministic fixtures exercise numerical results, filtering, metadata,
  conversion, clustering, correlations, ligand-receptor scores and plotting.
- Real first-generation methods use six deterministic pseudobulks pooled from
  the bundled single-cell reference, retaining the spatial fixture coordinates. Mouse methods use mixtures of immunedeconv's mouse signature.
  These tests verify output contracts and numerical validity, not biological
  ground truth for the breast cancer sample.
- Reference-based methods use three strongly separated synthetic cell types,
  120 reference cells, 1,200 genes and 36 mixtures. They must recover the dominant
  type in at least 80% of spots. SPOTlight uses a subset of 150 genes and 30
  reference cells and a 200-iteration NMF limit to keep fitting small.
  Dominant-type recovery is still required. This is a basic sanity check, not a benchmark.
- cell2location uses actual CPU training (100 reference / 200 spatial epochs, 30 posterior samples),
  not production convergence settings. Its test checks basic recovery on easy
  mixtures; it does not establish scientific accuracy or convergence.
- All activity-scoring branches are exercised with a small local network.
- A user workflow covers preprocessing, deconvolution, aggregation and rendering.
- Targeted internal tests catch spot-order corruption, incomplete results and
  single-column dimension dropping. Plot tests inspect data and build the plot;
  they do not compare brittle pixel snapshots.
- Remote reference retrieval uses a controlled response at the network boundary;
  filtering and argument forwarding are checked without depending on live APIs.

Test fixtures are fresh per test. Random state, temporary configuration and
output files are restored with withr. Keep expensive computation inside tests,
not at file scope. Add a regression test with every bug fix. Expected results
should be independently calculated, not copied from the implementation.

## Maintenance

Keep `helper-methods.R` in sync with the public method registry; a test enforces
this. New public functions need a success case and relevant invalid-input cases.
The public API coverage inventory is in `api-coverage.csv`.

For investigation, testthat still supports filtering, e.g.
`devtools::test(filter = "conversion")`; this is not a separate suite.
Coverage measurement with `covr::package_coverage()` is optional and reruns tests,
including expensive methods. Use it to locate gaps, not to chase 100% coverage.

CARD additionally requires MuSiC at runtime. DOT needs its separate `DOTr` package.
Optional activity backends include AUCell, fgsea, ranger and viper. Missing
backends are reported individually. First-generation algorithms also depend on
immunedeconv's method-specific packages and bundled reference data. Remote
retrieval tests do not assert availability of the upstream network service.

## Corrections exposed while adding tests

The accompanying source changes fix spot-ID alignment (including activity
scores and SpatialDWLS), correlation coefficients being replaced by confidence
limits, single-spot dimension dropping, and a single-column immunedeconv result
conversion. Tests also exposed missing namespace qualification in orthology,
AnnData and plotting functions, custom ligand-receptor reference handling and
per-spot complex expression, and ignored supplied SPOTlight markers. SPOTlight training parameters can now
be forwarded through `build_model(..., maxIter = ...)`, retaining backend
defaults when omitted.

cell2location now respects `gpu = FALSE` during reference training and accepts
`posterior_samples` (default remains 1,000). Python functions and Giotto
instructions are kept local instead of creating R global bindings. Model
building accepts documented display names; normalization rejects unknown
methods. Defaults for valid normalization methods are unchanged.

Two temporary in-memory mutations (positional result insertion and incorrect
aggregation) were checked during development. Both caused the new tests to fail;
no mutated source was kept.

The existing GitHub Actions test/coverage triggers remain disabled. These changes
provide the local suite and report runner; they do not configure or enable a
remote CI runner.

See [TESTING_STATUS.md](TESTING_STATUS.md) for the implementation-time validation,
remaining backend error, missing prerequisites and measured runtime.
