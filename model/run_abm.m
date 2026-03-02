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
credit_constraints=0;
scenarios = {'S0', 'S1'};
for sc=1:length(scenarios)
    scenario = scenarios{sc};
    [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,capital_consumption,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,sector_operating_surplus,sector_capital_consumption,nominal_output,real_output,nominal_sector_output,real_sector_output,government_debt,government_deficit,unemployment_rate,euribor,dyn_bilateral_trade_g,dyn_bilateral_trade_real_g,capital_stock_dynamics,capital_loss,sector_capital_loss,firms_damaged,loan_issuance,credit_constrained_pct,total_firms_demanding,credit_gap,credit_gap_to_gdp]=simulate_abm_mc(year,quarter,scenario,scale,seeds,T,credit_constraints);
    save(['../results/',scenario,'_',num2str(year),'Q',num2str(quarter),'.mat'], 'nominal_gdp', 'real_gdp', 'nominal_gva', 'real_gva', 'nominal_household_consumption', 'real_household_consumption', 'nominal_government_consumption', 'real_government_consumption', 'nominal_capitalformation', 'real_capitalformation', 'nominal_fixed_capitalformation', 'real_fixed_capitalformation', 'nominal_fixed_capitalformation_dwellings', 'real_fixed_capitalformation_dwellings', 'nominal_exports', 'real_exports', 'nominal_imports', 'real_imports', 'operating_surplus', 'capital_consumption', 'compensation_employees', 'wages', 'taxes_production', 'nominal_sector_gva', 'real_sector_gva', 'sector_operating_surplus', 'sector_capital_consumption', 'nominal_output', 'real_output', 'nominal_sector_output', 'real_sector_output', 'government_debt', 'government_deficit', 'unemployment_rate', 'euribor', 'dyn_bilateral_trade_g', 'dyn_bilateral_trade_real_g', 'capital_stock_dynamics', 'capital_loss', 'sector_capital_loss', 'firms_damaged', 'loan_issuance', 'credit_constrained_pct', 'total_firms_demanding', 'credit_gap', 'credit_gap_to_gdp');
end
