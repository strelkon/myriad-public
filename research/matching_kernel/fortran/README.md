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
