/*
** main.c
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mat.h"
#include "simulate_abm.h"
#include "simulate_abm_initialize.h"
#include "simulate_abm_terminate.h"

#define TIME 13
#define COUNTRIES 26
#define SECTORS 62

int main(int argc, char **argv)
{
    int T = (int) TIME;
    int F = (int) COUNTRIES;
    int G = (int) SECTORS;
    
    double year = (double) atoi(argv[1]);
    double quarter = (double) atoi(argv[2]);
    double seed = (double) atoi(argv[3]);
    double scenario = (double) atoi(argv[4]);
    const mwSize dims[]={T,F,G};
    
    mxArray *mxnominal_gdp = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_gdp = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_gva = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_gva = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_household_consumption = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_household_consumption = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_government_consumption = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_government_consumption = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_capitalformation = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_capitalformation = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_fixed_capitalformation = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_fixed_capitalformation = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_fixed_capitalformation_dwellings = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_fixed_capitalformation_dwellings = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_exports = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_exports = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_imports = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_imports = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxoperating_surplus = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxcapital_consumption = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxcompensation_employees = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxwages = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxtaxes_production = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_sector_gva = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxreal_sector_gva = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxsector_operating_surplus = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxsector_capital_consumption = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxnominal_output = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxreal_output = mxCreateDoubleMatrix(T,F,mxREAL);
    mxArray *mxnominal_sector_output = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxreal_sector_output = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    mxArray *mxgovernment_debt = mxCreateDoubleMatrix(1,T,mxREAL);
    mxArray *mxgovernment_deficit = mxCreateDoubleMatrix(1,T,mxREAL);
    mxArray *mxunemployment_rate = mxCreateDoubleMatrix(1,T,mxREAL);
    mxArray *mxeuribor = mxCreateDoubleMatrix(1,T,mxREAL);
    
    simulate_abm_initialize();
    
    simulate_abm(year,quarter,seed,scenario,mxGetPr(mxnominal_gdp),mxGetPr(mxreal_gdp),mxGetPr(mxnominal_gva),mxGetPr(mxreal_gva),mxGetPr(mxnominal_household_consumption),mxGetPr(mxreal_household_consumption),mxGetPr(mxnominal_government_consumption),mxGetPr(mxreal_government_consumption),mxGetPr(mxnominal_capitalformation),mxGetPr(mxreal_capitalformation),mxGetPr(mxnominal_fixed_capitalformation),mxGetPr(mxreal_fixed_capitalformation),mxGetPr(mxnominal_fixed_capitalformation_dwellings),mxGetPr(mxreal_fixed_capitalformation_dwellings),mxGetPr(mxnominal_exports),mxGetPr(mxreal_exports),mxGetPr(mxnominal_imports),mxGetPr(mxreal_imports),mxGetPr(mxoperating_surplus),mxGetPr(mxcapital_consumption),mxGetPr(mxcompensation_employees),mxGetPr(mxwages),mxGetPr(mxtaxes_production),mxGetPr(mxnominal_sector_gva),mxGetPr(mxreal_sector_gva),mxGetPr(mxsector_operating_surplus),mxGetPr(mxsector_capital_consumption),mxGetPr(mxnominal_output),mxGetPr(mxreal_output),mxGetPr(mxnominal_sector_output),mxGetPr(mxreal_sector_output),mxGetPr(mxgovernment_debt),mxGetPr(mxgovernment_deficit),mxGetPr(mxunemployment_rate),mxGetPr(mxeuribor));
    
    MATFile *pmat;
    char scenario_string[32];
    sprintf(scenario_string, "%d",(int) scenario);
    char *file = strcat(scenario_string,"_");
    char year_string[32];
    sprintf(year_string, "%d",(int) year);
    strcat(year_string,"Q");
    strcat(file,year_string);
    char quarter_string[32];
    sprintf(quarter_string, "%d",(int) quarter);
    strcat(file,quarter_string);
    strcat(file,"_");
    char seed_string[32];
    sprintf(seed_string, "%d",(int) seed);
    strcat(file,seed_string);
    strcat(file,".mat");
    pmat = matOpen(file,"w");
    matPutVariable(pmat,"nominal_gdp",mxnominal_gdp);
    matPutVariable(pmat,"real_gdp",mxreal_gdp);
    matPutVariable(pmat,"nominal_gva",mxnominal_gva);
    matPutVariable(pmat,"real_gva",mxreal_gva);
    matPutVariable(pmat,"nominal_household_consumption",mxnominal_household_consumption);
    matPutVariable(pmat,"real_household_consumption",mxreal_household_consumption);
    matPutVariable(pmat,"nominal_government_consumption",mxnominal_government_consumption);
    matPutVariable(pmat,"real_government_consumption",mxreal_government_consumption);
    matPutVariable(pmat,"nominal_capitalformation",mxnominal_capitalformation);
    matPutVariable(pmat,"real_capitalformation",mxreal_capitalformation);
    matPutVariable(pmat,"nominal_fixed_capitalformation",mxnominal_fixed_capitalformation);
    matPutVariable(pmat,"real_fixed_capitalformation",mxreal_fixed_capitalformation);
    matPutVariable(pmat,"nominal_fixed_capitalformation_dwellings",mxnominal_fixed_capitalformation_dwellings);
    matPutVariable(pmat,"real_fixed_capitalformation_dwellings",mxreal_fixed_capitalformation_dwellings);
    matPutVariable(pmat,"nominal_exports",mxnominal_exports);
    matPutVariable(pmat,"real_exports",mxreal_exports);
    matPutVariable(pmat,"nominal_imports",mxnominal_imports);
    matPutVariable(pmat,"real_imports",mxreal_imports);
    matPutVariable(pmat,"operating_surplus",mxoperating_surplus);
    matPutVariable(pmat,"capital_consumption",mxcapital_consumption);
    matPutVariable(pmat,"compensation_employees",mxcompensation_employees);
    matPutVariable(pmat,"wages",mxwages);
    matPutVariable(pmat,"taxes_production",mxtaxes_production);
    matPutVariable(pmat,"nominal_sector_gva",mxnominal_sector_gva);
    matPutVariable(pmat,"real_sector_gva",mxreal_sector_gva);
    matPutVariable(pmat,"sector_operating_surplus",mxsector_operating_surplus);
    matPutVariable(pmat,"sector_capital_consumption",mxsector_capital_consumption);
    matPutVariable(pmat,"nominal_output",mxnominal_output);
    matPutVariable(pmat,"real_output",mxreal_output);
    matPutVariable(pmat,"nominal_sector_output",mxnominal_sector_output);
    matPutVariable(pmat,"real_sector_output",mxreal_sector_output);
    matPutVariable(pmat,"government_debt",mxgovernment_debt);
    matPutVariable(pmat,"government_deficit",mxgovernment_deficit);
    matPutVariable(pmat,"unemployment_rate",mxunemployment_rate);
    matPutVariable(pmat,"euribor",mxeuribor);
    matClose(pmat);
    
    simulate_abm_terminate();
    
    return(EXIT_SUCCESS);
}
