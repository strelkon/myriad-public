# ECOLEC reviewer matching with the revised shuffle

This is the Fortran matching routine and MATLAB gateway used for the ECOLEC paper benchmark. It retains reviewer order handling, delivered-use accounting and reconstruction diagnostics. The shuffle draws uniforms from MATLAB and uses stable radix sorting to carry each buyer ID alongside its key.

## Reuse on IIASA

The tested Linux binary is at `/home/strelkon/post_tools/ecolec_shuffle100/model/search_and_matching_review_mex.mexa64`. The reference paper model and its dependencies are under `/home/strelkon/post_tools/reviewer_fortran_scale_20261118`.

To rebuild, copy this directory to a writable cluster path without spaces. In MATLAB R2025b Update 3 on the cluster, change into that directory and run:

```matlab
mkdir('model')
build_reviewer_fortran
```

The script uses GCCcore 12.3.0 and writes the MEX file to the local `model` subdirectory. For a simulation, run the following setup on **each worker** before calling the usual ECOLEC scenario driver. Set `kernelDir` to the new build directory's `model` subdirectory if using a rebuilt binary.

```matlab
paperRoot = '/home/strelkon/post_tools/reviewer_fortran_scale_20261118';
kernelDir = '/home/strelkon/post_tools/ecolec_shuffle100/model';
addpath(fullfile(paperRoot,'model'), fullfile(paperRoot,'dependency'));
cd(kernelDir)
clear search_and_matching_review_mex
assert(strcmp(which('search_and_matching_review_mex'), ...
    fullfile(kernelDir,['search_and_matching_review_mex.' mexext])))
```

In the existing paper scenario options, set `options.reviewer_options.compiled_kernel = true` with reviewer matching enabled. Keep the worker in `kernelDir` during simulation so the tested binary takes precedence over the earlier binary in the paper model directory. Supply the calibration and shock directories explicitly as in the paper driver.

## Validation

On 19 November 2026, cluster job 3237721 compared both ECOLEC Fortran implementations using the 2023Q4 paper reference settings at 1:100 over 12 quarters. For S0 and compound M5, seeds 1 through 10, all 47 simulation result fields and all final MATLAB RNG states matched exactly under `isequaln`. Mean per-seed simulation times fell from 3476 to 2868 seconds for S0 and from 3475 to 2912 seconds for M5.
