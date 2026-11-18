function collect_scale10
root=fileparts(mfilename('fullpath'));members=cell(1,10);rng_states=cell(1,10);records=cell(1,10);nominal=cell(1,10);real=cell(1,10);
for seed=1:10
 records{seed}=jsondecode(fileread(fullfile(root,sprintf('seed_%02d_complete.json',seed))));
 assert(records{seed}.finite_gdp&&records{seed}.nonzero_quarter);
 data=load(fullfile(root,sprintf('seed_%02d.mat',seed)),'outputs','post_rng');
 members{seed}=data.outputs;rng_states{seed}=data.post_rng;
 nominal{seed}=data.outputs{1};real{seed}=data.outputs{2};
end
tokens=regexp(fileread('/home/strelkon/simulate_abm.m'),'function\s*\[([^\]]+)\]','tokens','once');output_names=strtrim(strsplit(tokens{1},','));
assert(numel(output_names)==numel(members{1}));
nominal_gdp=cat(3,nominal{:});real_gdp=cat(3,real{:});seed_ids=1:10;
mean_nominal_gdp=mean(nominal_gdp,3);mean_real_gdp=mean(real_gdp,3);
save(fullfile(root,'ensemble.mat'),'members','output_names','rng_states','records','seed_ids','nominal_gdp','real_gdp','mean_nominal_gdp','mean_real_gdp','-v7.3');
f=fopen(fullfile(root,'ensemble_complete.json'),'w');fprintf(f,'%s',jsonencode(struct('seeds',seed_ids,'gdp_size',size(real_gdp),'finite_gdp',all(isfinite(real_gdp),'all'),'matlab_version',version)));fclose(f);
end
