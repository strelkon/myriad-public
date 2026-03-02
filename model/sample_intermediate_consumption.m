function y=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,s_a_ffs,F,G)
s_a_ffs=s_a_ffs./histcounts(F_if(F_g),1:F+2)';
s_a_ffs=s_a_ffs(F_if(F_g),:,:);
s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
y=NaN(1,numel(I_g));

% Group indices for each unique (f,g) combination in F_i(I_g) and G_i(I_g)
[groupPairs,~,groupIDs]=unique([F_i(I_g)',G_i(I_g)'],'rows');

% Loop over each group (only groups that occur in I_g)
for grp=1:size(groupPairs,1)
    f=groupPairs(grp,1);
    g=groupPairs(grp,2);
    
    % Find indices corresponding to this (f,g)
    groupIdx=find(groupIDs==grp);
    k=numel(groupIdx);
    
    % Get the corresponding s vector for current f and g
    s=s_a_ffs(:,f,g);
    
    if sum(s)>0
        % Normalize s and compute weights w
        s=s/sum(s);
        w=p_gamma.*s;
        w=w/sum(w);
        
        % Sample and assign values for all indices in this group
        y(groupIdx)=sample(F_g, k, w);
    end
end
end
