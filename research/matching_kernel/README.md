# Matching-kernel research checkpoint

This isolated prototype preserves the tested C optimisation work before a Fortran
research rewrite. Production `model/` is deliberately unchanged.

## Saved implementation

`matlab/` contains lazy intermediate weights, shared final-demand preparation,
ordered active sets, compact country IDs, zero-delivery bookkeeping skips,
compact supplier indices and one-pass active-final-buyer filtering.

Generate portable C with MATLAB R2025b Update 3 from this directory's
`matlab/generate_search_and_matching.m` (MATLAB Coder required). Then run:

```
python3 patch_generated.py /path/to/codegen/mex/search_and_matching
```

This reapplies the stable radix sort and equivalent binary-search midpoint.
Compile with the previous MATLAB MEX interface, `-fwrapv -ffp-contract=off`,
C99, no fast-math and no parallel matching loop. Generated MathWorks C, MEX
binaries, calibration data, fixtures and raw profiling artifacts are not committed.

## Evidence as of 17 November 2026

Production 1:100 fixtures: 2023Q4 S0 seed 1, initial matching and quarter 1;
293,942 domestic firms, 15,850 foreign suppliers and 4,444,072 households.

Successive paired cluster comparisons found approximately 2.7-3.0x, then
1.57-1.58x, then 1.046x speedups. The combined 4.5-4.9x estimate is a chained
estimate across separate allocations, not a direct original/final benchmark.
The final step averaged 198.36 -> 189.71 seconds initially and
209.29 -> 200.18 seconds for quarter 1 (two runs per version).
All 16 numerical outputs and final MATLAB RNG state matched using `isequaln`.
The final assessment includes 48 smaller kernel comparisons, eight short GDP/RNG
simulation comparisons, 19 production invocations and two instrumented profiles.
All passed. These checks do not establish equivalence for all hazards/horizons.
Earlier larger screening gains were noisy; the final paired saving was 4.4%.

Cluster experiment directories (private, not embedded in the repository):
`post_tools/matching_benchmark_20261116`, `post_tools/matching_profile_20261116`,
and `post_tools/matching_sampling_arrays_20261116` under the researcher's home.
The unmodified production binary SHA-256 is
`78a820e77b66e6902f9e0c9eaa82138e0803e1669147e7d5f8424dd980fa27d9`.

## Research constraints

Preserve RNG calls/count/order, buyer and supplier ordering, sequential allocation,
and floating-point reduction order. No language rewrite is assumed to be faster.
Keep experiments isolated and compare all outputs plus RNG, then short simulations
and production-scale calls before drawing conclusions. `isequaln` does not compare
NaN payloads or signed-zero bits. Broader regression/build integration precedes any
production deployment.

Source checkpoint: local development commit `d047246`, based on `213b62e`.
This public branch retains the public repository history and adds only the
self-contained research sources and documentation.

## Fortran research implementation

The [Fortran implementation and reproduction instructions](fortran/README.md)
retain the MATLAB interface and RNG service. All 12 small comparisons, eight
production calls and two short simulation comparisons passed with identical
outputs and RNG states. The conservative observed matching-time reduction is
about 25-30% versus the optimized C checkpoint; see the detailed timing table
and variability caveat. This branch does not replace the production MEX.
