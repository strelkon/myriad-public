function [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,capital_consumption,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,sector_operating_surplus,sector_capital_consumption,nominal_output,real_output,nominal_sector_output,real_sector_output,government_debt,government_deficit,unemployment_rate,euribor,dyn_bilateral_trade_g,dyn_bilateral_trade_real_g,capital_stock_dynamics,capital_loss,sector_capital_loss,firms_damaged,loan_issuance,credit_constrained_pct,total_firms_demanding,credit_gap,credit_gap_to_gdp]=simulate_abm_mc(year,quarter,scenario,scale,seeds,T,credit_constraints,output_options)

if nargin < 4
    scale = 1/1000;
end
if nargin < 5
    seeds = 500;
end
if nargin < 6
    T = 12;
end
if nargin < 8
    output_options = [];
end

output_options = resolve_output_options(output_options);
include_heavy_diagnostics = output_options.include_heavy_diagnostics;

F=26;
G=62;

nominal_gdp=zeros(T+1,seeds,F);
real_gdp=zeros(T+1,seeds,F);
nominal_gva=zeros(T+1,seeds,F);
real_gva=zeros(T+1,seeds,F);
nominal_household_consumption=zeros(T+1,seeds,F);
real_household_consumption=zeros(T+1,seeds,F);
nominal_government_consumption=zeros(T+1,seeds,F);
real_government_consumption=zeros(T+1,seeds,F);
nominal_capitalformation=zeros(T+1,seeds,F);
real_capitalformation=zeros(T+1,seeds,F);
nominal_fixed_capitalformation=zeros(T+1,seeds,F);
real_fixed_capitalformation=zeros(T+1,seeds,F);
nominal_fixed_capitalformation_dwellings=zeros(T+1,seeds,F);
real_fixed_capitalformation_dwellings=zeros(T+1,seeds,F);
nominal_exports=zeros(T+1,seeds,F);
real_exports=zeros(T+1,seeds,F);
nominal_imports=zeros(T+1,seeds,F);
real_imports=zeros(T+1,seeds,F);
operating_surplus=zeros(T+1,seeds,F);
capital_consumption=zeros(T+1,seeds,F);
compensation_employees=zeros(T+1,seeds,F);
wages=zeros(T+1,seeds,F);
taxes_production=zeros(T+1,seeds,F);
nominal_sector_gva=zeros(T+1,seeds,F,G);
real_sector_gva=zeros(T+1,seeds,F,G);
sector_operating_surplus=zeros(T+1,seeds,F,G);
sector_capital_consumption=zeros(T+1,seeds,F,G);
nominal_output=zeros(T+1,seeds,F);
real_output=zeros(T+1,seeds,F);
nominal_sector_output=zeros(T+1,seeds,F,G);
real_sector_output=zeros(T+1,seeds,F,G);
government_debt=zeros(T+1,seeds,F);
government_deficit=zeros(T+1,seeds,F);
unemployment_rate=zeros(T+1,seeds,F);
euribor=zeros(T+1,seeds);

if include_heavy_diagnostics
    dyn_bilateral_trade_g=zeros(T+1,seeds,F+1,F+1,G);
    dyn_bilateral_trade_real_g=zeros(T+1,seeds,F+1,F+1,G);
    capital_stock_dynamics=zeros(T+1,seeds,F,G);
    sector_capital_loss=zeros(T+1,seeds,F,G);
    firms_damaged=zeros(T+1,seeds,F,G);
    credit_constrained_pct=zeros(T+1,seeds,F,G);
    total_firms_demanding=zeros(T+1,seeds,F,G);
else
    dyn_bilateral_trade_g=[];
    dyn_bilateral_trade_real_g=[];
    capital_stock_dynamics=[];
    sector_capital_loss=[];
    firms_damaged=[];
    credit_constrained_pct=[];
    total_firms_demanding=[];
end
capital_loss=zeros(T+1,seeds,F);
loan_issuance=zeros(T+1,seeds,F);
credit_gap=zeros(T+1,seeds,F);
credit_gap_to_gdp=zeros(T+1,seeds,F);

cache_const = parallel.pool.Constant(@() build_simulation_cache(year, quarter, scenario, scale, T));
parfor s=1:seeds
    try
    cache = cache_const.Value;
    [S_nominal_gdp,S_real_gdp,S_nominal_gva,S_real_gva,S_nominal_household_consumption,S_real_household_consumption,S_nominal_government_consumption,S_real_government_consumption,S_nominal_capitalformation,S_real_capitalformation,S_nominal_fixed_capitalformation,S_real_fixed_capitalformation,S_nominal_fixed_capitalformation_dwellings,S_real_fixed_capitalformation_dwellings,S_nominal_exports,S_real_exports,S_nominal_imports,S_real_imports,S_operating_surplus,S_capital_consumption,S_compensation_employees,S_wages,S_taxes_production,S_nominal_sector_gva,S_real_sector_gva,S_sector_operating_surplus,S_sector_capital_consumption,S_nominal_output,S_real_output,S_nominal_sector_output,S_real_sector_output,S_government_debt,S_government_deficit,S_unemployment_rate,S_euribor,S_dyn_bilateral_trade_g,S_dyn_bilateral_trade_real_g,S_capital_stock_dynamics,S_capital_loss,S_sector_capital_loss,S_firms_damaged,S_loan_issuance,S_credit_constrained_pct,S_total_firms_demanding,S_credit_gap,S_credit_gap_to_gdp]=simulate_abm(year,quarter,s,scenario,scale,T,credit_constraints,cache,output_options);
    nominal_gdp(:,s,:)=S_nominal_gdp;
    real_gdp(:,s,:)=S_real_gdp;
    nominal_gva(:,s,:)=S_nominal_gva;
    real_gva(:,s,:)=S_real_gva;
    nominal_household_consumption(:,s,:)=S_nominal_household_consumption;
    real_household_consumption(:,s,:)=S_real_household_consumption;
    nominal_government_consumption(:,s,:)=S_nominal_government_consumption;
    real_government_consumption(:,s,:)=S_real_government_consumption;
    nominal_capitalformation(:,s,:)=S_nominal_capitalformation;
    real_capitalformation(:,s,:)=S_real_capitalformation;
    nominal_fixed_capitalformation(:,s,:)=S_nominal_fixed_capitalformation;
    real_fixed_capitalformation(:,s,:)=S_real_fixed_capitalformation;
    nominal_fixed_capitalformation_dwellings(:,s,:)=S_nominal_fixed_capitalformation_dwellings;
    real_fixed_capitalformation_dwellings(:,s,:)=S_real_fixed_capitalformation_dwellings;
    nominal_exports(:,s,:)=S_nominal_exports;
    real_exports(:,s,:)=S_real_exports;
    nominal_imports(:,s,:)=S_nominal_imports;
    real_imports(:,s,:)=S_real_imports;
    operating_surplus(:,s,:)=S_operating_surplus;
    capital_consumption(:,s,:)=S_capital_consumption;
    compensation_employees(:,s,:)=S_compensation_employees;
    wages(:,s,:)=S_wages;
    taxes_production(:,s,:)=S_taxes_production;
    nominal_sector_gva(:,s,:,:)=S_nominal_sector_gva;
    real_sector_gva(:,s,:,:)=S_real_sector_gva;
    sector_operating_surplus(:,s,:,:)=S_sector_operating_surplus;
    sector_capital_consumption(:,s,:,:)=S_sector_capital_consumption;
    nominal_output(:,s,:)=S_nominal_output;
    real_output(:,s,:)=S_real_output;
    nominal_sector_output(:,s,:,:)=S_nominal_sector_output;
    real_sector_output(:,s,:,:)=S_real_sector_output;
    government_debt(:,s,:)=S_government_debt;
    government_deficit(:,s,:)=S_government_deficit;
    unemployment_rate(:,s,:)=S_unemployment_rate;
    euribor(:,s)=S_euribor;
    capital_loss(:,s,:)=S_capital_loss;
    loan_issuance(:,s,:)=S_loan_issuance;
    credit_gap(:,s,:)=S_credit_gap;
    credit_gap_to_gdp(:,s,:)=S_credit_gap_to_gdp;
    if include_heavy_diagnostics
        dyn_bilateral_trade_g(:,s,:,:,:)=S_dyn_bilateral_trade_g;
        dyn_bilateral_trade_real_g(:,s,:,:,:)=S_dyn_bilateral_trade_real_g;
        capital_stock_dynamics(:,s,:,:)=S_capital_stock_dynamics;
        sector_capital_loss(:,s,:,:)=S_sector_capital_loss;
        firms_damaged(:,s,:,:)=S_firms_damaged;
        credit_constrained_pct(:,s,:,:)=S_credit_constrained_pct;
        total_firms_demanding(:,s,:,:)=S_total_firms_demanding;
    end
    catch ME
        fprintf('WARNING: Seed %d failed: %s\n', s, ME.message);
    end
end
delete(cache_const);
end
