function y=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,s_a_ffs,F,G)
s_a_ffs=s_a_ffs./histcounts(F_if(F_g),1:F+2)';
s_a_ffs=s_a_ffs(F_if(F_g),:,:);
% s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
y=NaN(1,length(I_g));

for f=1:F
    for g=1:G
        idx=find(F_i(I_g)==f&G_i(I_g)==g);
        s=s_a_ffs(:,f,g);
        if sum(s)>0
            s=s/sum(s);
            w=p_gamma.*s;
            w=w/sum(w);
            k=length(idx);
            y(idx)=sample(F_g,k,w);
        end
    end
end
end
