clear;
load('EU.new.mat')

domestic_use=squeeze(sum(figaro.intermediate_consumption,3))+squeeze(figaro.government_consumption+figaro.household_consumption+figaro.capitalformation);
output=squeeze(sum(figaro.intermediate_consumption,2))+squeeze(figaro.operating_surplus+figaro.compensation_employees+figaro.taxes_production+figaro.taxes_products);
imports=figaro.imports;
exports=figaro.exports;
sum(sum(squeeze(sum(domestic_use-output,1))+exports-imports))
