function y=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,s_CF_ff,s_CFH_ff,s_HH_ff,s_G_ff,s_E_f,F,I,L,H)
y=NaN(1,length(H_g));

% firm investment
y(H_g<=I)=sample_final_demand_(F_g,P_f,F_if,H_g(H_g<=I),F_if,s_CF_ff,F,I);

% household consumption and household investment
y(H_g>I&H_g<=H+I)=sample_final_demand_(F_g,P_f,F_if,H_g(H_g>I&H_g<=H+I)-I,F_hf,s_HH_ff,F,I);

% government consumption
y(H_g>H+I+L)=sample_final_demand_(F_g,P_f,F_if,H_g(H_g>H+I+L)-I,F_hf,s_G_ff,F,I);

% exports
y(H_g>H+I&H_g<=H+I+L)=sample_final_demand__(F_g,P_f,F_if,H_g(H_g>H+I&H_g<=H+I+L)-I,F_hf,[s_E_f;0],F,I);
end

function y=sample_final_demand_(F_g,P_f,F_if,H_g,F_hf,s_a_ffs,F,I)
s_a_ffs=s_a_ffs./histcounts(F_if(F_g),1:F+2)';
s_a_ffs=s_a_ffs(F_if(F_g),:);
s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
y=NaN(1,length(H_g));
F_hf_=F_hf(H_g);
for f=1:F
    idx=find(F_hf_==f);
    s=s_a_ffs(:,f);
    if sum(s)>0
        s=s/sum(s);
        w=p_gamma.*s;
        w=w/sum(w);
        k=length(idx);
        y(idx)=sample(F_g,k,w);
    end
end
end

function y=sample_final_demand__(F_g,P_f,F_if,H_g,F_hf,s_a_ffs,F,I)
s_a_ffs=s_a_ffs./histcounts(F_if(F_g),1:F+2)';
s_a_ffs=s_a_ffs(F_if(F_g));
s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
s=s_a_ffs;
y=NaN(1,length(H_g));
if sum(s)>0
    s=s/sum(s);
    w=p_gamma.*s;
    w=w/sum(w);
    k=length(H_g);
    y=sample(F_g,k,w);
end
end
