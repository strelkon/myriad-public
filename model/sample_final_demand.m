function y=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,s_CF_ff,s_CFH_ff,s_HH_ff,s_G_ff,s_E_f,F,I,L,H)
y=NaN(1,length(H_g));

% firm investment
mask_I=H_g<=I;
y(mask_I)=sample_final_demand_(F_g,P_f,F_if,H_g(mask_I),F_if,s_CF_ff,F,I);

% household consumption and household investment
mask_HH=H_g>I&H_g<=H+I;
y(mask_HH)=sample_final_demand_(F_g,P_f,F_if,H_g(mask_HH)-I,F_hf,s_HH_ff,F,I);

% government consumption
mask_G=H_g>H+I+L;
y(mask_G)=sample_final_demand_(F_g,P_f,F_if,H_g(mask_G)-I,F_hf,s_G_ff,F,I);

% exports
mask_E=H_g>H+I&H_g<=H+I+L;
y(mask_E)=sample_final_demand__(F_g,P_f,F_if,H_g(mask_E)-I,F_hf,[s_E_f;0],F,I);
end

function y=sample_final_demand_(F_g,P_f,F_if,H_g,F_hf,s_a_ffs,F,I)
supply_types=F_if(F_g);
s_a_ffs=s_a_ffs./histcounts(supply_types,1:F+2)';
s_a_ffs=s_a_ffs(supply_types,:);
s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
y=NaN(1,length(H_g));
F_hf_=F_hf(H_g);
group_counts=zeros(F,1);
for j=1:length(F_hf_)
    group_counts(F_hf_(j))=group_counts(F_hf_(j))+1;
end

group_offsets=zeros(F,1);
next_offset=zeros(F,1);
offset=1;
for f=1:F
    group_offsets(f)=offset;
    next_offset(f)=offset;
    offset=offset+group_counts(f);
end

group_positions=zeros(1,length(H_g));
for j=1:length(F_hf_)
    f=F_hf_(j);
    pos=next_offset(f);
    group_positions(pos)=j;
    next_offset(f)=pos+1;
end

for f=1:F
    s=s_a_ffs(:,f);
    s_sum=sum(s);
    if s_sum>0
        s=s./s_sum;
        w=p_gamma.*s;
        w=w./sum(w);
        k=group_counts(f);
        draws=sample(F_g,k,w);
        if k>0
            pos=group_positions(group_offsets(f):group_offsets(f)+k-1);
            y(pos)=draws;
        end
    end
end
end

function y=sample_final_demand__(F_g,P_f,F_if,H_g,F_hf,s_a_ffs,F,I)
supply_types=F_if(F_g);
s_a_ffs=s_a_ffs./histcounts(supply_types,1:F+2)';
s_a_ffs=s_a_ffs(supply_types);
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
