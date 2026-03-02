%%
%%
%%
%% Fetch Data from SQL Database, save relevant data (+ calculate taxrates)
%%
%%
%%
%%

%% Dictionary of abbreviations in code
%%

% ass   ....    asset(s)
% sec   ....    IO Sectors
% gov   ....    government
% hh    ....    household
% cons  ....    consumption
% soc   ....    social
% contr ....    contributions
% rec   ....    received/receivable
% pay   ....    paid/payable
% cap   ....    capital
% form  ....    formation
% os    ....    operating surplus
% np    ....    adjustment disposal/acquisition of valuables 
% oth   ....    other
% trans ....    transfers
% UB    ....    unemployment benefits
% PP    ....    pension payments
% SEB   ....    social exclusion benefits
% SB    ....    social benefits (all persons alike)
% inc   ....    income
% exp   ....    expenditure
% prop  ....    property
% CF    ....    capital formation
% vat   ....    value added tax
% tang  ....    tangible
% SIF   ....    employers' social contributions (rate)
% SIW   ....    employees' social contributions (rate)

%%
%%
%% Preparations
%%
%%
%%

%% Clear workspace
clear;

%% Connect to Database
conn=database('eurostat_20250317','db_reader','$qldbreader123!','Vendor','PostgreSQL','Server','psqlasa.iiasa.ac.at');

%% Variables to parameterize according to country and year
geos={'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EL', 'ES', 'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK', 'EA19', 'EU27_2020'};
year=1996;
number_years=2023-year;
number_quarters=number_years*4;

% calculate serial date numbers and format date strings
years_num=datenum(year+1,1:12:number_years*12+1,0);
years_str=datestr(years_num,'\''yyyy\'', ');
years_str=reshape(years_str',1,size(years_str,1)*size(years_str,2));
years_str=years_str(1:end-2);
data.years_num=years_num';

quarters_num=datenum(year,4:3:(number_years+1)*12+1,0);
quarters_str=datestr(quarters_num,'\''yyyy-qq\'', ');
quarters_str=reshape(quarters_str',1,size(quarters_str,1)*size(quarters_str,2));
quarters_str=quarters_str(1:end-2);
data.quarters_num=quarters_num';

for g=1:length(geos)
geo=['''',char(geos(g)),''''];
%% GDP time series
%%
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_gdp=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_gdp=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''PD10_EUR'' ORDER BY time'];
data.gdp_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_gdp_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.gdp_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_gdp_growth=data.real_gdp_growth+data.gdp_deflator_growth;

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_gdp_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_gdp_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.gdp_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_gdp_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1GQ'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.gdp_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_gdp_growth_quarterly=data.real_gdp_growth_quarterly+data.gdp_deflator_growth_quarterly;


%% GVA time series
%%
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_gva=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_gva=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''PD10_EUR'' ORDER BY time'];
data.gva_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_gva_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.gva_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_gva_growth=data.real_gva_growth+data.gva_deflator_growth;

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_gva_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_gva_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.gva_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_gva_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B1G'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.gva_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_gva_growth_quarterly=data.real_gva_growth_quarterly+data.gva_deflator_growth_quarterly;


%% Household Consumption Time Series

%Annual

%Take from IO tables to get correct number
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_household_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_household_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''PD10_EUR'' ORDER BY time'];
data.household_consumption_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_household_consumption_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.household_consumption_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_household_consumption_growth=data.real_household_consumption_growth+data.household_consumption_deflator_growth;

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_household_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_household_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.household_consumption_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_household_consumption_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P31_S14_S15'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.household_consumption_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_household_consumption_growth_quarterly=data.real_household_consumption_growth_quarterly+data.household_consumption_deflator_growth_quarterly;


%% Government Consumption Time Series

% Annual

%Take from IO tables to get correct number
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_government_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_government_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''PD10_EUR'' ORDER BY time'];
data.government_consumption_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_government_consumption_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.government_consumption_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_government_consumption_growth=data.real_government_consumption_growth+data.government_consumption_deflator_growth;

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_government_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_government_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.government_consumption_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_government_consumption_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3_S13'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.government_consumption_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_government_consumption_growth_quarterly=data.real_government_consumption_growth_quarterly+data.government_consumption_deflator_growth_quarterly;


%% Final Consumption Time Series

%Annual

%Take from IO tables to get correct number
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_final_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_final_consumption = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''PD10_EUR'' ORDER BY time'];
data.final_consumption_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_final_consumption_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.final_consumption_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_final_consumption_growth=data.real_final_consumption_growth+data.final_consumption_deflator_growth;

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_final_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_final_consumption_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.final_consumption_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_final_consumption_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P3'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.final_consumption_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_final_consumption_growth_quarterly=data.real_final_consumption_growth_quarterly+data.final_consumption_deflator_growth_quarterly;


%% Capital Formation Time Series


sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''PD10_EUR'' ORDER BY time'];
data.capitalformation_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_capitalformation_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.capitalformation_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_capitalformation_growth=data.real_capitalformation_growth+data.capitalformation_deflator_growth;

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_capitalformation_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_capitalformation_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.capitalformation_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_capitalformation_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P5G'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.capitalformation_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_capitalformation_growth_quarterly=data.real_capitalformation_growth_quarterly+data.capitalformation_deflator_growth_quarterly;


%% Fixed Capital Formation Time Series


sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_fixed_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_fixed_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''PD10_EUR'' ORDER BY time'];
data.fixed_capitalformation_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_fixed_capitalformation_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.fixed_capitalformation_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_fixed_capitalformation_growth=data.real_fixed_capitalformation_growth+data.fixed_capitalformation_deflator_growth;

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_fixed_capitalformation_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_fixed_capitalformation_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.fixed_capitalformation_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_fixed_capitalformation_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P51G'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.fixed_capitalformation_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_fixed_capitalformation_growth_quarterly=data.real_fixed_capitalformation_growth_quarterly+data.fixed_capitalformation_deflator_growth_quarterly;


%% Exports Time Series - Take from IO tables, all growth and deflator rates from nama_10_gdp, calculate quarterly exports then!

% Annual
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_exports=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_exports=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''PD10_EUR'' ORDER BY time'];
data.exports_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_exports_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.exports_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_exports_growth=data.real_exports_growth+data.exports_deflator_growth;

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_exports_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_exports_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.exports_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_exports_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P6'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.exports_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_exports_growth_quarterly=data.real_exports_growth_quarterly+data.exports_deflator_growth_quarterly;


%% Imports Time Series


%Annual
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CP_MEUR'' ORDER BY time'];
data.nominal_imports = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CLV10_MEUR'' ORDER BY time'];
data.real_imports = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''PD10_EUR'' ORDER BY time'];
data.imports_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CLV_PCH_PRE'' ORDER BY time'];
data.real_imports_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''PD_PCH_PRE_EUR'' ORDER BY time'];
data.imports_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_imports_growth=data.real_imports_growth+data.imports_deflator_growth;

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.nominal_imports_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.real_imports_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.imports_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY time'];
data.real_imports_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''P7'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY time'];
data.imports_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

data.nominal_imports_growth_quarterly=data.real_imports_growth_quarterly+data.imports_deflator_growth_quarterly;


%% 3-month euribor
sqlquery=['SELECT value FROM irt_st_q WHERE time IN (',quarters_str,') AND geo=''EA'' AND int_rt=''IRT_M3'' ORDER BY time'];
data.euribor=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

%Annual
sqlquery=['SELECT value FROM irt_st_a WHERE time IN (',years_str,') AND geo=''EA'' AND int_rt=''IRT_M3'' ORDER BY time'];
data.euribor_yearly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Compensation of employees

%Annual
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''D1'' AND unit=''CP_MEUR'' ORDER BY time'];
data.compensation_employees = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''D1'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.compensation_employees_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Wages

%Annual
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''D11'' AND unit=''CP_MEUR'' ORDER BY time'];
data.wages = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''D11'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.wages_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Operating surplus

%Annual
sqlquery=['SELECT value FROM nama_10_gdp WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''B2A3G'' AND unit=''CP_MEUR'' ORDER BY time'];
data.operating_surplus = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

%Quarterly
sqlquery=['SELECT value FROM namq_10_gdp WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''B2A3G'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY time'];
data.operating_surplus_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Employed

%Annual
sqlquery=['SELECT value FROM nama_10_pe WHERE time IN (',years_str,') AND geo=',geo,' AND na_item=''EMP_DC'' AND unit=''THS_PER'' ORDER BY time'];
data.employed = fetch(conn,sqlquery,'DataReturnFormat','numeric'); 

%Quarterly
sqlquery=['SELECT value FROM namq_10_pe WHERE time IN (',quarters_str,') AND geo=',geo,' AND na_item=''EMP_DC'' AND unit=''THS_PER'' AND s_adj=''SCA'' ORDER BY time'];
data.employed_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Unemployment rate
sqlquery=['SELECT value FROM une_rt_q_h WHERE time IN (',quarters_str,') AND geo=',geo,' AND unit=''PC_ACT'' AND age=''Y15-74'' AND s_adj=''SA'' AND sex=''T'' ORDER BY time'];
data.unemployment_rate_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');

%Annual
sqlquery=['SELECT value FROM une_rt_a_h WHERE time IN (',years_str,') AND geo=',geo,' AND unit=''PC_ACT'' AND age=''Y15-74'' AND sex=''T'' ORDER BY time'];
data.unemployment_rate=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');


%% Sectoral GVA

sqlquery=['SELECT value FROM nama_10_a10 where  time IN (',years_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND unit = ''CP_MEUR'' AND na_item=''B1G'' order by nace_r2, time'];
data.nominal_nace10_gva=fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nominal_nace10_gva=reshape(data.nominal_nace10_gva,length(data.nominal_nace10_gva)/10,10);

sqlquery=['SELECT value FROM nama_10_a10 where  time IN (',years_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND unit = ''CLV10_MEUR'' AND na_item=''B1G'' order by nace_r2, time'];
data.real_nace10_gva=fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.real_nace10_gva=reshape(data.real_nace10_gva,length(data.real_nace10_gva)/10,10);

sqlquery=['SELECT value FROM nama_10_a10 where  time IN (',years_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND unit = ''PD10_EUR'' AND na_item=''B1G'' order by nace_r2, time'];
data.nace10_gva_deflator=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nace10_gva_deflator=reshape(data.nace10_gva_deflator,length(data.nace10_gva_deflator)/10,10);

sqlquery=['SELECT value FROM nama_10_a10 where  time IN (',years_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND unit = ''CLV_PCH_PRE'' AND na_item=''B1G'' order by nace_r2, time'];
data.real_nace10_gva_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.real_nace10_gva_growth=reshape(data.real_nace10_gva_growth,length(data.real_nace10_gva_growth)/10,10);

sqlquery=['SELECT value FROM nama_10_a10 where  time IN (',years_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND unit = ''PD_PCH_PRE_EUR'' AND na_item=''B1G'' order by nace_r2, time'];
data.nace10_gva_deflator_growth=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nace10_gva_deflator_growth=reshape(data.nace10_gva_deflator_growth,length(data.nace10_gva_deflator_growth)/10,10);

data.nominal_nace10_gva_growth=data.real_nace10_gva_growth+data.gva_deflator_growth;

sqlquery=['SELECT value FROM namq_10_a10 WHERE time IN (',quarters_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND na_item=''B1G'' AND unit=''CP_MEUR'' AND s_adj=''SCA'' ORDER BY nace_r2, time'];
data.nominal_nace10_gva_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nominal_nace10_gva_quarterly=reshape(data.nominal_nace10_gva_quarterly,length(data.nominal_nace10_gva_quarterly)/10,10);

sqlquery=['SELECT value FROM namq_10_a10 WHERE time IN (',quarters_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND na_item=''B1G'' AND unit=''CLV10_MEUR'' AND s_adj=''SCA'' ORDER BY nace_r2, time'];
data.real_nace10_gva_quarterly=fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.real_nace10_gva_quarterly=reshape(data.real_nace10_gva_quarterly,length(data.real_nace10_gva_quarterly)/10,10);

sqlquery=['SELECT value FROM namq_10_a10 WHERE time IN (',quarters_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND na_item=''B1G'' AND unit=''PD10_EUR'' AND s_adj=''SCA'' ORDER BY nace_r2, time'];
data.nace10_gva_deflator_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nace10_gva_deflator_quarterly=reshape(data.nace10_gva_deflator_quarterly,length(data.nace10_gva_deflator_quarterly)/10,10);

sqlquery=['SELECT value FROM namq_10_a10 WHERE time IN (',quarters_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND na_item=''B1G'' AND unit=''CLV_PCH_PRE'' AND s_adj=''SCA'' ORDER BY nace_r2, time'];
data.real_nace10_gva_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.real_nace10_gva_growth_quarterly=reshape(data.real_nace10_gva_growth_quarterly,length(data.real_nace10_gva_growth_quarterly)/10,10);

sqlquery=['SELECT value FROM namq_10_a10 WHERE time IN (',quarters_str,') AND geo=',geo,' AND nace_r2 NOT IN (''C'', ''TOTAL'') AND na_item=''B1G'' AND unit=''PD_PCH_PRE_EUR'' AND s_adj=''SCA'' ORDER BY nace_r2, time'];
data.nace10_gva_deflator_growth_quarterly=0.01*fetch(conn,sqlquery,'DataReturnFormat','numeric');
data.nace10_gva_deflator_growth_quarterly=reshape(data.nace10_gva_deflator_growth_quarterly,length(data.nace10_gva_deflator_growth_quarterly)/10,10);

data.nominal_nace10_gva_growth_quarterly=data.real_nace10_gva_growth_quarterly+data.nace10_gva_deflator_growth_quarterly;


%%
%% Adjust length of time series
%%


fields=fieldnames(data);
for l=1:numel(fields)
    eval(['p=length(data.',fields{l},');']);
    if p == length(data.quarters_num)-1 || p == length(data.years_num)-1
        eval(['data.',fields{l},'=[NaN*zeros(1,size(data.',fields{l},',2));data.',fields{l},'];']);
    end
end

data.unemployment_rate=[NaN(length(data.years_num)-length(data.unemployment_rate),1);data.unemployment_rate];
data.unemployment_rate_quarterly=[NaN(length(data.quarters_num)-length(data.unemployment_rate_quarterly),1);data.unemployment_rate_quarterly];

%%
%% Save output variables
%%
%%
if string(geos(g))=="EU27_2020"
    eu=data;
    save('EU.mat','eu');
elseif string(geos(g))=="EA19"
    ea=data;
    save('EA.mat','ea');
else
    save([char(geos(g)),'.mat'],'data');
end
end


%%
%% Clear and Close
%%
%%
close(conn);
clear('conn');
