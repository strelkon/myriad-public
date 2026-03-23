# AGENTS.md

This repository is an actively maintained MATLAB simulation codebase with large tracked data assets and expensive runtime paths. Keep changes conservative, reproducible, and easy to validate.

## Working Rules

- Default to small local smoke tests before touching cluster submission behavior.
- Do not commit generated outputs, copied cluster logs, or profiling artifacts.
- Keep edits ASCII unless the file already uses non-ASCII.
- Prefer minimal, surgical changes to hot code paths.

## Entry Points

- Local runs: `model/run_abm.m`
- Cluster runs: `model/run_batch.m`
- Cluster task wrapper: `model/run_and_save_scenario.m`
- Single-seed smoke tests: `model/run_single_seed_scenario.m`

Run MATLAB commands from `model/` unless the task explicitly needs a different working directory.

## Default Validation Path

For quick validation, prefer one of:

```matlab
run_abm(1/10000, 1, 1)
```

```matlab
opts = struct('include_heavy_diagnostics', false);
run_single_seed_scenario(2023, 4, 1, 'S0', 1/10000, 1, 0, opts)
```

When changing runtime-sensitive code, compare saved GDP outputs before and after on a small deterministic benchmark.

## Data And Outputs

- Input data lives under `model/parameters`, `model/initial_conditions`, and `model/shock`
- Large tracked assets use Git LFS
- Local outputs go to `results/`
- Cluster outputs go to `$HOME/results`
- Worker lifecycle logs go to `$HOME/worker_logs`

Do not move output locations casually. Cluster path changes are operationally significant.

## Cluster Notes

- `run_batch.m` assumes a configured MATLAB cluster profile
- Cluster jobs rely on `batch(...)` and the runtime wrappers in `model/`
- Worker-start and worker-end diagnostics are emitted when `log_worker_lifecycle` is enabled
- If jobs return zero-filled outputs, inspect `simulate_abm_mc.m` first

## Performance Notes

- `search_and_matching.m` is the primary hotspot
- `search_and_matching_labor.m`, `search_and_matching_credit.m`, and `production_function.m` are secondary hotspots
- Avoid changing RNG order unless exact output preservation is not required

## Documentation

If you change:

- output locations
- cluster submission behavior
- default runtime options
- validation commands

then update `README.md` and `docs/devops_script_map.md` in the same change.

