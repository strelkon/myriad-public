function DL_i=search_and_matching_credit(DL_d_i,K_e_i,L_e_i,E_k,zeta,zeta_LTV)
    DL_i=zeros(size(DL_d_i));
    sum_L_e_i=sum(L_e_i);
    I_FG=shuffle(find(DL_d_i>0));
    for f=1:length(I_FG)
        i=I_FG(f);
        DL_i(i)=max(0,min(min(DL_d_i(i),zeta_LTV*K_e_i(i)-L_e_i(i)),E_k/zeta-sum_L_e_i));
        sum_L_e_i=sum_L_e_i+DL_i(i);
    end
end

