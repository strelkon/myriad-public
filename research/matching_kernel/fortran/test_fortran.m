function test_fortran
root=fileparts(mfilename('fullpath'));reference_folder='/home/strelkon/post_tools/matching_sampling_arrays_20261116/search_followup/candidate';timing_reference=reference_folder;old='/home/strelkon/post_tools/matching_benchmark_20261116';
try
writejson(fullfile(root,'metadata.json'),struct('version',version,'node',getenv('SLURMD_NODENAME'),'job_id',getenv('SLURM_JOB_ID')));
status(root,'building_fortran');candidate=fullfile(root,'candidate');build_linux_kernel(candidate);
status(root,'small_checks');checks=struct('fixture',{},'stress',{},'seed',{},'outputs_equal',{},'rng_equal',{},'equal_each',{});ix=0;
 for fixture={'small_initial.mat','small_quarter.mat'}
  data=load(fullfile(old,'fixtures',fixture{1}));
  for stress=1:3
   args=data.args;
   if stress==2,args{2}=0.05*args{2};args{3}=zeros(size(args{3}));args{7}=0.05*args{7};end
   if stress==3,args{2}=zeros(size(args{2}));args{3}=zeros(size(args{3}));args{7}=zeros(size(args{7}));end
   for seed=[1 7]
    rng(seed);state=rng;
    [A,R]=invoke(reference_folder,args,state);
    [B,S]=invoke(fullfile(root,'candidate'),args,state);
    ix=ix+1;checks(ix)=struct('fixture',fixture{1},'stress',stress,'seed',seed,'outputs_equal',isequaln(A,B),'rng_equal',isequaln(R,S),'equal_each',cellfun(@isequaln,A,B));
    writejson(fullfile(root,'small_checks.json'),checks);
    assert(checks(ix).outputs_equal && checks(ix).rng_equal,'cluster:Mismatch','Small check changed output or RNG.');
   end
  end
 end

results=struct('fixture',{},'repeat',{},'variant',{},'seconds',{},'outputs_equal',{},'rng_equal',{});ix=0;
for k=1:2
 fixtures={'production_initial.mat','production_quarter.mat'};fixture=fixtures{k};
 data=load(fullfile(old,'fixtures',fixture));reference=load(fullfile(old,[fixture '_baseline.mat']),'A','R');

 for rep=1:2
  if rep==1,variants={'reference','candidate'};else,variants={'candidate','reference'};end
  for v=variants
   status(root,sprintf('%s_%s_repeat%d',fixture,v{1},rep));
   if strcmp(v{1},'reference'),folder=timing_reference;else,folder=fullfile(root,'candidate');end
   [B,S,t]=invoke(folder,data.args,data.initial_rng);ix=ix+1;
   results(ix)=struct('fixture',fixture,'repeat',rep,'variant',v{1},'seconds',t,'outputs_equal',isequaln(reference.A,B),'rng_equal',isequaln(reference.R,S));
   writejson(fullfile(root,'timings.json'),results);assert(results(ix).outputs_equal&&results(ix).rng_equal);
  end
 end
end
status(root,'simulation_smoke');addpath(fullfile(old,'support'),'-end');addpath('/home/strelkon','-begin');
 smoke=struct('seed',{},'nominal_equal',{},'real_equal',{},'rng_equal',{},'finite_gdp',{},'nonzero_quarters',{});
 for seed=1:2
  for variant={'reference','candidate'}
   if strcmp(variant{1},'reference'),cd(reference_folder);else,cd(fullfile(root,'candidate'));end;clear functions;
   [nominal,real]=simulate_abm(2023,4,seed,'S0',1/10000,2,0,[],struct('include_heavy_diagnostics',false));post=rng;
   if strcmp(variant{1},'reference'),N=nominal;G=real;R=post;else
    smoke(seed)=struct('seed',seed,'nominal_equal',isequaln(N,nominal),'real_equal',isequaln(G,real),'rng_equal',isequaln(R,post), ...
      'finite_gdp',all(isfinite(nominal),'all') && all(isfinite(real),'all'),'nonzero_quarters',all(any(real(2:end,:)~=0,2)));
    writejson(fullfile(root,'smoke.json'),smoke);
    assert(smoke(seed).nominal_equal && smoke(seed).real_equal && smoke(seed).rng_equal,'cluster:SmokeMismatch','GDP or RNG changed.');
    assert(smoke(seed).finite_gdp && smoke(seed).nonzero_quarters,'cluster:InvalidGDP','Smoke GDP is nonfinite or has an all-zero quarter.');
   end
  end
 end

status(root,'complete');
catch e
writejson(fullfile(root,'error.json'),struct('message',e.message,'report',getReport(e,'extended','hyperlinks','off')));status(root,'failed');rethrow(e)
end
end
function [out,post,elapsed]=invoke(folder,args,state)
 cd(folder);clear search_and_matching;rng(state);out=cell(1,16);tic;[out{:}]=search_and_matching(args{:});elapsed=toc;post=rng;
end
function status(root,phase)
 writejson(fullfile(root,'status.json'),struct('phase',phase,'time',char(datetime('now'))));fprintf('PHASE %s\n',phase);
end
function writejson(path,data)
 tmp=[path '.tmp'];fid=fopen(tmp,'w');assert(fid>=0);fprintf(fid,'%s',jsonencode(data,PrettyPrint=true));fclose(fid);movefile(tmp,path,'f');
end

function build_linux_kernel(folder)
src=fullfile(folder,'c_src');
gcc='/apps/software/GCCcore/12.3.0';
cmd=sprintf('%s/bin/gfortran -c -O2 -fPIC -ffp-contract=off -fno-unsafe-math-optimizations -ffree-line-length-none -J%s %s -o %s',gcc,folder,fullfile(fileparts(folder),'matching.f90'),fullfile(folder,'matching.o'));
[code,msg]=system(cmd);disp(msg);assert(code==0,'Fortran compilation failed');
files=[dir(fullfile(src,'*.c'));dir(fullfile(src,'interface','*.c'))];sources=arrayfun(@(f)fullfile(f.folder,f.name),files,'UniformOutput',false);
mex('-v','-R2018a','-O','CFLAGS=$CFLAGS -fwrapv -ffp-contract=off -std=c99','-DMODEL=search_and_matching','-DNDEBUG', ...
 ['-I' src],['-I' fullfile(src,'interface')],'-outdir',folder,'-output','search_and_matching',sources{:},fullfile(folder,'matching.o'), ...
 ['-L' fullfile(matlabroot,'bin','glnxa64')],'-lmwblas','-lemlrt','-lcovrt','-lut','-lmwmathutil', ...
 ['-L' gcc '/lib64'],'-lgfortran',['LDFLAGS=$LDFLAGS -Wl,-rpath,' gcc '/lib64']);
end
