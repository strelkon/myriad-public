# Contributing

Thanks for contributing to MYRIAD.

## Before You Start

- Read `README.md` for the project layout and runtime entry points.
- Read `AGENTS.md` for repository-specific engineering rules.
- Keep changes small and reviewable.

## Development Expectations

- Prefer local smoke tests before longer cluster runs.
- Preserve simulation outputs unless the change explicitly alters model behavior.
- If you change performance-sensitive code, compare a small before/after benchmark and document what changed.
- Do not commit generated results, worker logs, copied cluster logs, or profiling artifacts.

## Coding Guidelines

- Follow the existing MATLAB style in the touched file.
- Add comments only where the code would otherwise be difficult to understand.
- Keep cluster-path and output-path changes explicit and documented.
- When editing runtime defaults, update both code comments and user-facing docs.

## Suggested Validation

Typical quick checks from `model/`:

```matlab
run_abm(1/10000, 1, 1)
```

```matlab
opts = struct('include_heavy_diagnostics', false);
run_single_seed_scenario(2023, 4, 1, 'S0', 1/10000, 1, 0, opts)
```

For runtime-sensitive changes, compare GDP outputs across a small benchmark before and after.

## Pull Requests

Please include:

- a short description of the change
- whether outputs are expected to change
- the exact validation command(s) you ran
- any relevant runtime or memory observations

