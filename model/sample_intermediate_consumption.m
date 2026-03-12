function y=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,s_a_ffs,F,G)
supply_types=F_if(F_g);
s_a_ffs=s_a_ffs./histcounts(supply_types,1:F+2)';
s_a_ffs=s_a_ffs(supply_types,:,:);
s_a_ffs=s_a_ffs+eps;

p=P_f(F_g)';
gamma=-2;
p_gamma=p.^gamma;
y=NaN(1,length(I_g));

group_ids=G_i(I_g)+G.*(F_i(I_g)-1);
group_counts=zeros(F*G,1);
for j=1:length(group_ids)
    group_counts(group_ids(j))=group_counts(group_ids(j))+1;
end

group_offsets=zeros(F*G,1);
next_offset=zeros(F*G,1);
offset=1;
for gid=1:F*G
    group_offsets(gid)=offset;
    next_offset(gid)=offset;
    offset=offset+group_counts(gid);
end

group_positions=zeros(1,length(I_g));
for j=1:length(group_ids)
    gid=group_ids(j);
    pos=next_offset(gid);
    group_positions(pos)=j;
    next_offset(gid)=pos+1;
end

active_groups=find(group_counts>0);
for grp=1:length(active_groups)
    gid=active_groups(grp);
    f=floor((gid-1)/G)+1;
    g=gid-G.*(f-1);
    s=s_a_ffs(:,f,g);
    s_sum=sum(s);
    if s_sum>0
        s=s./s_sum;
        w=p_gamma.*s;
        w=w./sum(w);
        k=group_counts(gid);
        pos=group_positions(group_offsets(gid):group_offsets(gid)+k-1);
        y(pos)=sample(F_g,k,w);
    end
end
end
