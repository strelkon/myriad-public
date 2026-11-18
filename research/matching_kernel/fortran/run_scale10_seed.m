function run_scale10_seed(seed)
% One independent cluster job per seed, with a 32-GiB allocation.
root=fileparts(mfilename('fullpath'));prefix=fullfile(root,sprintf('seed_%02d',seed));
assert(~isfile([prefix '_complete.json']),'This seed has already completed.');
kernel='/home/strelkon/post_tools/matching_fortran_20261117/candidate';
addpath('/home/strelkon/post_tools/matching_benchmark_20261116/support','-end');
addpath('/home/strelkon','-begin');cd(kernel);clear search_and_matching;
assert(strcmp(which('search_and_matching'),fullfile(kernel,'search_and_matching.mexa64')));
maxNumCompThreads(1);
record=struct('seed',seed,'scenario','S0','year',2023,'quarter',4,'scale_denominator',10,'simulated_quarters',1, ...
 'start_utc',utcnow,'node',getenv('SLURMD_NODENAME'),'slurm_job_id',getenv('SLURM_JOB_ID'), ...
 'matlab_version',version,'pid',feature('getpid'),'kernel',which('search_and_matching'),'requested_memory_gib',32);
writejson([prefix '_running.json'],record);
try
options=struct('include_heavy_diagnostics',false,'reviewer_options',struct('enabled',false));
outputs=cell(1,nargout('simulate_abm'));clock=tic;
[outputs{:}]=simulate_abm(2023,4,seed,'S0',1/10,1,0,[],options);
record.simulation_seconds=toc(clock);post_rng=rng;
record.finite_gdp=all(isfinite(outputs{1}),'all')&&all(isfinite(outputs{2}),'all');
record.nonzero_quarter=any(outputs{2}(2,:)~=0);record.gdp_size=size(outputs{2});
assert(record.finite_gdp&&record.nonzero_quarter&&isequal(record.gdp_size,[2 26]),'Invalid GDP results.');
record.compute_end_utc=utcnow;
record.process_memory=process_memory;
save([prefix '.mat'],'outputs','post_rng','record','options','-v7.3');
record.seconds_including_save=toc(clock);record.end_utc=utcnow;
record.process_memory=process_memory;
writejson([prefix '_complete.json'],record);
catch e
record.end_utc=utcnow;record.message=e.message;record.report=getReport(e,'extended','hyperlinks','off');
record.process_memory=process_memory;writejson([prefix '_error.json'],record);rethrow(e)
end
end
function m=process_memory
m=struct();s=fileread('/proc/self/status');
for key={'VmHWM','VmRSS','VmPeak'}
 token=regexp(s,[key{1} ':\s+(\d+)\s+kB'],'tokens','once');
 if ~isempty(token),m.([key{1} '_KiB'])=str2double(token{1});end
end
end
function t=utcnow
t=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
function writejson(path,data)
f=fopen([path '.tmp'],'w');assert(f>=0);fprintf(f,'%s',jsonencode(data,PrettyPrint=true));fclose(f);movefile([path '.tmp'],path,'f');
end
