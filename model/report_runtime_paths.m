function report_runtime_paths()
    fprintf('PWD=%s\n', pwd);
    fprintf('MEXEXT=%s\n', mexext);

    matches = which('search_and_matching', '-all');
    fprintf('SEARCH_AND_MATCHING_COUNT=%d\n', numel(matches));
    for i = 1:numel(matches)
        fprintf('SEARCH_AND_MATCHING_%d=%s\n', i, matches{i});
    end

    matches = which('run_single_seed_scenario', '-all');
    fprintf('RUN_SINGLE_SEED_SCENARIO_COUNT=%d\n', numel(matches));
    for i = 1:numel(matches)
        fprintf('RUN_SINGLE_SEED_SCENARIO_%d=%s\n', i, matches{i});
    end
end
