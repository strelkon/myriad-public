function run_batch(scale, T, seeds, workers, output_options)
% run_batch - Submit batch jobs for all shock scenarios to HPC cluster
%   scale:   firm scale ratio (e.g., 1/100 for 1:100) (default: 1/1000)
%   T:       number of quarters to simulate (default: 12)
%   seeds:   number of Monte Carlo seeds (default: 500)
%   workers: number of parallel workers per job (default: 32)
%   output_options: output selection options (default: light diagnostics)
%
% All scenarios are submitted simultaneously for parallel execution
% on the cluster. Each job uses a pool of 'workers' CPUs to run
% 'seeds' Monte Carlo iterations via parfor.
%
% Scenarios:
%   S0 = Baseline (no shock)
%   S1 = Single Flood

if nargin < 1, scale = 1/1000; end
if nargin < 2, T = 12; end
if nargin < 3, seeds = 500; end
if nargin < 4, workers = 32; end
if nargin < 5
    output_options = struct( ...
        'include_heavy_diagnostics', false, ...
        'log_worker_lifecycle', true);
end

output_options = resolve_output_options(output_options);

year = 2023;
quarter = 4;

% Match run_abm defaults: baseline and single-flood, no credit constraints.
scenarios = {
    'S0', 0;
    'S1', 0;
};

% Initialize cluster connection
c = parcluster('UniCC production SFTP -  R2025b');
c.AdditionalProperties.Partition = 'generic';
c.AdditionalProperties.MemPerCPU = '2gb';
c.AdditionalProperties.AdditionalSubmitArgs = iAppendSubmitArg( ...
    c.AdditionalProperties.AdditionalSubmitArgs, ...
    '--output=%x_%j_main.log');

% Pre-allocate job arrays
num_scenarios = size(scenarios, 1);
jobs = cell(num_scenarios, 1);
job_names = cell(num_scenarios, 1);

% Submit all jobs simultaneously
fprintf('Submitting %d scenarios (seeds=%d, workers=%d, T=%d, scale=1:%d)...\n', ...
    num_scenarios, seeds, workers, T, round(1/scale));
submission_start = tic;

for i = 1:num_scenarios
    scenario = scenarios{i,1};
    constraints = scenarios{i,2};
    job_names{i} = sprintf('%s_C%d', scenario, constraints);

    jobs{i} = batch(c, 'run_and_save_scenario', 0, ...
        {year, quarter, T, scenario, scale, seeds, constraints, output_options}, ...
        'Pool', workers, 'CurrentFolder', '.');

    fprintf('  [%d/%d] Submitted: %s\n', i, num_scenarios, job_names{i});
end

submission_time = toc(submission_start);
fprintf('\nAll %d jobs submitted in %.1f seconds.\n', num_scenarios, submission_time);
fprintf('Jobs are now running in parallel on the cluster.\n\n');

% Wait for all jobs to complete
fprintf('Waiting for jobs to complete...\n');
wait_start = tic;

for i = 1:num_scenarios
    wait(jobs{i});
    job_state = jobs{i}.State;
    if strcmp(job_state, 'finished')
        fprintf('  [%d/%d] Completed: %s (%.1f min elapsed)\n', ...
            i, num_scenarios, job_names{i}, toc(wait_start)/60);
    else
        fprintf('  [%d/%d] %s: %s (state: %s)\n', ...
            i, num_scenarios, job_names{i}, job_state);
    end
end

total_time = toc(wait_start);
fprintf('\nAll jobs finished in %.1f minutes (%.1f seconds).\n', ...
    total_time/60, total_time);

% Report any failures
failed_jobs = {};
for i = 1:num_scenarios
    task_error = [];
    if ~isempty(jobs{i}.Tasks)
        task_error = jobs{i}.Tasks(1).Error;
    end
    if ~strcmp(jobs{i}.State, 'finished') || ~isempty(task_error)
        failed_jobs{end+1} = job_names{i}; %#ok<AGROW>
    end
end

if ~isempty(failed_jobs)
    fprintf('\nWARNING: %d job(s) did not complete successfully:\n', length(failed_jobs));
    for i = 1:length(failed_jobs)
        fprintf('  - %s\n', failed_jobs{i});
    end
else
    fprintf('\nAll scenarios completed successfully!\n');
end
end

function submit_args = iAppendSubmitArg(existing_args, new_arg)
if isempty(existing_args)
    submit_args = new_arg;
    return;
end

existing_args = strtrim(char(existing_args));
if contains(existing_args, new_arg)
    submit_args = existing_args;
else
    submit_args = strtrim([existing_args, ' ', new_arg]);
end
end
