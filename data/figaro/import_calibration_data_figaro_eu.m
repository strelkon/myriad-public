%% Clear workspace
clear;

%% Connect to Database
conn=database('eurostat_20221225','db_reader','$qldbreader123!','Vendor','PostgreSQL','Server','psqlasa.iiasa.ac.at');

%% Variables to parameterize according to country and year
geo='''AT'' ,''BE'' ,''BG'' ,''HR'' ,''CY'' ,''CZ'' ,''DK'' ,''EE'' ,''FI'' ,''FR'' ,''DE'' ,''GR'' ,''HU'' ,''IE'' ,''IT'' ,''LV'' ,''LT'' ,''LU''  ,''NL'' ,''PL'' ,''PT'' ,''RO'' ,''SK'' ,''SI'' ,''ES'' ,''SE'''; %,''MT''
start_calibration_year=2010;
end_calibration_year=2016;
number_years=end_calibration_year-start_calibration_year+1;
number_quarters=number_years*4;
number_sectors=62;
number_countries=26;

% calculate serial date numbers and format date strings
figaro.years_num=datenum(start_calibration_year+1,1:12:(number_years-1)*12+1,0);
years_str=datestr(figaro.years_num,'\''yyyy\'', ');
years_str=reshape(years_str',1,size(years_str,1)*size(years_str,2));
years_str=years_str(1:end-2);

figaro.quarters_num=datenum(start_calibration_year,4:3:(number_years+3)*12+1,0);
quarters_str=datestr(figaro.quarters_num,'\''yyyyqq\'', ');
quarters_str=reshape(quarters_str',1,size(quarters_str,1)*size(quarters_str,2));
quarters_str=quarters_str(1:end-2);

%% time series
sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') ORDER BY time, colii, rowii, counterpartarea, refarea'];
figaro.intermediate_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.intermediate_consumption=reshape(figaro.intermediate_consumption,number_countries,number_countries,number_sectors,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, colii, rowii, counterpartarea ORDER BY time, colii, rowii, counterpartarea'];
imported_intermediate_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
imported_intermediate_consumption=reshape(imported_intermediate_consumption,number_countries,number_sectors,number_sectors,number_years);

figaro.intermediate_consumption=[figaro.intermediate_consumption;reshape(imported_intermediate_consumption,[1,size(imported_intermediate_consumption)])];

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (''P3_S14'', ''P3_S15'') AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea, refarea ORDER BY time, rowii, counterpartarea, refarea'];
figaro.household_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.household_consumption=reshape(figaro.household_consumption,number_countries,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii IN (''P3_S14'', ''P3_S15'') AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea ORDER BY time, rowii, counterpartarea'];
imported_household_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
imported_household_consumption=reshape(imported_household_consumption,number_countries,number_sectors,number_years);

figaro.household_consumption=[figaro.household_consumption;reshape(imported_household_consumption,[1,size(imported_household_consumption)])];

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P51G'' AND time IN (',years_str,') ORDER BY time, rowii, counterpartarea, refarea'];
figaro.fixed_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.fixed_capitalformation=reshape(figaro.fixed_capitalformation,number_countries,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P51G'' AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea ORDER BY time, rowii, counterpartarea'];
imported_fixed_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');
imported_fixed_capitalformation=reshape(imported_fixed_capitalformation,number_countries,number_sectors,number_years);

figaro.fixed_capitalformation=[figaro.fixed_capitalformation;reshape(imported_fixed_capitalformation,[1,size(imported_fixed_capitalformation)])];

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P5M'' AND time IN (',years_str,') ORDER BY time, rowii, counterpartarea, refarea'];
figaro.inventory_changes=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.inventory_changes=reshape(figaro.inventory_changes,number_countries,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P5M'' AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea ORDER BY time, rowii, counterpartarea'];
imported_inventory_changes=fetch(conn,sqlquery,'DataReturnFormat','numeric');
imported_inventory_changes=reshape(imported_inventory_changes,number_countries,number_sectors,number_years);

figaro.inventory_changes=[figaro.inventory_changes;reshape(imported_inventory_changes,[1,size(imported_inventory_changes)])];
figaro.capitalformation=figaro.fixed_capitalformation+figaro.inventory_changes;

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea ORDER BY time, rowii, counterpartarea'];
imports=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.imports=reshape(imports,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea NOT IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') GROUP BY time, rowii, refarea ORDER BY time, rowii, refarea'];
exports=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.exports=reshape(exports,number_countries,number_sectors,number_years);

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P3_S13'' AND time IN (',years_str,') ORDER BY time, rowii, counterpartarea, refarea'];
figaro.government_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.government_consumption=reshape(figaro.government_consumption,number_countries,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND refarea NOT IN (',geo,') AND rowii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND colii=''P3_S13'' AND time IN (',years_str,') GROUP BY time, rowii, counterpartarea ORDER BY time, rowii, counterpartarea'];
imported_government_consumption=fetch(conn,sqlquery,'DataReturnFormat','numeric');
imported_government_consumption=reshape(imported_government_consumption,number_countries,number_sectors,number_years);

figaro.government_consumption=[figaro.government_consumption;reshape(imported_government_consumption,[1,size(imported_government_consumption)])];

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND rowii=''B2A3G'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') ORDER BY time, colii, counterpartarea'];
figaro.operating_surplus=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.operating_surplus=reshape(figaro.operating_surplus,number_countries,number_sectors,number_years);

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND rowii=''D1'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') ORDER BY time, colii, counterpartarea'];
figaro.compensation_employees=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.compensation_employees=reshape(figaro.compensation_employees,number_countries,number_sectors,number_years);

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND rowii=''D29X39'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') ORDER BY time, colii, counterpartarea'];
figaro.taxes_production=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_production=reshape(figaro.taxes_production,number_countries,number_sectors,number_years);

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND rowii=''D21X31'' AND colii IN (SELECT nace_figaro FROM nace64 WHERE nace NOT IN (''L68A'', ''T'', ''U'')) AND time IN (',years_str,') ORDER BY time, colii, counterpartarea'];
figaro.taxes_products=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_products=reshape(figaro.taxes_products,number_countries,number_sectors,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND colii IN (''P3_S14'',''P3_S15'') AND rowii=''D21X31'' AND time IN (',years_str,') GROUP BY time, counterpartarea ORDER BY time, counterpartarea'];
figaro.taxes_products_household=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_products_household=reshape(figaro.taxes_products_household,number_countries,number_years);

sqlquery=['SELECT sum(obsvalue) FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND colii IN (''P51G'',''P5M'') AND rowii=''D21X31'' AND time IN (',years_str,') GROUP BY time, counterpartarea ORDER BY time, counterpartarea'];
figaro.taxes_products_capitalformation=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_products_capitalformation=reshape(figaro.taxes_products_capitalformation,number_countries,number_years);

sqlquery=['SELECT obsvalue FROM eu_ic_io_ind_by_ind WHERE counterpartarea IN (',geo,') AND colii=''P3_S13'' AND rowii=''D21X31'' AND time IN (',years_str,') ORDER BY time, counterpartarea'];
figaro.taxes_products_government=fetch(conn,sqlquery,'DataReturnFormat','numeric');
figaro.taxes_products_government=reshape(figaro.taxes_products_government,number_countries,number_years);

figaro.taxes_products_export=zeros(size(figaro.taxes_products_government));

save('EU.mat','figaro');
