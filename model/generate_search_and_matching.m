% SEARCH_AND_MATCHING_SCRIPT   Generate MEX-function search_and_matching from
%  search_and_matching.
% 
% Script generated from project 'search_and_matching.prj' on 29-May-2021.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.GenerateReport = false;
cfg.ReportPotentialDifferences = false;
cfg.EnableOpenMP = false;

%% Define argument types for entry-point 'search_and_matching'.
ARGS = cell(1,1);
ARGS{1} = cell(29,1);
ARGS{1}{1} = coder.typeof(0,[1 Inf]);
ARGS{1}{2} = coder.typeof(0,[1 Inf]);
ARGS{1}{3} = coder.typeof(0,[1 Inf]);
ARGS{1}{4} = coder.typeof(0,[1 Inf]);
ARGS{1}{5} = coder.typeof(0,[1 Inf]);
ARGS{1}{6} = coder.typeof(0,[1 Inf]);
ARGS{1}{7} = coder.typeof(0,[1 Inf]);
ARGS{1}{8} = coder.typeof(0,[1 Inf]);
ARGS{1}{9} = coder.typeof(0,[1 Inf]);
ARGS{1}{10} = coder.typeof(0,[62 62 26]);
ARGS{1}{11} = coder.typeof(0,[1 Inf]);
ARGS{1}{12} = coder.typeof(0,[62 26]);
ARGS{1}{13} = coder.typeof(0,[1 Inf]);
ARGS{1}{14} = coder.typeof(0,[62 26]);
ARGS{1}{15} = coder.typeof(0,[1 Inf]);
ARGS{1}{16} = coder.typeof(0,[62 26]);
ARGS{1}{17} = coder.typeof(0,[1 Inf]);
ARGS{1}{18} = coder.typeof(0,[62 26]);
ARGS{1}{19} = coder.typeof(0,[1 26]);
ARGS{1}{20} = coder.typeof(0,[62  1]);
ARGS{1}{21} = coder.typeof(0,[1 Inf]);
ARGS{1}{22} = coder.typeof(0);
ARGS{1}{23} = coder.typeof(0,[1 Inf]);
ARGS{1}{24} = coder.typeof(0,[1 Inf]);
ARGS{1}{25} = coder.typeof(0,[27 26 62 62]);
ARGS{1}{26} = coder.typeof(0,[27 26 62]);
ARGS{1}{27} = coder.typeof(0,[27 26 62]);
ARGS{1}{28} = coder.typeof(0,[27 26 62]);
ARGS{1}{29} = coder.typeof(0,[27 26 62]);
ARGS{1}{30} = coder.typeof(0,[26 62]);

%% Invoke MATLAB Coder.
codegen -config cfg -o search_and_matching search_and_matching -args ARGS{1}

