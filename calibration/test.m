domestic_use=squeeze(sum(intermediate_consumption,2))+household_consumption+government_consumption+capitalformation;
output=squeeze(sum(intermediate_consumption))+taxes_products+taxes_production+compensation_employees+operating_surplus;
sum(domestic_use-output,2)+exports-imports
