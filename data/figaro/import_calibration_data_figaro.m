%% Clear workspace
clear;

%% Connect to Database
conn=database('eurostat_20221225','db_reader','$qldbreader123!','Vendor','PostgreSQL','Server','psqlasa.iiasa.ac.at');

%% Variables to parameterize according to country and year
geos={'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EL', 'ES', 'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK'};
start_calibration_year=2010;
end_calibration_year=2016;
number_years=end_calibration_year-start_calibration_year+1;
number_quarters=number_years*4;
number_sectors=62;

% calculate serial date numbers and format date strings
figaro.years_num=datenum(start_calibration_year+1,1:12:(number_years-1)*12+1,0);
years_str=datestr(figaro.years_num,'\''yyyy\'', ');
years_str=reshape(years_str',1,size(years_str,1)*size(years_str,2));
years_str=years_str(1:end-2);

figaro.quarters_num=datenum(start_calibration_year,4:3:(number_years+3)*12+1,0);
quarters_str=datestr(figaro.quarters_num,'\''yyyyqq\'', ');
quarters_str=reshape(quarters_str',1,size(quarters_str,1)*size(quarters_str,2));
quarters_str=quarters_str(1:end-2);

for g=1:length(geos)

if string(geos(g))=="EL"
    geo='''GR''';
else
    geo=['''',char(geos(g)),''''];
end

%% time series
sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii, rowii ORDER BY time, colii, rowii'];
figaro.intermediate_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.intermediate_consumption=reshape(figaro.intermediate_consumption,number_sectors,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (''P3_S14'', ''P3_S15'') AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.household_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.household_consumption=reshape(figaro.household_consumption,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P51G'' AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.fixed_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.fixed_capitalformation=reshape(figaro.fixed_capitalformation,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P5M'' AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.inventory_changes=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.inventory_changes=reshape(figaro.inventory_changes,number_sectors,number_years);

figaro.capitalformation=figaro.fixed_capitalformation+figaro.inventory_changes;

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE refarea!=',geo,' and counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.imports=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.imports=reshape(figaro.imports,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE refarea=',geo,' and counterpartarea!=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.exports=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.exports=reshape(figaro.exports,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P3_S13'' AND time IN (',years_str,') GROUP BY time, rowii ORDER BY time, rowii'];
figaro.government_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.government_consumption=reshape(figaro.government_consumption,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii=''B2A3G'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii ORDER BY time, colii'];
figaro.operating_surplus=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.operating_surplus=reshape(figaro.operating_surplus,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii=''D1'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii ORDER BY time, colii'];
figaro.compensation_employees=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.compensation_employees=reshape(figaro.compensation_employees,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii=''D29X39'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii ORDER BY time, colii'];
figaro.taxes_production=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_production=reshape(figaro.taxes_production,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND rowii=''D21X31'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii ORDER BY time, colii'];
figaro.taxes_products=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_products=reshape(figaro.taxes_products,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND colii IN (''P3_S14'',''P3_S15'') AND rowii=''D21X31'' AND time IN (',years_str,') GROUP BY time ORDER BY time'];
figaro.taxes_products_household=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND colii IN (''P51G'',''P5M'') AND rowii=''D21X31'' AND time IN (',years_str,') GROUP BY time ORDER BY time'];
figaro.taxes_products_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea=',geo,' AND colii=''P3_S13'' AND rowii=''D21X31'' AND time IN (',years_str,') ORDER BY time'];
figaro.taxes_products_government=fetch(conn,sqlquery,'DataReturnFormat','numeric');

% figaro.taxes_products_export=zeros(size(figaro.taxes_products_household));

% figaro.wages=0.825*figaro.compensation_employees;

% figaro.capital_consumption=0.1*(squeeze(sum(figaro.intermediate_consumption,1))+figaro.operating_surplus+figaro.compensation_employees+figaro.taxes_production+figaro.taxes_products);

% figaro.operating_surplus=figaro.operating_surplus-figaro.capital_consumption;

if string(geos(g))=="IE"
    figaro.compensation_employees(3,:)=interp1(3:7,figaro.compensation_employees(3,3:7),1:7,'linear','extrap');
    figaro.compensation_employees(57,:)=interp1(3:7,figaro.compensation_employees(57,3:7),1:7,'linear','extrap');
    figaro.compensation_employees(10,:)=interp1([1 2 3 4 6 7],figaro.compensation_employees(10,[1 2 3 4 6 7]),1:7,'linear','extrap');
end

save([char(geos(g)),'.mat'],'figaro');
end
