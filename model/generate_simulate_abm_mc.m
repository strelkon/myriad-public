% simulate_abm_mc_SCRIPT   Generate executable simulate_abm_mc from simulate_abm_mc.
% 
% Script generated from project 'simulate_abm_mc.prj' on 10-May-2019.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.CodeConfig'.
cfg = coder.config('exe','ecoder',false);
cfg.GenerateReport = true;
cfg.ReportPotentialDifferences = false;
cfg.GenerateComments = false;
cfg.EnableOpenMP = false;
cfg.BuildConfiguration = 'Faster Runs';
% cfg.CustomInclude = sprintf('/Applications/MATLAB_R2019b.app/extern/include\n');
cfg.CustomSource = 'main_simulate_abm_mc.c';
cfg.CustomLibrary = sprintf('/Applications/MATLAB_R2019b.app/bin/maci64/libmat.dylib\n/Applications/MATLAB_R2019b.app/bin/maci64/libmx.dylib');

%% Define argument types for entry-point 'simulate_abm_mc'.
ARGS = cell(1,1);
ARGS{1} = cell(2,1);
ARGS{1}{1} = coder.typeof(0);
ARGS{1}{2} = coder.typeof(0);
ARGS{1}{3} = coder.typeof(0);

%% Invoke MATLAB Coder.
codegen -config cfg simulate_abm_mc -args ARGS{1}
