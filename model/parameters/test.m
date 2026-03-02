clear;

negative_parameter=[];
parameter=load('2015Q4.mat');

fields=fieldnames(parameter);
for l=1:numel(fields)
    %         if string(fields(l))=="firms"
    %            continue;
    %         end
    
    eval(['negative=any(any(any(parameter.',fields{l},'<0)));']);
    if negative
        variable=fields(l);
        negative_parameter=[negative_parameter;variable];
    end
end

negative_parameter=unique(cell2table(negative_parameter));
