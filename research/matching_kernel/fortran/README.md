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

### Completed full-baseline measurements (17 November 2026)

Both cluster batches completed successfully on `compute4`: S0 baseline, 2023Q4
calibration, seeds 1-10, 12 quarters, isolated Fortran implementation, ten
simulation workers plus one coordinator per batch. Both jobs began immediately,
with no scheduler wait in this experiment. The jobs shared the node and overlapped
for the first minute of the larger-scale run.

| Scale | Mean per seed | Per-seed range | Ten-seed workload | Full cluster allocation |
| --- | --- | --- | --- | --- |
| 1:1000 | 2m 01s | 1m 54s-2m 06s | 2m 08s | 2m 38s |
| 1:100 | 38m 22s | 36m 02s-39m 39s | 39m 41s | 40m 11s |

Per-seed times include loading, initialization and all twelve quarters, but
exclude writing the seed output file. Ten-seed workload time includes output
saving and ensemble construction. Full cluster allocation time also includes
worker startup and shutdown; it excludes queueing. These are ten concurrent
seeds, not ten serial runs. A practical planning estimate at these settings is
about three minutes at 1:1000 and forty minutes at 1:100, plus any future queue
wait. Different node load, worker counts, horizons and scenarios can change this.

Exact mean seed times were 121.0345025 and 2302.2529707 seconds; workload times
were 127.652266 and 2380.608092 seconds. Slurm jobs 3233083 and 3233084 completed
with exit code 0 and allocation elapsed times of 158 and 2411 seconds, respectively.
Every seed produced finite nominal and real GDP, a 13-by-26 GDP array (initial
state plus twelve quarters), and no all-zero simulated quarter. All 20 seed
output files, final RNG states, two GDP ensembles and timing records were saved.
These are validity and runtime checks; no new full-length C/Fortran trajectory
comparison was performed for these batches.

Raw results are retained under `post_tools/full_baseline_fortran_20261117` on
the cluster and `output/full_baseline_fortran_20261117/results` in the Macro MIP
workspace. Model-source and kernel checksums matched before/after the runs.
The production MEX remained unchanged; only the isolated research version ran.

## Paired macroMIP shock comparison

`compare_macromip.m` compares the original archived macroMIP matching binary
with the Fortran binary, holding the entire archived macroMIP model fixed.
The selected experiment is `macro_mip_1-p-4`, 2017Q4 calibration, scale 1:1000,
12 quarters and seeds 1-10. It also compares each fresh output against the same
seed in the archived 100-member scenario. It does not compare a ten-member mean
against the original hundred-member mean.

Copy the driver to a fresh experiment directory with `original/` and `fortran/`
subdirectories, each containing the appropriate `search_and_matching.mexa64`.
Review the archived-model and result-file paths in the driver. Submit through
the licensed MATLAB profile with Pool=10, AutoAttachFiles=false, the experiment
directory as CurrentFolder and AdditionalPaths, 8 GiB per CPU and two hours.
The initial job ran on one node. No archived input, model or output is modified.

The driver alternates implementation order across odd/even seeds, asserts
which model and kernel are selected, and checks all returned fields with
`isequaln`. It saves per-output mismatch counts and maximum finite absolute
differences, per-seed outputs, and both post-run RNG states. Timings exclude
the common cache build and output saving. GDP must be finite and no simulated
quarter may be all zero. Disabled diagnostics are compared as empty fields.
Archive files have no saved post-run RNG, so RNG equality is checked between
the two fresh implementations. Exactness still uses MATLAB's `isequaln`
convention for NaNs and signed zeros.

### Completed macroMIP comparison (17 November 2026)

The persistent Pair 1 shock (`macro_mip_1-p-4`), 2017Q4 calibration, scale 1:1000,
12 quarters and seeds 1-10 passed every comparison on cluster node `compute1`.
The rest of the model was held at the archived macroMIP commit
`a1674cd18467068af3bfddc53ca5acea9e9f6ddc`; only the matching binary changed.

- All 46 returned fields matched per seed: 39 populated outputs and seven empty,
  disabled diagnostic fields. There were 460 array comparisons, including 390
  populated arrays containing 1,365,650 numerical values in total.
- Fresh original and Fortran outputs were identical under `isequaln`, with zero
  differing elements, zero maximum finite absolute difference and zero nonfinite
  mismatches. This covers GDP, gross output, GVA, consumption, investment, trade,
  government and financial variables, including the returned sectoral arrays.
- Both implementations reproduced the same ten seed members in the archived
  100-member macroMIP result file exactly. No comparison of unmatched ensemble
  means was used.
- All ten final RNG-state structures matched between the fresh original and
  Fortran runs. The archive did not contain post-run RNG states.
- All twenty fresh simulations had finite nominal/real GDP and no all-zero
  simulated quarter. The source, calibration, shock, archive and binary checksums
  remained unchanged during the experiment.

Mean simulation time was 528.969501 seconds for the original and 145.695464
seconds for Fortran: 3.6307x speedup, or 72.46% less time. These full-simulation
measurements exclude the common cache build and saving. Order was alternated
across seeds, with ten workers on the same shared node. This comparison includes
all accumulated matching improvements relative to the archived original; it is
not an estimate of the Fortran language contribution alone. The paired job ran
both implementations for every seed and completed with Slurm exit 0, job 3233216,
in 12m 45s including startup and shutdown.

Raw seed outputs, RNG states and per-variable comparison records are retained
under `post_tools/macromip_fortran_compare_20261117` on the cluster and
`output/macromip_fortran_compare_20261117/results` in the Macro MIP workspace.
The local `variable_comparisons.csv` contains all 460 field comparisons.
This validates the selected shock, ten seeds and twelve-quarter horizon; it is
not an exhaustive regression of every macroMIP scenario or seed. Production
binaries and archived results were not replaced.

## Scale 1:10 memory pilot

`run_scale10_seed(seed)` runs S0 with 2023Q4 calibration, scale 1:10, one
simulated quarter and the isolated Fortran matching binary. Submit seeds 1-10
as separate licensed MATLAB batch jobs, each with Pool=0, one CPU, 32 GiB RAM
and a four-hour wall-time limit. Use a fresh experiment directory as
CurrentFolder and AdditionalPaths, AutoAttachFiles=false, and upload the driver
first. Review its model, support and kernel paths before reuse.

Separate jobs provide a distinct memory allocation and Slurm memory record for
each seed. The driver also records Linux `/proc/self/status` VmHWM (resident
memory high-water mark) for the MATLAB process, explicitly labelled in KiB.
VmPeak is virtual memory and must not be interpreted as physical RAM used.
One computational thread is used. Timing includes loading, initialization and
one quarter; saving has a separate timer. The usual lightweight diagnostics
are retained, reviewer matching and credit constraints are disabled, and all
outputs plus the final RNG state are saved. GDP must be finite, have the
expected 2-by-26 shape and contain a nonzero simulated quarter.

The pilot measures actual peak memory at 1:10; it does not establish the peak
for a longer horizon or every scenario. Raw outputs and accounting records
remain outside Git. The production model is not changed.

### Completed 1:10 pilot (18 November 2026)

All ten S0 seeds completed one simulated quarter at scale 1:10 using the Fortran
kernel, 2023Q4 calibration and the lightweight diagnostic configuration. Each
seed ran as a separate one-CPU cluster job with a verified 32-GiB allocation.
All ten ran on the shared `compute5` node and exited successfully (Slurm jobs
3234556-3234565, exit code 0). Model, calibration and kernel checksums were
unchanged during the runs. No local model simulation was performed.

| Measurement | Observed result |
| --- | --- |
| Mean simulation time per seed | 1h 54m 05s |
| Simulation-time range | 1h 43m 31s-2h 00m 40s |
| Entire ten-job span, including startup/shutdown | 2h 01m 24s |
| MATLAB process peak resident memory range | 10.16-10.26 GiB |
| Highest Slurm-recorded job memory peak | 10.34 GiB |
| Allocated RAM per seed | 32 GiB |

Simulation times include loading, initialization and one simulated quarter;
they exclude output saving and worker startup/shutdown. The cohort span runs
from the first job start to the last job end. Individual queue waits were 0-3
seconds. This is a ten-job concurrent workload, and the timing reflects the
shared-node conditions during this experiment.

Process memory uses Linux VmHWM, converted from KiB to GiB by dividing by
1,048,576. Slurm MaxRSS is reported separately because it has a different scope
and sampling method. VmPeak is virtual memory and is not the RAM requirement.
The largest recorded peak across these measurements was 10.336 GiB, leaving
substantial headroom within the requested 32 GiB. The earlier tenfold-memory
extrapolation was conservative; this pilot provides direct per-seed evidence.
These observations apply to one quarter with these diagnostic settings, not
an established maximum for every scenario or a full twelve-quarter horizon.

All ten seeds returned finite nominal and real GDP, a nonzero simulated quarter,
and the expected 2-by-26 GDP arrays. Full output cells and final RNG states were
saved per seed. This was a runtime/memory/validity pilot, not a new original-C
versus-Fortran numerical equivalence comparison at 1:10.

`collect_scale10.m` combines the ten completed members, their RNG states,
output-variable names, GDP arrays and ensemble means into `ensemble.mat`.
Run this collector only after all ten seed-completion files exist. It can use
a separate small cluster job; its aggregation time is excluded above.

Raw results are retained under `post_tools/scale10_quarter_20261118` on the
cluster and `output/scale10_quarter_20261118/results` in the Macro MIP workspace.
The local `seed_timings_memory.csv` and `summary.json` contain per-seed figures.
Production model files and binaries were not replaced.

For paper simulations using reviewer matching and reconstruction accounting, see the [ECOLEC revised shuffle](ecolec/README.md).
