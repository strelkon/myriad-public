clear;

tables = {'naio_10_fcp_ii1','naio_10_fcp_ii2','naio_10_fcp_ii3'};

for k = 1:numel(tables)
    assignin('base', tables{k}, readtable_eurostat(tables{k}));
end

naio_10_fcp_ii = vertcat(naio_10_fcp_ii1, naio_10_fcp_ii2, naio_10_fcp_ii3);

clear(tables{:});

% save('naio_10_fcp_ii.mat','naio_10_fcp_ii');
% load('naio_10_fcp_ii.mat','naio_10_fcp_ii');

naio_10_fcp_ii.c_orig(naio_10_fcp_ii.c_orig=='EL') = 'GR';
naio_10_fcp_ii.c_orig = reordercats(naio_10_fcp_ii.c_orig, sort(categories(naio_10_fcp_ii.c_orig)));
naio_10_fcp_ii.c_dest(naio_10_fcp_ii.c_dest=='EL') = 'GR';
naio_10_fcp_ii.c_dest = reordercats(naio_10_fcp_ii.c_dest, sort(categories(naio_10_fcp_ii.c_dest)));

countries = {'AT','BE','BG','CY','CZ','DE','DK','EE','ES','FI','FR','GR','HR','HU','IE','IT','LT','LU','LV','NL','PL','PT','RO','SE','SI','SK'};
            {'AT','BE','BG','CY','CZ','DE','DK','EE','ES','FI','FR','EL','HR','HU','IE','IT','LT','LU','LV','NL','PL','PT','RO','SE','SI','SK'};
industries = {'A01','A02','A03','B','C10-12','C13-15','C16','C17','C18','C19','C20','C21','C22','C23','C24','C25','C26','C27','C28','C29','C30','C31_32','C33','D35','E36','E37-39','F','G45','G46','G47','H49','H50','H51','H52','H53','I','J58','J59_60','J61','J62_63','K64','K65','K66','L','M69_70','M71','M72','M73','M74_75','N77','N78','N79','N80-82','O84','P85','Q86','Q87_88','R90-92','R93','S94','S95','S96'};
years = {'2010','2011','2012','2013','2014','2015','2016'};

figaro.years_num=datenum(dateshift(datetime(years, 'format','yyyy'),'end','year'));

figaro.intermediate_consumption=select_intermediate_consumption(naio_10_fcp_ii,countries,industries,years);

figaro.household_consumption=select_final_use(naio_10_fcp_ii,countries,industries,{'P3_S14','P3_S15'},years);

figaro.government_consumption=select_final_use(naio_10_fcp_ii,countries,industries,{'P3_S13'},years);

figaro.fixed_capitalformation=select_final_use(naio_10_fcp_ii,countries,industries,{'P51G'},years);

figaro.inventory_changes=select_final_use(naio_10_fcp_ii,countries,industries,{'P5M'},years);

figaro.capitalformation=figaro.fixed_capitalformation+figaro.inventory_changes;

figaro.operating_surplus=select_value_added(naio_10_fcp_ii,countries,industries,{'B2A3G'},years);

figaro.compensation_employees=select_value_added(naio_10_fcp_ii,countries,industries,{'D1'},years);

figaro.taxes_production=select_value_added(naio_10_fcp_ii,countries,industries,{'D29X39'},years);

figaro.taxes_products=select_value_added(naio_10_fcp_ii,countries,industries,{'D21X31'},years);

figaro.taxes_products_household=select_taxes(naio_10_fcp_ii,countries,{'P3_S14','P3_S15'},{'D21X31'},years);

figaro.taxes_products_government=select_taxes(naio_10_fcp_ii,countries,{'P3_S13'},{'D21X31'},years);

figaro.taxes_products_fixed_capitalformatio=select_taxes(naio_10_fcp_ii,countries,{'P51G'},{'D21X31'},years);

figaro.taxes_products_inventory_changes=select_taxes(naio_10_fcp_ii,countries,{'P5M'},{'D21X31'},years);

figaro.taxes_products_capitalformation=figaro.taxes_products_fixed_capitalformatio+figaro.taxes_products_inventory_changes;

figaro.taxes_products_export=zeros(size(figaro.taxes_products_government));

idx=~ismember(naio_10_fcp_ii.c_dest,countries)&ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_ava','c_orig'}; % Group (GROUP BY)
column={'time','ind_ava','c_orig'}; % Ordering (ORDER BY)
figaro.exports=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(industries),numel(years));

idx=ismember(naio_10_fcp_ii.c_dest,countries)&~ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_ava','c_dest'}; % Group (GROUP BY)
column={'time','ind_ava','c_dest'}; % Ordering (ORDER BY)
figaro.imports=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(industries),numel(years));

save('figaro.mat','figaro');

function final_use = select_final_use(naio_10_fcp_ii,countries,industries,final_uses,years)
idx=ismember(naio_10_fcp_ii.c_dest,countries)&ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.ind_use,final_uses)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_ava','c_dest','c_orig'}; % Group (GROUP BY)
column={'time','ind_ava','c_dest','c_orig'}; % Ordering (ORDER BY)
domestic_final_use=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(countries),numel(industries),numel(years));

idx=ismember(naio_10_fcp_ii.c_dest,countries)&~ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.ind_use,final_uses)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_ava','c_dest'}; % Group (GROUP BY)
column={'time','ind_ava','c_dest'}; % Ordering (ORDER BY)
imported_final_use=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(industries),numel(years));
final_use=[domestic_final_use;reshape(imported_final_use,[1,size(imported_final_use)])];
end

function intermediate_consumption = select_intermediate_consumption(naio_10_fcp_ii,countries,industries,years)
idx=ismember(naio_10_fcp_ii.c_dest,countries)&ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.ind_use,industries)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_use','ind_ava','c_dest','c_orig'}; % Group (GROUP BY)
column={'time','ind_use','ind_ava','c_dest','c_orig'}; % Ordering (ORDER BY)
domestic_intermediate_consumption=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(countries),numel(industries),numel(industries),numel(years));

idx=ismember(naio_10_fcp_ii.c_dest,countries)&~ismember(naio_10_fcp_ii.c_orig,countries)&ismember(naio_10_fcp_ii.ind_ava,industries)&ismember(naio_10_fcp_ii.ind_use,industries)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_use','ind_ava','c_dest'}; % Group (GROUP BY)
column={'time','ind_use','ind_ava','c_dest'}; % Ordering (ORDER BY)
imported_intermediate_consumption=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(industries),numel(industries),numel(years));
intermediate_consumption=[domestic_intermediate_consumption;reshape(imported_intermediate_consumption,[1,size(imported_intermediate_consumption)])];
end

function value_added = select_value_added(naio_10_fcp_ii,countries,industries,value_added,years)
idx=ismember(naio_10_fcp_ii.c_dest,countries)&ismember(naio_10_fcp_ii.ind_ava,value_added)&ismember(naio_10_fcp_ii.ind_use,industries)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','ind_use','c_dest'}; % Group (GROUP BY)
column={'time','ind_use','c_dest'}; % Ordering (ORDER BY)
value_added=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(industries),numel(years));
end

function taxes = select_taxes(naio_10_fcp_ii,countries,final_use,taxes,years)
idx=ismember(naio_10_fcp_ii.c_dest,countries)&ismember(naio_10_fcp_ii.ind_ava,taxes)&ismember(naio_10_fcp_ii.ind_use,final_use)&ismember(naio_10_fcp_ii.time,years); % Row selection (WHERE clause) 
groupvars={'time','c_dest'}; % Group (GROUP BY)
column={'time','c_dest'}; % Ordering (ORDER BY)
taxes=reshape(sortrows(groupsummary(naio_10_fcp_ii(idx,:),groupvars,'sum','value'),column).sum_value,numel(countries),numel(years));
end

% counterpartarea==c_dest
% refarea==c_orig
% rowii==ind_ava
% colii==ind_use
