% simulate_abm_SCRIPT   Generate executable simulate_abm from simulate_abm.
% 
% Script generated from project 'simulate_abm.prj' on 10-May-2019.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.CodeConfig'.
cfg = coder.config('exe','ecoder',false);
cfg.GenerateReport = true;
cfg.ReportPotentialDifferences = false;
cfg.GenerateComments = false;
cfg.EnableOpenMP = false;
cfg.BuildConfiguration = 'Faster Runs';
cfg.CustomSource = 'main_simulate_abm.c';
cfg.CustomLibrary = sprintf('/Applications/MATLAB_R2019b.app/bin/maci64/libmat.dylib\n/Applications/MATLAB_R2019b.app/bin/maci64/libmx.dylib');

%% Define argument types for entry-point 'simulate_abm'.
ARGS = cell(1,1);
ARGS{1} = cell(2,1);
ARGS{1}{1} = coder.typeof(0);
ARGS{1}{2} = coder.typeof(0);
ARGS{1}{3} = coder.typeof(0);
ARGS{1}{4} = coder.typeof(0);

%% Invoke MATLAB Coder.
codegen -config cfg simulate_abm -args ARGS{1}
