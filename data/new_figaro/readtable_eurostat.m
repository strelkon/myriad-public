function T = readtable_eurostat(dataset)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
% dataset   = "naio_10_fcp_ii3";       % Eurostat codes are case-insensitive but upper-case is the convention
apiRoot   = "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/";
query     = dataset + "?format=SDMX-CSV&compressed=true&attributes=none";   % TSV + gzip keeps the file small
url       = apiRoot + query;

gzFile    = dataset + ".csv.gz";
websave(gzFile, url);
csvFile   = string(gunzip(gzFile));

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 12);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["DATAFLOW", "LASTUPDATE", "freq", "ind_use", "ind_ava", "c_dest", "unit", "c_orig", "time", "value", "OBS_FLAG", "CONF_STATUS"];
opts.SelectedVariableNames = ["freq", "ind_use", "ind_ava", "c_dest", "unit", "c_orig", "time", "value"];
opts.VariableTypes = ["string", "string", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["DATAFLOW", "LASTUPDATE", "OBS_FLAG", "CONF_STATUS"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["DATAFLOW", "LASTUPDATE", "freq", "ind_use", "ind_ava", "c_dest", "unit", "c_orig", "OBS_FLAG", "CONF_STATUS"], "EmptyFieldRule", "auto");

T = readtable(csvFile, opts);

delete(csvFile);
end