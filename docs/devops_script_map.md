# DevOps Script Map

This note shows how the runtime scripts are organized for local runs, cluster runs, and MEX/codegen support.

## Execution Diagram

```mermaid
flowchart TD
    subgraph Entry["Entry Points"]
        RA["run_abm.m<br/>Local multi-scenario runner"]
        RB["run_batch.m<br/>Cluster batch submitter"]
        RS["run_and_save_scenario.m<br/>Cluster task wrapper"]
        RSS["run_single_seed_scenario.m<br/>Serial cluster smoke test"]
        RSH["run.sh<br/>Legacy shell wrapper"]
    end

    subgraph Config["Runtime Options"]
        RO["resolve_output_options.m<br/>Heavy diagnostics on or off"]
    end

    subgraph Engine["Simulation Engine"]
        SAMC["simulate_abm_mc.m<br/>Seed-level Monte Carlo orchestration"]
        CACHE["build_simulation_cache.m<br/>Load data and expand firm indices"]
        SA["simulate_abm.m<br/>Build period-0 state and initial matching"]
        ABM["abm.m<br/>Quarter loop"]
    end

    subgraph Kernels["Core Kernels"]
        SM["search_and_matching.m<br/>Goods matching hotspot"]
        SML["search_and_matching_labor.m<br/>Labor matching"]
        SMC["search_and_matching_credit.m<br/>Credit matching"]
        PF["production_function.m<br/>Production and LP step"]
        SIC["sample_intermediate_consumption.m"]
        SFD["sample_final_demand.m"]
        SHUF["shuffle.m and sample.m"]
    end

    subgraph Data["Runtime Data"]
        PAR["model parameters MAT files"]
        IC["model initial_conditions MAT files"]
        SHOCK["model shock MAT files"]
        RESLOCAL["results MAT files<br/>Local output"]
        RESHOME["HOME results MAT files<br/>Cluster output"]
    end

    subgraph Build["Build / Performance Support"]
        GSM["generate_search_and_matching.m<br/>Build MEX"]
        MEX["search_and_matching mex binary<br/>Platform-specific compiled kernel"]
        GSA["generate_simulate_abm.m<br/>Experimental codegen path"]
        GSAMC["generate_simulate_abm_mc.m<br/>Experimental codegen path"]
    end

    RA --> RO
    RA --> SAMC
    RA --> RESLOCAL

    RB --> RS
    RS --> RO
    RS --> SAMC
    RS --> RESHOME

    RSS --> RO
    RSS --> CACHE
    RSS --> SA
    RSS --> RESHOME

    RSH --> SA

    SAMC --> CACHE
    SAMC --> SA

    CACHE --> PAR
    CACHE --> IC
    CACHE --> SHOCK

    SA --> SM
    SA --> ABM

    ABM --> SM
    ABM --> SML
    ABM --> SMC
    ABM --> PF

    SM --> SIC
    SM --> SFD
    SIC --> SHUF
    SFD --> SHUF

    GSM --> MEX
    MEX --> SM
    GSA --> SA
    GSAMC --> SAMC
```

## Operational Grouping

| Layer | Main scripts | Purpose |
|---|---|---|
| User entry points | `run_abm.m`, `run_batch.m`, `run_single_seed_scenario.m` | Start local, cluster, or serial smoke-test runs |
| Cluster wrapper | `run_and_save_scenario.m` | Per-job cluster task that calls the Monte Carlo engine and saves outputs |
| Monte Carlo orchestration | `simulate_abm_mc.m` | Allocates seed output tensors and runs one `simulate_abm` call per seed |
| Shared setup | `build_simulation_cache.m` | Loads `.mat` inputs and expands country/sector/firm lookup structures |
| Single-seed engine | `simulate_abm.m` | Builds the initial economy state, computes period-0 outputs, and calls `abm` |
| Quarter dynamics | `abm.m` | Runs the per-quarter economic simulation |
| Hot kernels | `search_and_matching*.m`, `production_function.m` | Goods, labor, credit, and production bottlenecks |
| Data | `model/parameters`, `model/initial_conditions`, `model/shock` | Static inputs loaded by the cache builder |
| Build support | `generate_search_and_matching.m` | Generates platform-specific `search_and_matching.mex*` binaries |

## Local vs Cluster

- Local default path:
  - `run_abm.m -> simulate_abm_mc.m -> build_simulation_cache.m -> simulate_abm.m -> abm.m`
  - saves to `results/`

- Cluster batch path:
  - `run_batch.m -> batch(...) -> run_and_save_scenario.m -> simulate_abm_mc.m`
  - saves to `$HOME/results/`

- Serial cluster smoke-test path:
  - `run_single_seed_scenario.m -> build_simulation_cache.m -> simulate_abm.m`
  - used to isolate startup/runtime behavior without `parfor`

## DevOps Notes

- `search_and_matching` is the main compiled hotspot. The cluster must have a Linux `search_and_matching.mexa64` on its runtime path.
- `build_simulation_cache.m` is the central file for data-path resolution and scenario shock loading.
- `simulate_abm_mc.m` is the place to inspect if jobs return zero-filled arrays, because seed failures happen there.
- `generate_simulate_abm*.m` exists, but the top-level codegen path has been experimental and not the main production route.
- `run.sh` appears to be a legacy helper and is not the main current batch path.
