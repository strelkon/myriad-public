sum(Y_i)+sum(Y_m)-(sum(DM_d_i+I_d_i)+sum(C_d_h+I_d_h)+sum(C_d_j)+sum(C_d_l))

for g=1:G
    diff_g(g)=sum(Y_i(G_i==g))+sum(Y_m(g))-(sum(a_sg(g,G_i).*DM_d_i)+sum(b_CF_g(g)*I_d_i)+b_HH_g(g)*sum(C_d_h)+b_CFH_g(g)*sum(I_d_h)+c_G_g(g)*sum(C_d_j)+c_E_g(g)*sum(C_d_l));
end