clear;

seeds=500;
T=12;
G=62;

for y=2010:2019
    for q=1:4
        for p=0:1
            for s=1:seeds
                S=load([num2str(p),'_',num2str(y),'Q',num2str(q),'_',num2str(s),'.mat']);
                nominal_gdp(:,s)=S.nominal_gdp;
                real_gdp(:,s)=S.real_gdp;
                nominal_gva(:,s)=S.nominal_gva;
                real_gva(:,s)=S.real_gva;
                nominal_household_consumption(:,s)=S.nominal_household_consumption;
                real_household_consumption(:,s)=S.real_household_consumption;
                nominal_government_consumption(:,s)=S.nominal_government_consumption;
                real_government_consumption(:,s)=S.real_government_consumption;
                nominal_capitalformation(:,s)=S.nominal_capitalformation;
                real_capitalformation(:,s)=S.real_capitalformation;
                nominal_fixed_capitalformation(:,s)=S.nominal_fixed_capitalformation;
                real_fixed_capitalformation(:,s)=S.real_fixed_capitalformation;
                nominal_fixed_capitalformation_dwellings(:,s)=S.nominal_fixed_capitalformation_dwellings;
                real_fixed_capitalformation_dwellings(:,s)=S.real_fixed_capitalformation_dwellings;
                nominal_exports(:,s)=S.nominal_exports;
                real_exports(:,s)=S.real_exports;
                nominal_imports(:,s)=S.nominal_imports;
                real_imports(:,s)=S.real_imports;
                operating_surplus(:,s)=S.operating_surplus;
                compensation_employees(:,s)=S.compensation_employees;
                wages(:,s)=S.wages;
                taxes_production(:,s)=S.taxes_production;
                nominal_sector_gva(:,s,:)=S.nominal_sector_gva;
                real_sector_gva(:,s,:)=S.real_sector_gva;
                euribor(:,s)=S.euribor;
                gdp_deflator_growth_ea(:,s)=S.gdp_deflator_growth_ea;
                real_gdp_ea(:,s)=S.real_gdp_ea;
            end
            save(['./',num2str(p),'_',num2str(y),'Q',num2str(q),'.mat'],'nominal_gdp', 'real_gdp', 'nominal_gva', 'real_gva', 'nominal_household_consumption', 'real_household_consumption', 'nominal_government_consumption', 'real_government_consumption', 'nominal_capitalformation', 'real_capitalformation', 'nominal_fixed_capitalformation', 'real_fixed_capitalformation', 'nominal_fixed_capitalformation_dwellings', 'real_fixed_capitalformation_dwellings', 'nominal_exports', 'real_exports', 'nominal_imports', 'real_imports', 'operating_surplus', 'compensation_employees', 'wages', 'taxes_production', 'nominal_sector_gva', 'real_sector_gva', 'euribor', 'gdp_deflator_growth_ea', 'real_gdp_ea');
        end
    end
end
