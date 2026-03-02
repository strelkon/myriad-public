clear;

values_missing=[];
missing_variables=[];
geos={'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EL', 'ES', 'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK'};
for g=1:length(geos)
    
    geo=['''',char(geos(g)),''''];
    
    try
        load([char(geos(g)),'.mat'],'data');
    catch
    end
    
    fields=fieldnames(data);
    for l=3:numel(fields)
        variable=fields(l);
        eval(['p=length(data.',fields{l},');']);
        eval(['missing=isempty(data.',fields{l},');']);
        if  contains(variable,'_quarterly') && p ~= length(data.quarters_num)
            values_missing=[values_missing;geo,variable];
        elseif  ~contains(variable,'_quarterly') && p ~= length(data.years_num)
            values_missing=[values_missing;geo,variable];
        end
        if missing
            missing_variables=[missing_variables;char(geos(g)),variable];
        end
    end
end
