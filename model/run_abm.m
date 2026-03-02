function run_abm(scale, T, seeds)

if nargin < 1
    scale = 1/1000;
end
if nargin < 2
    T = 12;
end
if nargin < 3
    seeds = 500;
end

year=2023;
quarter=4;
for scenario=0:1
    [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,capital_consumption,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,sector_operating_surplus,sector_capital_consumption,nominal_output,real_output,nominal_sector_output,real_sector_output,government_debt,government_deficit,unemployment_rate,euribor]=simulate_abm_mc(year,quarter,scenario,scale,seeds,T);
    save([num2str(scenario),'_',num2str(year),'Q',num2str(quarter),'.mat'], 'nominal_gdp', 'real_gdp', 'nominal_gva', 'real_gva', 'nominal_household_consumption', 'real_household_consumption', 'nominal_government_consumption', 'real_government_consumption', 'nominal_capitalformation', 'real_capitalformation', 'nominal_fixed_capitalformation', 'real_fixed_capitalformation', 'nominal_fixed_capitalformation_dwellings', 'real_fixed_capitalformation_dwellings', 'nominal_exports', 'real_exports', 'nominal_imports', 'real_imports', 'operating_surplus', 'capital_consumption', 'compensation_employees', 'wages', 'taxes_production', 'nominal_sector_gva', 'real_sector_gva', 'sector_operating_surplus', 'sector_capital_consumption', 'nominal_output', 'real_output', 'nominal_sector_output', 'real_sector_output', 'government_debt', 'government_deficit', 'unemployment_rate', 'euribor');
end
