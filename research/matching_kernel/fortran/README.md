# Fortran matching experiment

`matching.f90` implements the matching kernel, weighted supplier sampling,
active-list handling, stable shuffle sorting and numerical reductions in Fortran.
It preserves the 30-input / 16-output MATLAB interface for the fixed 26-country,
62-sector model. This is an isolated research implementation, not a production
replacement or a general-purpose library.

## Exactness design

- MATLAB still supplies uniform random numbers through `emlrtRandu`; Fortran does
  not seed or use its own random-number generator. Calls retain the original
  count and order, including the no-draw singleton supplier case.
- Stable radix sorting orders the same uniform draws. Group processing, buyer
  ordering and sequential allocations follow the saved MATLAB/C implementation.
- The 1024/4096-element reduction tree follows MATLAB Coder rather than Fortran
  `SUM`. Arithmetic is compiled without reassociation or fused multiply-add.
- The power operation uses MATLAB's `muDoubleScalarPower` through a small C
  callback, retaining the existing rounding behavior for price weights.
- `make_gateway.py` generates a thin C adapter against locally generated MATLAB
  headers. The generated MEX API, allocation and runtime initialization remain
  in C. Generated helper C files may be linked but the replacement entry point
  delegates the matching computation to `matching_f`; there is no C fallback.
- No `fast-math`, parallel matching loop or replacement RNG is used.

## Reproduce on the cluster

1. Generate C from `../matlab/generate_search_and_matching.m` using MATLAB R2025b
   and MATLAB Coder. Keep generated sources outside Git. Build and verify the
   saved optimized C reference separately using `../patch_generated.py`.
2. Create a fresh experiment directory:

   ```sh
   python3 prepare.py --generated /path/to/codegen/mex/search_and_matching --output /path/to/experiment
   ```

3. Review the paths in the copied `test_fortran.m`. Its defaults reproduce the
   IIASA experiment: GCCcore 12.3.0, the saved optimized C reference, captured
   fixtures and the existing model/support directories under the researcher's
   home. The fixture folder contains `small_initial.mat`, `small_quarter.mat`,
   `production_initial.mat`, `production_quarter.mat`, each with `args` (30 cells)
   and `initial_rng`. Original baseline files in the parent directory contain
   `A` (16 output cells) and `R` (post-call RNG state).
4. Submit `test_fortran` through the existing licensed MATLAB cluster profile,
   with the experiment directory as CurrentFolder and AdditionalPaths,
   AutoAttachFiles=false, one CPU, 8 GB RAM and a two-hour wall time. Upload the
   prepared directory first. The worker builds Fortran and links the MEX locally.

The compiler flags are `-O2 -fPIC -ffp-contract=off
-fno-unsafe-math-optimizations -ffree-line-length-none`. The C adapter uses
`-fwrapv -ffp-contract=off -std=c99`; the linker records the GCC runtime path.
MATLAB, its toolboxes and the generated interface remain required; this is not
an independent standalone Fortran model. Generated files retain their own
licensing conditions and are not distributed here.

The test driver stops on a mismatch. It performs 12 small comparisons (two
fixtures, three supply conditions, two seeds), eight production calls (two
fixtures, two implementations, two repeats with reversed order), and two
short two-quarter simulation comparisons (seeds 1 and 2). All 16 outputs and the
post-call RNG state use `isequaln`; GDP checks also require finite results and
nonzero simulated quarters. Raw JSON records and binaries stay outside Git.
`isequaln` treats NaNs as equal and does not distinguish signed zero; these
checks do not establish equivalence for every scenario or exceptional input.

## Cluster validation completed 17 November 2026

All 12 small comparisons passed, including reduced and zero current supply.
All eight production calls matched the archived original C outputs and RNG
state. Both two-quarter simulation comparisons matched nominal GDP, real GDP
and RNG state, with finite GDP and nonzero simulated quarters. Equality used
`isequaln` for all 16 kernel outputs and the RNG-state structures.

Production 1:100 results, in seconds (two runs per implementation):

| Fixture | Optimized C runs | Fortran runs | C mean | Fortran mean | Mean time reduction |
| --- | --- | --- | --- | --- | --- |
| Initial | 187.401, 205.175 | 137.054, 137.634 | 196.288 | 137.344 | 30.0% |
| Quarter one | 318.983, 202.569 | 154.219, 148.737 | 260.776 | 151.478 | 41.9% |

The slower C quarter-one run materially raises that mean. Comparing the Fortran
mean against the faster C run gives a more conservative 26.7% initial and 25.2%
quarter-one time reduction (approximately 1.34-1.36x speedup). A cautious summary
is about 25-30% less matching time than the saved optimized C implementation.
These are exploratory kernel timings on a shared node, not a measured whole-model
speedup or a confidence interval. No repeated result was discarded from the table.

The paired order was C/F then F/C, in the same one-CPU allocation on `compute4`,
MATLAB R2025b Update 3, Slurm job 3232829 (COMPLETED, exit 0). Maximum recorded job
RSS was 2,778,784 KiB; this is job-wide and not a per-implementation comparison.
The Fortran core used GNU Fortran 12.3.0; the C reference and runtime adapter used
GCC 11.4.0. This compares concrete implementations with different compiler
versions and array handling; it does not isolate an inherent language advantage.

The production MEX remained unchanged. Its SHA-256 is
`78a820e77b66e6902f9e0c9eaa82138e0803e1669147e7d5f8424dd980fa27d9`.
The experimental Linux MEX SHA-256 is
`9bd67a73a195db75949e762ad218875df272c62610f506d579ae396b3539a1eb`.
The tested `matching.f90` SHA-256 is
`1d77301a659c921a3329f1e4f3eb6e0d30be4ff57add795121ef777089f49155`.

Private raw records remain in `post_tools/matching_fortran_20261117` on the
cluster, with local copies under `output/matching_fortran_20261117/results` in
the Macro MIP workspace. Neither generated sources, fixtures, binaries nor raw
cluster logs are committed. Broader scenario/horizon regression and deployment
integration remain prerequisites for using this prototype in production.

## Full baseline runtime experiment

`run_full_baseline(denominator)` runs S0, 2023Q4 calibration, seeds 1-10,
12 quarters, no credit constraints, and the isolated Fortran MEX. Copy the
driver into a separate cluster experiment directory and submit twice through
the licensed MATLAB profile, passing 1000 and 100 respectively. Each submission
uses Pool=10 (ten simulation workers plus one coordinator), AutoAttachFiles=false,
and the experiment directory as CurrentFolder and AdditionalPaths. The initial
run requested 4 GiB per CPU at 1:1000 and 16 GiB per CPU at 1:100, with a four-hour
limit. Review the kernel, model and support paths in the driver before reuse.

Each seed starts with an empty cache, so simulation timing includes calibration
loading and model initialization. All simulation outputs and final RNG states
are saved per seed; GDP ensembles and their means are saved after all ten finish.
The default lightweight output configuration is used (`include_heavy_diagnostics=false`,
with its default selected diagnostics retained), and reviewer matching is disabled.

Per-seed simulation seconds exclude saving; a second timer includes saving.
Batch seconds cover the driver's parallel workload and ensemble save, excluding
scheduler queueing and pool startup. Slurm accounting supplies allocation
elapsed time separately. Results must have finite GDP and twelve nonzero
simulated quarters. This is a full-run timing/validity test, not an additional
Fortran-versus-C trajectory comparison. Raw results remain outside Git.
