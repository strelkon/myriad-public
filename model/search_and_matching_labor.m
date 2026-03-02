function [N_i,O_h]=search_and_matching_labor(N_i,V_i,O_h)
H_E=shuffle(find(O_h>0));
for e=1:length(H_E)
    h=H_E(e);
    i=O_h(h);
    if V_i(i)<0
        O_h(h)=0;
        N_i(i)=N_i(i)-1;
        V_i(i)=V_i(i)+1;
    end
end

H_U=shuffle(find(O_h==0),min(sum(O_h==0),sum(max(0,V_i))));
I_V=shuffle(repelem(1:length(V_i),max(0,V_i)),min(sum(O_h==0),sum(max(0,V_i))));
O_h(H_U)=I_V;
N_i(I_V)=N_i(I_V)+max(0,V_i(I_V));
end

