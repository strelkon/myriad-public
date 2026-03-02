clear;

values_missing=[];
missing_variables=[];
geos={'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EL', 'ES', 'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK'};
for g=1:length(geos)
    
    geo=['''',char(geos(g)),''''];
    
    try
        load([char(geos(g)),'.mat'],'calibration_data');
    catch
    end
    
    fields=fieldnames(calibration_data);
    for l=3:numel(fields)
        variable=fields(l);
        eval(['p=size(calibration_data.',fields{l},');']);
        eval(['missing=any(any(any(isnan((calibration_data.',fields{l},'))))) | isempty(calibration_data.',fields{l},');']);
        if  contains(variable,'_quarterly') && all(p ~= length(calibration_data.quarters_num))
            values_missing=[values_missing;geo,variable];
        elseif  ~contains(variable,'_quarterly') && all(p ~= length(calibration_data.years_num))
            values_missing=[values_missing;geo,variable];
        end
        if missing
            variable=fields(l);
            missing_variables=[missing_variables;char(geos(g)),variable];
        end
    end
end
