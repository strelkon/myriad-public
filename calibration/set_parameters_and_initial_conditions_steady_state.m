% Clear workspace
clear;

% Load calibration data
load('../data/calibration/AT.mat','calibration_data');
load('../data/figaro/EU.mat','figaro');

% Load time series data
load('../data/data/EU.mat','eu');

% Calculate GDP deflator from levels
eu.gdp_deflator_quarterly=eu.nominal_gdp_quarterly./eu.real_gdp_quarterly;

% Calibration date
start_calibration_date=datetime(2015,12,31);
end_calibration_date=datetime(2023,12,31);
max_calibration_date=datetime(2016,12,31);
estimation_date=datetime(1996,12,31);

for calibration_date=start_calibration_date:calquarters:end_calibration_date
    
    % Variables and constants for calibration
    T_calibration=find(calibration_data.years_num==datenum(datetime(year(min(calibration_date,max_calibration_date)),12,31)));
    T_calibration_quarterly=find(calibration_data.quarters_num==datenum(calibration_date));
    T_estimation_exo=find(eu.quarters_num==datenum(estimation_date));
    T_calibration_exo=find(eu.quarters_num==datenum(calibration_date));
    T_calibration_exo_max=length(eu.quarters_num);
    
    intermediate_consumption=max(0,figaro.intermediate_consumption(:,:,:,:,T_calibration));
    household_consumption=max(0,figaro.household_consumption(:,:,:,T_calibration));
    fixed_capitalformation=max(0,figaro.fixed_capitalformation(:,:,:,T_calibration));
    % capitalformation=squeeze(sum(figaro.capitalformation(:,:,:,T_calibration)))';
    exports=max(0,figaro.exports(:,:,T_calibration));
    imports=squeeze(sum(figaro.imports(:,:,T_calibration)))';
    compensation_employees=figaro.compensation_employees(:,:,T_calibration)';
    operating_surplus=figaro.operating_surplus(:,:,T_calibration)';
    government_consumption=max(0,figaro.government_consumption(:,:,:,T_calibration));
    taxes_products_household=figaro.taxes_products_household(:,T_calibration)';
    taxes_products_capitalformation=figaro.taxes_products_capitalformation(:,T_calibration)';
    taxes_production=figaro.taxes_production(:,:,T_calibration)';
    taxes_products_government=figaro.taxes_products_government(:,T_calibration)';
    taxes_products=figaro.taxes_products(:,:,T_calibration)';
    taxes_products_export=figaro.taxes_products_export(T_calibration);
    
    wages=[];
    geos={'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI', 'FR', 'EL', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK'}; % ,'MT'
    for g=1:length(geos)
    
    % Load calibration data
    load(['../data/calibration/',char(geos(g)),'.mat'],'calibration_data');
    
    capital_consumption(:,g)=calibration_data.capital_consumption(:,T_calibration);
    fixed_assets(:,g)=calibration_data.fixed_assets(:,T_calibration);
    dwellings(:,g)=calibration_data.dwellings(:,T_calibration);
    
    property_income(1,g)=calibration_data.property_income(T_calibration);
    mixed_income(1,g)=calibration_data.mixed_income(T_calibration);
    social_benefits(1,g)=calibration_data.social_benefits(T_calibration);
    unemployment_benefits(1,g)=calibration_data.unemployment_benefits(T_calibration);
    pension_benefits(1,g)=calibration_data.pension_benefits(T_calibration);
    corporate_tax(1,g)=calibration_data.corporate_tax(T_calibration);
    wages(1,g)=calibration_data.wages(T_calibration);
    social_contributions(1,g)=calibration_data.social_contributions(T_calibration);
    income_tax(1,g)=calibration_data.income_tax(T_calibration);
    capital_taxes(1,g)=calibration_data.capital_taxes(T_calibration);
    gross_capitalformation_dwellings(1,g)=calibration_data.gross_capitalformation_dwellings(T_calibration);
    
    firm_interest(1,g)=calibration_data.firm_interest(T_calibration);
    interest_government_debt(1,g)=calibration_data.interest_government_debt(T_calibration);
    government_deficit(1,g)=calibration_data.government_deficit(T_calibration);
    
    household_cash_quarterly(1,g)=calibration_data.household_cash_quarterly(T_calibration_quarterly);
    firm_cash_quarterly(1,g)=calibration_data.firm_cash_quarterly(T_calibration_quarterly);
    firm_debt_quarterly(1,g)=calibration_data.firm_debt_quarterly(T_calibration_quarterly);
    bank_equity_quarterly(1,g)=calibration_data.bank_equity_quarterly(T_calibration_quarterly);
    government_debt_quarterly(1,g)=calibration_data.government_debt_quarterly(T_calibration_quarterly);
    
    firms(:,g)=calibration_data.firms(:,T_calibration);
    employees(:,g)=calibration_data.employees(:,T_calibration);
    population(1,g)=calibration_data.population(T_calibration);
    
    % Load time series data for EU countries
    load(['../data/data/',char(geos(g)),'.mat'],'data');
    
    unemployment_rate_quarterly(1,g)=data.unemployment_rate_quarterly(T_calibration_exo);
    end
    
    % r_bar=max(0,(data.euribor(T_calibration_exo)+1).^(1/4)-1);
    
    scale=1/10000;
    omega=0.85;
    
    % Set interest to zero for debugging
    r_bar=0;
    firm_interest=zeros(1,26);
    interest_government_debt=zeros(1,26);
    gross_capitalformation_dwellings=zeros(1,26);
    
    s_a_ffsg=fillmissing(intermediate_consumption./sum(intermediate_consumption),'constant',0);
    s_CF_ffg=fillmissing(fixed_capitalformation./sum(fixed_capitalformation),'constant',0);
    s_CFH_ffg=s_CF_ffg;
    s_HH_ffg=fillmissing(household_consumption./sum(household_consumption),'constant',0);
    s_G_ffg=fillmissing(government_consumption./sum(government_consumption),'constant',0);
    s_E_fg=exports./sum(exports);
    
    IO=intermediate_consumption;
    IO=cat(4,IO,government_consumption);
    IO=cat(4,IO,household_consumption);
    IO=cat(4,IO,fixed_capitalformation);
    
    intermediate_consumption=permute(squeeze(sum(intermediate_consumption)),[2 3 1]);
    fixed_capitalformation=squeeze(sum(fixed_capitalformation))';
    household_consumption=squeeze(sum(household_consumption))';
    government_consumption=squeeze(sum(government_consumption))';
    
    % Calculate variables from accounting indentities
    output=squeeze(sum(intermediate_consumption))+taxes_products+taxes_production+compensation_employees+operating_surplus;
    for g=1:26
        for s=1:62
            output_res(s,g)=sum(sum(IO(g,:,s,:)))+exports(g,s)-output(s,g);
        end
    end
    for s=1:62
        imports(s)=sum(sum(IO(27,:,s,:)));
    end
    output=output+output_res;
    operating_surplus=operating_surplus+output_res;
    exports=sum(exports)';
    capital_consumption=capital_consumption./sum(capital_consumption).*sum(fixed_capitalformation);
    operating_surplus=operating_surplus-capital_consumption;
    taxes_products_capitalformation_dwellings=gross_capitalformation_dwellings.*(1-1./(1+taxes_products_capitalformation./sum(fixed_capitalformation)));
    capitalformation_dwellings=(gross_capitalformation_dwellings-taxes_products_capitalformation_dwellings).*fixed_capitalformation./sum(fixed_capitalformation);
    % capitalformation_dwellings=fixed_capitalformation-fixed_capitalformation./sum(fixed_capitalformation).*sum(capital_consumption);
    fixed_capital_formation_other_than_dwellings=fixed_capitalformation-capitalformation_dwellings;
    % imports=max(0,sum(squeeze(sum(intermediate_consumption,2))+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings./sum(fixed_capital_formation_other_than_dwellings).*sum(capital_consumption)+capitalformation_dwellings-output,2)+exports);
    reexports=0*min(0,sum(squeeze(sum(intermediate_consumption,2))+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings./sum(fixed_capital_formation_other_than_dwellings).*sum(capital_consumption)+capitalformation_dwellings-output,2)+exports);
    employers_social_contributions=min(social_contributions,sum(compensation_employees)-wages);
    wages=compensation_employees.*(1-employers_social_contributions./sum(compensation_employees));
    household_social_contributions=social_contributions-employers_social_contributions;
    household_income_tax=income_tax-corporate_tax;
    other_net_transfers=max(0,taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_export+sum(taxes_products)+sum(taxes_production)+employers_social_contributions+household_social_contributions+household_income_tax+corporate_tax+capital_taxes-social_benefits-sum(government_consumption)-interest_government_debt-government_deficit);
    pension_benefits=pension_benefits+min(0,taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_export+sum(taxes_products)+sum(taxes_production)+employers_social_contributions+household_social_contributions+household_income_tax+corporate_tax+capital_taxes-social_benefits-sum(government_consumption)-interest_government_debt-government_deficit);
    social_benefits=social_benefits+min(0,taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_export+sum(taxes_products)+sum(taxes_production)+employers_social_contributions+household_social_contributions+household_income_tax+corporate_tax+capital_taxes-social_benefits-sum(government_consumption)-interest_government_debt-government_deficit);
    disposable_income=sum(wages)+mixed_income+property_income+social_benefits+other_net_transfers-household_social_contributions-household_income_tax-capital_taxes;
    fixed_assets_other_than_dwellings=fixed_assets; %-dwellings;
    unemployed=round(unemployment_rate_quarterly.*sum(employees)./(1-unemployment_rate_quarterly));
    timescale=eu.nominal_gdp_quarterly(T_calibration_exo)/sum(sum(compensation_employees+operating_surplus+capital_consumption+taxes_production+taxes_products)+taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_government+taxes_products_export);
    
    % Scale number of firms and employees
    firms=max(1,round(scale*firms));
    % firms(:)=1;
    firms(output==0)=0;
    employees=max(firms,round(scale*employees));
    population=max(1,round(scale*population));
    unemployed=max(1,round(scale*unemployed));
    inactive=max(1,(population-sum(employees)-unemployed-sum(firms)));
    
    % Sector parameters
    I_sr=firms;
    alpha_sr=timescale*output./employees;
    beta_sr=output./squeeze(sum(intermediate_consumption));
    kappa_sr=timescale*output./fixed_assets_other_than_dwellings/omega;
    delta_sr=fillmissing(timescale*capital_consumption./fixed_assets_other_than_dwellings/omega,'constant',0);
    w_sr=timescale*wages./employees;
    tau_Y_sr=taxes_products./output;
    tau_K_sr=taxes_production./output;
    b_CF_g=fixed_capital_formation_other_than_dwellings./sum(fixed_capital_formation_other_than_dwellings);
    b_CFH_g=fillmissing(capitalformation_dwellings./sum(capitalformation_dwellings),'constant',0);
    b_HH_g=household_consumption./sum(household_consumption);
    a_sg=fillmissing(intermediate_consumption./sum(intermediate_consumption),'constant',0);
    c_G_g=government_consumption./sum(government_consumption);
    c_E_g=(exports-reexports)./sum(exports-reexports);
    c_I_g=imports/sum(imports);
    
    % Parameters
    T_prime=T_calibration_exo-T_estimation_exo+1;
    T=12;
    T_max=T-max(0,T_calibration_exo+T-T_calibration_exo_max);
    G=length(intermediate_consumption);
    S=G;
    F=size(intermediate_consumption,3);
    H_act=sum(employees)+unemployed+sum(firms);
    H_inact=inactive;
    J=round(sum(sum(firms))*sum(sum(government_consumption))/sum(sum(output)));
    L=round(sum(sum(firms))*sum(exports-reexports)/sum(sum(output)));
    mu=timescale*sum(firm_interest)/sum(firm_debt_quarterly)-r_bar;
    tau_INC=(household_income_tax+capital_taxes)./(sum(wages)+property_income+mixed_income-household_social_contributions);
    tau_FIRM=timescale*corporate_tax./(sum(max(0,timescale*operating_surplus-timescale*sum(firm_interest).*firm_debt_quarterly/sum(firm_debt_quarterly).*fixed_assets_other_than_dwellings./sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly.*max(0,operating_surplus)./sum(max(0,operating_surplus)))));
    tau_VAT=taxes_products_household./sum(household_consumption);
    tau_SIF=employers_social_contributions./sum(wages);
    tau_SIW=household_social_contributions./sum(wages);
    tau_EXPORT=taxes_products_export./sum(exports-reexports);
    tau_CF=fillmissing(taxes_products_capitalformation_dwellings./sum(capitalformation_dwellings),'constant',0);
    tau_G=taxes_products_government./sum(government_consumption);
    psi=(sum(household_consumption)+taxes_products_household)./disposable_income;
    psi_H=(sum(capitalformation_dwellings)+taxes_products_capitalformation_dwellings)./disposable_income;
    theta_DIV=timescale*(mixed_income+property_income)./(sum(max(0,timescale*operating_surplus-timescale*sum(firm_interest).*firm_debt_quarterly/sum(firm_debt_quarterly).*fixed_assets_other_than_dwellings./sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly.*max(0,operating_surplus)./sum(max(0,operating_surplus))))-timescale*corporate_tax);
    r_G=timescale*interest_government_debt./government_debt_quarterly;
    theta_UB=.5*(1-tau_INC).*(1-tau_SIW);
    theta=0.05;
    zeta=0.03;
    zeta_LTV=0.6;
    zeta_b=0.5;
    pi_star=0;
    alpha_gamma_G=1;
    beta_gamma_G=0;
    alpha_gamma_E=1;
    beta_gamma_E=0;
    alpha_gamma_I=1;
    beta_gamma_I=0;
    alpha_pi_G=1;
    beta_pi_G=0;
    alpha_pi_E=1;
    beta_pi_E=0;
    alpha_pi_I=1;
    beta_pi_I=0;
    
    C=zeros(6);
    
    save(['../model/parameters/',num2str(year(calibration_date)),'Q',num2str(quarter(calibration_date)),'.mat'],'T','T_max','S','G','H_act','H_inact','J','L','tau_INC','tau_FIRM','tau_VAT','tau_SIF','tau_SIW','tau_EXPORT','tau_CF','tau_G','theta_UB','psi','psi_H','theta_DIV','theta','mu','r_G','zeta','zeta_LTV','zeta_b','I_sr','alpha_sr','beta_sr','kappa_sr','delta_sr','w_sr','tau_Y_sr','tau_K_sr','b_CF_g','b_CFH_g','b_HH_g','c_G_g','c_E_g','c_I_g','a_sg','T_prime','pi_star','alpha_gamma_G','beta_gamma_G','alpha_gamma_E','beta_gamma_E','alpha_gamma_I','beta_gamma_I','alpha_pi_G','beta_pi_G','alpha_pi_E','beta_pi_E','alpha_pi_I','beta_pi_I','C','F','s_a_ffsg','s_CF_ffg','s_CFH_ffg','s_HH_ffg','s_G_ffg','s_E_fg');
    
    % Sector initial conditions
    N_sr=employees;
    D_I=firm_cash_quarterly;
    L_I=firm_debt_quarterly;
    w_UB=timescale*unemployment_benefits./unemployed;
    sb_inact=timescale*pension_benefits./inactive;
    sb_other=timescale*(social_benefits+other_net_transfers-unemployment_benefits-pension_benefits)./(sum(employees)+unemployed+inactive+sum(firms)); % +1 removed because I don't know what to do with bank profits at the moment
    D_H=household_cash_quarterly;
    K_H=sum(dwellings);
    L_G=government_debt_quarterly;
    E_k=sum(bank_equity_quarterly);
    E_CB=sum(L_G)+sum(L_I)-sum(D_I)-sum(D_H)-E_k;
    D_RoW=0;
    
    % Initial conditions
    Y=timescale*sum(sum(output))*ones(T_calibration_exo-T_estimation_exo+1,1);
    gamma=zeros(T_calibration_exo-T_estimation_exo+1,1);
    pi=zeros(T_calibration_exo-T_estimation_exo+1,1);
    P=ones(T_calibration_exo-T_estimation_exo+1,1);
    % r_bar=(eu.euribor(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))+1).^(1/4)-1;
    % gamma_G=diff(log(eu.real_government_consumption_quarterly(T_estimation_exo-1:min(T_calibration_exo+T,T_calibration_exo_max))));
    % C_G=timescale*sum(government_consumption)*exp(cumsum(gamma_G))/exp(sum(gamma_G(1:T_prime)));
    % pi_G=diff(log(eu.government_consumption_deflator_quarterly(T_estimation_exo-1:min(T_calibration_exo+T,T_calibration_exo_max))));
    % P_G=exp(cumsum(pi_G))/exp(sum(pi_G(1:T_prime)));
    gamma_E=zeros(T_calibration_exo-T_estimation_exo+1,1);
    C_E=timescale*sum(exports-reexports)*ones(T_calibration_exo-T_estimation_exo+1,1);
    pi_E=zeros(T_calibration_exo-T_estimation_exo+1,1);
    P_E=ones(T_calibration_exo-T_estimation_exo+1,1);
    gamma_I=zeros(T_calibration_exo-T_estimation_exo+1,1);
    Y_I=timescale*sum(imports)*ones(T_calibration_exo-T_estimation_exo+1,1);
    pi_I=zeros(T_calibration_exo-T_estimation_exo+1,1);
    P_I=ones(T_calibration_exo-T_estimation_exo+1,1);
    
    Y_f=[];
    gamma_f=[];
    pi_f=[];
    P_f=[];
    gamma_G=[];
    C_G=[];
    pi_G=[];
    P_G=[];
    for g=1:length(geos)
        
        % Load calibration data
        load(['../data/data/',char(geos(g)),'.mat'],'data');
        
        Y_f(:,g)=timescale*sum(output(:,g))*ones(T_calibration_exo-T_estimation_exo+1,1);
        gamma_f(:,g)=zeros(T_calibration_exo-T_estimation_exo+1,1);
        pi_f(:,g)=zeros(T_calibration_exo-T_estimation_exo+1,1);
        P_f(:,g)=ones(T_calibration_exo-T_estimation_exo+1,1);
        gamma_G(:,g)=zeros(T_calibration_exo-T_estimation_exo+1,1);
        C_G(:,g)=timescale*sum(government_consumption(:,g))*ones(T_calibration_exo-T_estimation_exo+1,1);
        pi_G(:,g)=zeros(T_calibration_exo-T_estimation_exo+1,1);
        P_G(:,g)=ones(T_calibration_exo-T_estimation_exo+1,1);
    end
    
    save(['../model/initial_conditions/',num2str(year(calibration_date)),'Q',num2str(quarter(calibration_date)),'.mat'],'D_I','L_I','omega','w_UB','sb_inact','sb_other','D_H','K_H','L_G','E_k','E_CB','D_RoW','N_sr','Y','gamma','pi','P','r_bar','gamma_G','C_G','pi_G','P_G','gamma_E','C_E','pi_E','P_E','gamma_I','Y_I','pi_I','P_I','Y_f','gamma_f','pi_f','P_f');
end
