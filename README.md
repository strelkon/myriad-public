# MYRIAD

MYRIAD is a MATLAB-based multi-country agent-based macro simulation repository. It contains the core simulation engine, calibration scripts, scenario shock files, and batch tooling used to run local and cluster experiments across multiple geographic and sectoral scales.

This repository is organized for active maintenance work:

- local development and smoke tests
- cluster submission and runtime diagnostics
- reproducible scenario outputs for baseline and shock runs
- performance-sensitive matching kernels with platform-specific MEX support

## What Is In The Repository

- `model/`: main simulation engine, cluster wrappers, MEX generation, and runtime helpers
- `calibration/`: calibration and parameter-generation scripts
- `data/`: input datasets used to build model parameters and calibration assets
- `docs/`: maintainer and DevOps documentation
- `results/`: output directory for local runs; tracked outputs should not be committed

## Main Entry Points

- `model/run_abm.m`: local multi-scenario runner
- `model/run_batch.m`: cluster batch submitter
- `model/run_and_save_scenario.m`: cluster task wrapper used by `batch(...)`
- `model/run_single_seed_scenario.m`: serial smoke-test entry point for cluster diagnosis

## Prerequisites

- MATLAB R2025b or a compatible recent MATLAB release
- Parallel Computing Toolbox for `parfor`, `batch`, and cluster runs
- Optimization Toolbox for `linprog` in `production_function.m`
- Git LFS for tracked `.mat` and `.csv` assets

## Quick Start

Run a small local test from `model/`:

```matlab
run_abm(1/10000, 12, 14)
```

Run a single-seed smoke test on the cluster:

```matlab
opts = struct('include_heavy_diagnostics', false);
run_single_seed_scenario(2023, 4, 1, 'S0', 1/10000, 1, 0, opts)
```

Submit a cluster batch:

```matlab
opts = struct( ...
    'include_heavy_diagnostics', false, ...
    'log_worker_lifecycle', true);
run_batch(1/1000, 12, 32, 32, opts)
```

## Outputs

- Local runs save to `results/`
- Cluster runs save to `$HOME/results`
- Worker lifecycle logs save to `$HOME/worker_logs` when `log_worker_lifecycle` is enabled

Heavy diagnostics are disabled by default in the current local and cluster wrappers. This keeps default runs smaller and reduces memory pressure without changing core macro outputs such as GDP, GVA, trade, unemployment, debt, and credit-gap series.

## Performance Notes

- `search_and_matching` is the main goods-matching hotspot and should use a platform-appropriate MEX binary when available.
- Small-scale benchmarks run better with fewer workers than seeds so that pool startup is amortized.
- Large-scale runs can become memory-bandwidth-bound before they become CPU-bound.
- See `docs/devops_script_map.md` for the runtime layout.

## Development Workflow

- Read `AGENTS.md` before making nontrivial changes.
- Use small local smoke tests before longer cluster submissions.
- Do not commit generated results, copied cluster logs, or profiling artifacts.
- Keep maintainer-facing documentation in sync with changes to run paths or output locations.

## Open Source Status

This repository is public and documented for maintainer workflows, but it does not yet include an explicit project license. If you intend to reuse or redistribute the code or bundled data, coordinate with the maintainers before relying on any implied permissions.

