function run_full_baseline(denominator)
% Research-only full baseline timing: ten independent seeds, twelve quarters.
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,sprintf('scale_%d',denominator));
if ~isfolder(folder),mkdir(folder);end
assert(~isfile(fullfile(folder,'summary.json')),'A completed batch already exists.');
batch_start=utcnow;batch_clock=tic;
writejson(fullfile(folder,'status.json'),struct('phase','running','start_utc',batch_start,'job_id',getenv('SLURM_JOB_ID')));
try
records=cell(1,10);
parfor seed=1:10
 records{seed}=run_seed(folder,denominator,seed);
end
records=[records{:}];
nominal=cell(1,10);real=cell(1,10);
for seed=1:10
 data=load(fullfile(folder,sprintf('seed_%02d.mat',seed)),'outputs');
 nominal{seed}=data.outputs{1};real{seed}=data.outputs{2};
end
nominal_gdp=cat(3,nominal{:});real_gdp=cat(3,real{:});
mean_nominal_gdp=mean(nominal_gdp,3);mean_real_gdp=mean(real_gdp,3);
save(fullfile(folder,'ensemble.mat'),'nominal_gdp','real_gdp','mean_nominal_gdp','mean_real_gdp','records','-v7.3');
summary=struct('scenario','S0','denominator',denominator,'quarters',12,'seeds',1:10, ...
 'workers',10,'start_utc',batch_start,'end_utc',utcnow,'batch_seconds',toc(batch_clock), ...
 'mean_seed_seconds',mean([records.simulation_seconds]),'median_seed_seconds',median([records.simulation_seconds]), ...
 'min_seed_seconds',min([records.simulation_seconds]),'max_seed_seconds',max([records.simulation_seconds]), ...
 'sum_seed_seconds',sum([records.simulation_seconds]),'records',records);
writejson(fullfile(folder,'summary.json'),summary);
writejson(fullfile(folder,'status.json'),struct('phase','complete','end_utc',utcnow));
catch e
writejson(fullfile(folder,'error.json'),struct('message',e.message,'report',getReport(e,'extended','hyperlinks','off')));
writejson(fullfile(folder,'status.json'),struct('phase','failed','end_utc',utcnow));rethrow(e)
end
end
function record=run_seed(folder,denominator,seed)
kernel='/home/strelkon/post_tools/matching_fortran_20261117/candidate';
addpath('/home/strelkon/post_tools/matching_benchmark_20261116/support','-end');
addpath('/home/strelkon','-begin');cd(kernel);clear search_and_matching;
assert(strcmp(which('search_and_matching'),fullfile(kernel,'search_and_matching.mexa64')),'Wrong matching implementation selected.');
record=struct('seed',seed,'denominator',denominator,'start_utc',utcnow,'node',getenv('SLURMD_NODENAME'), ...
 'slurm_job_id',getenv('SLURM_JOB_ID'),'matlab_version',version,'kernel',which('search_and_matching'));
prefix=fullfile(folder,sprintf('seed_%02d',seed));writejson([prefix '_running.json'],record);
try
options=struct('include_heavy_diagnostics',false,'reviewer_options',struct('enabled',false));
outputs=cell(1,nargout('simulate_abm'));clock=tic;
[outputs{:}]=simulate_abm(2023,4,seed,'S0',1/denominator,12,0,[],options);
record.simulation_seconds=toc(clock);post_rng=rng;
record.finite_gdp=all(isfinite(outputs{1}),'all')&&all(isfinite(outputs{2}),'all');
record.nonzero_quarters=all(any(outputs{2}(2:end,:)~=0,2));
record.gdp_size=size(outputs{2});
assert(record.finite_gdp && record.nonzero_quarters,'Invalid or zero-filled GDP results.');
assert(size(outputs{2},1)==13,'Expected initial state and twelve quarters.');
record.compute_end_utc=utcnow;
save([prefix '.mat'],'outputs','post_rng','record','options','-v7.3');
record.seed_seconds_including_save=toc(clock);record.end_utc=utcnow;
writejson([prefix '_complete.json'],record);
catch e
writejson([prefix '_error.json'],struct('seed',seed,'message',e.message,'report',getReport(e,'extended','hyperlinks','off')));rethrow(e)
end
end
function t=utcnow
t=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
function writejson(path,data)
tmp=[path '.tmp'];f=fopen(tmp,'w');assert(f>=0);fprintf(f,'%s',jsonencode(data,PrettyPrint=true));fclose(f);movefile(tmp,path,'f');
end
