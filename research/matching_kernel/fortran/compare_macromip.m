function compare_macromip
root=fileparts(mfilename('fullpath'));
model='/hdrive/u056/strelkon/abm_results/MacroMIP_S1_2017Q4_20261116/model';
archive='/hdrive/u056/strelkon/abm_results/MacroMIP_S1_2017Q4_20261116/T12/macro_mip_1-p-4_2017Q4_1000.mat';
writejson(fullfile(root,'status.json'),struct('phase','running','time',utcnow,'job_id',getenv('SLURM_JOB_ID')));
try
addpath(model,'-begin');
tokens=regexp(fileread(fullfile(model,'simulate_abm.m')),'function\s*\[([^\]]+)\]','tokens','once');names=strtrim(strsplit(tokens{1},','));
assert(numel(names)==nargout('simulate_abm'));
records=cell(1,10);clock=tic;
parfor seed=1:10
 records{seed}=compare_seed(root,model,archive,names,seed);
end
records=[records{:}];
summary=struct('scenario','macro_mip_1-p-4','year',2017,'quarter',4,'scale_denominator',1000,'quarters',12,'seeds',1:10, ...
 'output_names',{names},'all_fresh_outputs_equal',all([records.fresh_equal]),'all_rng_equal',all([records.rng_equal]), ...
 'all_original_archive_equal',all([records.original_archive_equal]),'all_fortran_archive_equal',all([records.fortran_archive_equal]), ...
 'batch_seconds',toc(clock),'records',records);
writejson(fullfile(root,'summary.json'),summary);
writejson(fullfile(root,'status.json'),struct('phase','complete','time',utcnow));
catch e
writejson(fullfile(root,'error.json'),struct('message',e.message,'report',getReport(e,'extended','hyperlinks','off')));
writejson(fullfile(root,'status.json'),struct('phase','failed','time',utcnow));rethrow(e)
end
end
function record=compare_seed(root,model,archive,names,seed)
addpath(model,'-begin');
assert(strcmp(which('simulate_abm'),fullfile(model,'simulate_abm.m')));
assert(strcmp(which('abm'),fullfile(model,'abm.m')));
record=struct('seed',seed,'node',getenv('SLURMD_NODENAME'),'start_utc',utcnow);
prefix=fullfile(root,sprintf('seed_%02d',seed));writejson([prefix '_running.json'],record);
options=struct('include_heavy_diagnostics',false,'log_worker_lifecycle',false);
cache=build_simulation_cache(2017,4,'macro_mip_1-p-4',1/1000,12);
if mod(seed,2),order={'original','fortran'};else,order={'fortran','original'};end
for v=order
 folder=fullfile(root,v{1});cd(folder);clear search_and_matching;
 assert(strcmp(which('search_and_matching'),fullfile(folder,'search_and_matching.mexa64')));
 writejson([prefix '_phase.json'],struct('variant',v{1},'time',utcnow));
 out=cell(1,numel(names));clock=tic;
 [out{:}]=simulate_abm(2017,4,seed,'macro_mip_1-p-4',1/1000,12,0,cache,options);
 seconds=toc(clock);post_rng=rng;
 assert(all(isfinite(out{1}),'all')&&all(isfinite(out{2}),'all')&&all(any(out{2}(2:end,:)~=0,2)),'Invalid GDP output');
 save([prefix '_' v{1} '.mat'],'out','post_rng','seconds','names','options','-v7.3');
 if strcmp(v{1},'original'),A=out;R=post_rng;record.original_seconds=seconds;else,B=out;S=post_rng;record.fortran_seconds=seconds;end
end
saved=load(archive);assert(isequal(saved.seed_ids,1:100));
metrics=struct([]);
for k=1:numel(names)
 a=saved.(names{k});
 if isempty(a),ref=a;else
  indices=repmat({':'},1,ndims(a));indices{2}=seed;ref=a(indices{:});ref=reshape(ref,size(A{k}));
 end
 m=struct('output',names{k},'elements',numel(A{k}),'fresh_equal',isequaln(A{k},B{k}), ...
  'original_archive_equal',isequaln(A{k},ref),'fortran_archive_equal',isequaln(B{k},ref), ...
  'different_elements',0,'max_finite_abs_difference',0,'nonfinite_mismatches',0);
 assert(isequal(size(A{k}),size(B{k})),'Different output sizes');
 same=(A{k}==B{k})|(isnan(A{k})&isnan(B{k}));m.different_elements=sum(~same,'all');
 finite=isfinite(A{k})&isfinite(B{k});d=abs(A{k}(finite)-B{k}(finite));if ~isempty(d),m.max_finite_abs_difference=max(d);end
 m.nonfinite_mismatches=sum(~same&~finite,'all');
 if k==1,metrics=m;else,metrics(k)=m;end
end
record.fresh_equal=all([metrics.fresh_equal]);record.rng_equal=isequaln(R,S);
record.original_archive_equal=all([metrics.original_archive_equal]);record.fortran_archive_equal=all([metrics.fortran_archive_equal]);
record.outputs_compared=numel(names);record.nonempty_outputs=sum([metrics.elements]>0);record.end_utc=utcnow;
writejson([prefix '_metrics.json'],metrics);writejson([prefix '_complete.json'],record);
end
function t=utcnow
t=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
function writejson(path,data)
f=fopen([path '.tmp'],'w');assert(f>=0);fprintf(f,'%s',jsonencode(data,PrettyPrint=true));fclose(f);movefile([path '.tmp'],path,'f');
end
