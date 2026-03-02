function [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,capital_consumption,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,sector_operating_surplus,sector_capital_consumption,nominal_output,real_output,nominal_sector_output,real_sector_output,government_debt,government_deficit,unemployment_rate,euribor]=simulate_abm(year,quarter,seed,scenario)
rng(seed);
T=12;
G=62;
coder.varsize('a_sg','G_i');

parameters=coder.load(['./parameters/',num2str(year),'Q',num2str(quarter),'.mat'],'T','T_max','S','G','H_act','H_inact','J','L','tau_INC','tau_FIRM','tau_VAT','tau_SIF','tau_SIW','tau_EXPORT','tau_CF','tau_G','theta_UB','psi','psi_H','theta_DIV','theta','mu','r_G','zeta','zeta_LTV','zeta_b','I_sr','alpha_sr','beta_sr','kappa_sr','delta_sr','w_sr','tau_Y_sr','tau_K_sr','b_CF_g','b_CFH_g','b_HH_g','c_G_g','c_E_g','c_I_g','a_sg','T_prime','pi_star','alpha_gamma_G','beta_gamma_G','alpha_gamma_E','beta_gamma_E','alpha_gamma_I','beta_gamma_I','alpha_pi_G','beta_pi_G','alpha_pi_E','beta_pi_E','alpha_pi_I','beta_pi_I','C','F','s_a_ffsg','s_CF_ffg','s_CFH_ffg','s_HH_ffg','s_G_ffg','s_E_fg');
initial_conditions=coder.load(['./initial_conditions/',num2str(year),'Q',num2str(quarter),'.mat'],'D_H','D_I','D_RoW','E_CB','E_k','K_H','L_G','L_I','omega','sb_inact','sb_other','w_UB','N_sr','Y','gamma','pi','P','r_bar','gamma_G','C_G','pi_G','P_G','gamma_E','C_E','pi_E','P_E','gamma_I','Y_I','pi_I','P_I','Y_f','gamma_f','pi_f','P_f');shock=coder.load('./shock/2023.mat');  

F=parameters.F;
% G=parameters.G;
H_act=parameters.H_act;
H_inact=parameters.H_inact;
J=parameters.J;
L=parameters.L;
tau_INC=parameters.tau_INC;
tau_FIRM=parameters.tau_FIRM;
tau_VAT=parameters.tau_VAT;
tau_SIF=parameters.tau_SIF;
tau_SIW=parameters.tau_SIW;
tau_EXPORT=parameters.tau_EXPORT;
tau_CF=parameters.tau_CF;
tau_G=parameters.tau_G;
theta_UB=parameters.theta_UB;
psi=parameters.psi;
psi_H=parameters.psi_H;
theta_DIV=parameters.theta_DIV;
theta=parameters.theta;
mu=parameters.mu;
r_G=parameters.r_G;
zeta=parameters.zeta;
zeta_LTV=parameters.zeta_LTV;
zeta_b=parameters.zeta_b;
I_sr=parameters.I_sr;
alpha_sr=parameters.alpha_sr;
beta_sr=parameters.beta_sr;
kappa_sr=parameters.kappa_sr;
delta_sr=parameters.delta_sr;
w_sr=parameters.w_sr;
tau_Y_sr=parameters.tau_Y_sr;
tau_K_sr=parameters.tau_K_sr;
b_CF_g=parameters.b_CF_g;
b_CFH_g=parameters.b_CFH_g;
b_HH_g=parameters.b_HH_g;
c_G_g=parameters.c_G_g;
c_E_g=parameters.c_E_g;
c_I_g=parameters.c_I_g;
a_sg=parameters.a_sg;
% T=parameters.T;
T_prime=parameters.T_prime;
T_max=parameters.T_max;
alpha_gamma_G=parameters.alpha_gamma_G;
beta_gamma_G=parameters.beta_gamma_G;
alpha_gamma_E=parameters.alpha_gamma_E;
beta_gamma_E=parameters.beta_gamma_E;
alpha_gamma_I=parameters.alpha_gamma_I;
beta_gamma_I=parameters.beta_gamma_I;
alpha_pi_G=parameters.alpha_pi_G;
beta_pi_G=parameters.beta_pi_G;
alpha_pi_E=parameters.alpha_pi_E;
beta_pi_E=parameters.beta_pi_E;
alpha_pi_I=parameters.alpha_pi_I;
beta_pi_I=parameters.beta_pi_I;
C=parameters.C;
s_a_ffsg=parameters.s_a_ffsg;
s_CF_ffg=parameters.s_CF_ffg;
s_CFH_ffg=parameters.s_CFH_ffg;
s_HH_ffg=parameters.s_HH_ffg;
s_G_ffg=parameters.s_G_ffg;
s_E_fg=parameters.s_E_fg;

I=sum(sum(I_sr));
G_i=zeros(1,I);
F_i=zeros(1,I);
for g=1:G
    for f=1:F
        i=sum(sum(I_sr(1:g-1,:)))+sum(sum(I_sr(g,1:f-1)));
        j=I_sr(g,f);
        G_i(i+1:i+j)=g;
        F_i(i+1:i+j)=f;
    end
end

alpha_bar_i=zeros(1,I);
beta_i=zeros(1,I);
kappa_i=zeros(1,I);
w_bar_i=zeros(1,I);
delta_i=zeros(1,I);
tau_Y_i=zeros(1,I);
tau_K_i=zeros(1,I);
for i=1:I
    g=G_i(i);
    f=F_i(i);
    alpha_bar_i(i)=alpha_sr(g,f);
    beta_i(i)=beta_sr(g,f);
    kappa_i(i)=kappa_sr(g,f);
    delta_i(i)=delta_sr(g,f);
    w_bar_i(i)=w_sr(g,f);
    tau_Y_i(i)=tau_Y_sr(g,f);
    tau_K_i(i)=tau_K_sr(g,f);
end

Y=initial_conditions.Y;
gamma=initial_conditions.gamma;
pi=initial_conditions.pi;
P=initial_conditions.P;
Y_f=initial_conditions.Y_f;
gamma_f=initial_conditions.gamma_f;
pi_f=initial_conditions.pi_f;
P_f=initial_conditions.P_f;
r_bar=initial_conditions.r_bar;
gamma_G=initial_conditions.gamma_G;
C_G=initial_conditions.C_G;
pi_G=initial_conditions.pi_G;
P_G=initial_conditions.P_G;
gamma_E=initial_conditions.gamma_E;
C_E=initial_conditions.C_E;
pi_E=initial_conditions.pi_E;
P_E=initial_conditions.P_E;
gamma_I=initial_conditions.gamma_I;
Y_I=initial_conditions.Y_I;
pi_I=initial_conditions.pi_I;
P_I=initial_conditions.P_I;

Y=[Y;zeros(T,1)];
pi=[pi;zeros(T,1)];

D_H=initial_conditions.D_H;
D_I=initial_conditions.D_I;
D_RoW=initial_conditions.D_RoW;
E_CB=initial_conditions.E_CB;
E_k=initial_conditions.E_k;
K_H=initial_conditions.K_H;
L_G=initial_conditions.L_G;
L_I=initial_conditions.L_I;
omega=initial_conditions.omega;
sb_inact=initial_conditions.sb_inact;
sb_other=initial_conditions.sb_other;
w_UB=initial_conditions.w_UB;
N_sr=initial_conditions.N_sr;

gamma_X_gr=shock.gamma_X_gr;

P_bar_g=ones(G,1);
P_bar_HH=ones(1,F);
P_bar_CF=ones(1,F);

N_i=zeros(1,I);
for g=1:G
    for f=1:F
        N_i(G_i==g & F_i==f)=randpl(I_sr(g,f),2,N_sr(g,f));
    end
end

Y_i=alpha_bar_i.*N_i;
Q_d_i=Y_i;
P_i=ones(1,I);
S_i=zeros(1,I);
K_i=Y_i./(omega*kappa_i);
M_i=Y_i./(omega*beta_i);

L_i=zeros(size(K_i));
pi_bar_i=1-(1+tau_SIF(F_i)).*w_bar_i./alpha_bar_i-delta_i./kappa_i-1./beta_i-tau_K_i-tau_Y_i;
D_i=zeros(size(Y_i));
for f=1:F
    L_i(F_i==f)=L_I(f).*K_i(F_i==f)/sum(K_i(F_i==f));
    D_i(F_i==f)=D_I(f).*max(0,pi_bar_i(F_i==f).*Y_i(F_i==f))/sum(max(0,pi_bar_i(F_i==f).*Y_i(F_i==f)));
end

r=r_bar+mu;
Pi_i=pi_bar_i.*Y_i-r*L_i+r_bar*max(0,D_i);

Pi_k=mu*sum(L_i)+r_bar*E_k;

H_W=sum(H_act)-I;
w_h=zeros(1,H_W);
O_h=zeros(1,H_W);
V_i=N_i;
h=1;
for i=1:I
    while V_i(i)>0
        O_h(h)=i;
        w_h(h)=w_bar_i(i);
        V_i(i)=V_i(i)-1;
        h=h+1;
    end
end

H=sum(H_act)+sum(H_inact);
F_h=zeros(1,H);
F_h(O_h~=0)=F_i(O_h(O_h~=0));

H_U=H_act-sum(I_sr)-sum(N_sr);
h=sum(sum(N_sr))+1;
for f=1:F
    F_h(h:h+H_U(f)-1)=f;
    w_h(h:h+H_U(f))=w_UB(f)/theta_UB(f);
    h=h+H_U(f);
end

h=H_W+1;
for f=1:F
    F_h(h:h+H_inact(f)-1)=f;
    h=h+H_inact(f);
end

F_h(H_W+sum(H_inact)+1:H_W+sum(H_inact)+I)=F_i;

Y_h=zeros(1,H);
for h=1:H
    if h<=H_W
        if O_h(h)~=0
            Y_h(h)=(w_h(h)*(1-tau_SIW(F_h(h))-tau_INC(F_h(h))*(1-tau_SIW(F_h(h))))+sb_other(F_h(h)))*P_bar_HH(F_h(h));
        else
            Y_h(h)=(theta_UB(F_h(h))*w_h(h)+sb_other(F_h(h)))*P_bar_HH(F_h(h));
        end
    elseif h>H_W && h<=H_W+sum(H_inact)
        Y_h(h)=(sb_inact(F_h(h))+sb_other(F_h(h)))*P_bar_HH(F_h(h));
    elseif h>H_W+sum(H_inact) && h<=H_W+sum(H_inact)+I
        i=h-(H_W+sum(H_inact));
        Y_h(h)=theta_DIV(F_h(h))*(1-tau_INC(F_h(h)))*(1-tau_FIRM(F_h(h)))*max(0,Pi_i(i))+sb_other(F_h(h))*P_bar_HH(F_h(h));
    % elseif h>H_W+sum(H_inact)+I && h<=H
        % Y_h(h)=theta_DIV*(1-tau_INC)*(1-tau_FIRM)*max(0,Pi_k)+sb_other*P_bar_HH(F_h(h));
    end
end

D_h=zeros(size(Y_h));
K_h=zeros(size(Y_h));
for f=1:F
    D_h(F_h==f)=D_H(f)*Y_h(F_h==f)/sum(Y_h(F_h==f));
    K_h(F_h==f)=K_H(f)*Y_h(F_h==f)/sum(Y_h(F_h==f));
end

D_k=sum(D_i)+sum(D_h)+E_k-sum(L_i);

% G_m=1:G;
% G_m=reshape(((1:G)'.*ones(G,round(L/G)))',1,round(L/G)*G);
% Y_m=zeros(size(G_m));
% for g=1:G
%     Y_m(G_m==g)=c_I_g(g)*Y_I(T_prime)/sum(G_m==g);
% end

I_ms=max(1,round(nansum(I_sr,2)./nansum(alpha_sr.*N_sr,2).*c_I_g*Y_I(T_prime)));
N_ms=max(1,round(nansum(N_sr,2)./nansum(alpha_sr.*N_sr,2).*c_I_g*Y_I(T_prime)));

M=sum(I_ms);
G_m=zeros(1,M);
for g=1:G
    i=sum(I_ms(1:g-1));
    j=I_ms(g);
    G_m(i+1:i+j)=g;
end
N_m=zeros(1,M);
Y_m=zeros(1,M);
for g=1:G
    N_m(G_m==g)=randpl(I_ms(g),2,N_ms(g));
    Y_m(G_m==g)=N_m(G_m==g)*c_I_g(g)*Y_I(T_prime)/sum(N_m(G_m==g));
end
P_m=ones(size(Y_m));

C_d_j=P_G(T_prime,:).*C_G(T_prime,:);

C_d_l=P_E(T_prime)*C_E(T_prime)/L*ones(1,L);

[~,~,~,~,~,~,~,~,~,~,~,~,~,~,bilateral_trade_g,bilateral_trade_real_g]=search_and_matching(P_i,Y_i,S_i,K_i.*kappa_i,G_i,P_m,Y_m,Y_m,G_m,a_sg,Y_i./beta_i,b_CF_g,Y_i.*delta_i./kappa_i,b_HH_g,psi(F_h).*Y_h./(1+tau_VAT(F_h)),b_CFH_g,zeros(size(Y_h)),c_G_g,C_d_j,c_E_g,C_d_l,F,F_i,F_h,s_a_ffsg,s_CF_ffg,s_CFH_ffg,s_HH_ffg,s_G_ffg,s_E_fg);

bilateral_trade=sum(bilateral_trade_g,3);
bilateral_trade_real=sum(bilateral_trade_real_g,3);
D=diag(diag(bilateral_trade));
nom_imports=sum(bilateral_trade-D,2);
nom_exports=sum(bilateral_trade-D,1);
D=diag(diag(bilateral_trade_real));
rea_imports=sum(bilateral_trade_real-D,2);
rea_exports=sum(bilateral_trade_real-D,1);

nominal_gdp=zeros(T+1,F);
real_gdp=zeros(T+1,F);
nominal_gva=zeros(T+1,F);
real_gva=zeros(T+1,F);
nominal_household_consumption=zeros(T+1,F);
real_household_consumption=zeros(T+1,F);
nominal_government_consumption=zeros(T+1,F);
real_government_consumption=zeros(T+1,F);
nominal_capitalformation=zeros(T+1,F);
real_capitalformation=zeros(T+1,F);
nominal_fixed_capitalformation=zeros(T+1,F);
real_fixed_capitalformation=zeros(T+1,F);
nominal_fixed_capitalformation_dwellings=zeros(T+1,F);
real_fixed_capitalformation_dwellings=zeros(T+1,F);
nominal_exports=zeros(T+1,F);
real_exports=zeros(T+1,F);
nominal_imports=zeros(T+1,F);
real_imports=zeros(T+1,F);
operating_surplus=zeros(T+1,F);
capital_consumption=zeros(T+1,F);
compensation_employees=zeros(T+1,F);
wages=zeros(T+1,F);
taxes_production=zeros(T+1,F);
nominal_sector_gva=zeros(T+1,F,G);
real_sector_gva=zeros(T+1,F,G);
sector_operating_surplus=zeros(T+1,F,G);
sector_capital_consumption=zeros(T+1,F,G);
nominal_output=zeros(T+1,F);
real_output=zeros(T+1,F);
nominal_sector_output=zeros(T+1,F,G);
real_sector_output=zeros(T+1,F,G);
government_debt=zeros(T+1,F);
government_deficit=zeros(T+1,F);
unemployment_rate=zeros(T+1,F);
euribor=zeros(1,T+1);

for f=1:F
    nominal_gdp(1,f)=sum(Y_i(F_i==f).*(1-1./beta_i(F_i==f)))+sum(Y_h(F_h==f).*psi(f)./(1./tau_VAT(f)+1))+sum(Y_h(F_h==f).*psi_H(f)./(1./tau_CF(f)+1))+tau_G(f)*C_G(T_prime,f);% +tau_EXPORT(f)*C_E(T_prime,f);
    real_gdp(1,f)=nominal_gdp(1,f);
    nominal_gva(1,f)=sum(Y_i(F_i==f).*((1-tau_Y_i(F_i==f))-1./beta_i(F_i==f)));
    real_gva(1,f)=nominal_gva(1,f);
    nominal_household_consumption(1,f)=sum(Y_h(F_h==f).*psi(f));
    real_household_consumption(1,f)=nominal_household_consumption(1,f);
    nominal_government_consumption(1,f)=(1+tau_G(f))*C_G(T_prime,f);
    real_government_consumption(1,f)=nominal_government_consumption(1,f);
    nominal_capitalformation(1,f)=sum(Y_i(F_i==f).*delta_i(F_i==f)./kappa_i(F_i==f))+sum(Y_h(F_h==f).*psi_H(f));
    real_capitalformation(1,f)=nominal_capitalformation(1,f);
    nominal_fixed_capitalformation(1,f)=nominal_capitalformation(1,f);
    real_fixed_capitalformation(1,f)=nominal_capitalformation(1,f);
    nominal_fixed_capitalformation_dwellings(1,f)=sum(Y_h(F_h==f).*psi_H(f));
    real_fixed_capitalformation_dwellings(1,f)=nominal_fixed_capitalformation_dwellings(1,f);
    nominal_intermediate_consumption(1,f)=sum(Y_i(F_i==f)./beta_i(F_i==f));
    
    for g=1:G
        imported_nominal_sector_intermediate_consumption(1,f,g)=sum(sum(squeeze(s_a_ffsg([1:f-1,f+1:end],f,:,g)).*a_sg(:,g,f)'))*sum(Y_i(F_i==f&G_i==g)./beta_i(F_i==f&G_i==g));
    end
    
    % nominal_imports(1,f)=sum(imported_nominal_sector_intermediate_consumption(1,f,:))+sum(sum(squeeze(s_HH_ffg([1:f-1,f+1:end],f,:)).*b_HH_g(:,f)'))*nominal_household_consumption(1,f)/(1+tau_VAT(f))+sum(sum(squeeze(s_G_ffg([1:f-1,f+1:end],f,:)).*c_G_g(:,f)'))*nominal_government_consumption(1,f)/(1+tau_G(f))+sum(sum(squeeze(s_CF_ffg([1:f-1,f+1:end],f,:)).*b_CF_g(:,f)'))*(nominal_fixed_capitalformation(1,f)-nominal_fixed_capitalformation_dwellings(1,f))+sum(sum(squeeze(s_CFH_ffg([1:f-1,f+1:end],f,:)).*b_CFH_g(:,f)'))*nominal_fixed_capitalformation_dwellings(1,f)/(1+tau_CF(f));
    % real_imports(1,f)=nominal_imports(1,f);
    % nominal_exports(1,f)=(1+tau_EXPORT(f))*C_E(T_prime,f);
    % nominal_exports(1,f)=nominal_gdp(1,f)+nominal_imports(1,f)-nominal_household_consumption(1,f)-nominal_government_consumption(1,f)-nominal_capitalformation(1,f);
    % real_exports(1,f)=nominal_exports(1,f);
    operating_surplus(1,f)=sum(Y_i(F_i==f).*(1-((1+tau_SIF(f)).*w_bar_i(F_i==f)./alpha_bar_i(F_i==f)+1./beta_i(F_i==f)))-tau_K_i(F_i==f).*Y_i(F_i==f)-tau_Y_i(F_i==f).*Y_i(F_i==f));
    capital_consumption(1,f)=sum(Y_i(F_i==f).*delta_i(F_i==f)./kappa_i(F_i==f));
    compensation_employees(1,f)=sum((1+tau_SIF(f)).*w_bar_i(F_i==f).*N_i(F_i==f));
    wages(1,f)=sum(w_bar_i(F_i==f).*N_i(F_i==f));
    taxes_production(1,f)=sum(tau_K_i(F_i==f).*Y_i(F_i==f));
    
    for g=1:G
        nominal_sector_gva(1,f,g)=sum(Y_i(F_i==f&G_i==g).*((1-tau_Y_i(F_i==f&G_i==g))-1./beta_i(F_i==f&G_i==g)));
        sector_operating_surplus(1,f,g)=sum(Y_i(F_i==f&G_i==g).*(1-((1+tau_SIF(F_i(F_i==f&G_i==g))).*w_bar_i(F_i==f&G_i==g)./alpha_bar_i(F_i==f&G_i==g)+1./beta_i(F_i==f&G_i==g)))-tau_K_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g)-tau_Y_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g));
        sector_capital_consumption(1,f,g)=sum(Y_i(F_i==f&G_i==g).*delta_i(F_i==f&G_i==g)./kappa_i(F_i==f&G_i==g));
        nominal_sector_output(1,f,g)=sum(Y_i(F_i==f&G_i==g));
    end
    
    real_sector_gva(1,f,:)=nominal_sector_gva(1,f,:);
    nominal_output(1,f)=sum(Y_i(F_i==f));
    real_output(1,f)=nominal_output(1,f);
    real_sector_output(1,f,:)=nominal_sector_output(1,f,:);
    
    government_debt(1,f)=L_G(f);
    government_deficit(1,f)=0;
    unemployment_rate(1,f)=sum(O_h==0&F_h(1:H_W)==f)/(H_act(f)-sum(I_sr(:,f)));
end

nominal_imports(1,:)=nom_imports(1:end-1);
real_imports(1,:)=nominal_imports(1,:);
nominal_exports(1,:)=nom_exports(1:end-1);
real_exports(1,:)=nominal_exports(1,:);

euribor(1)=r_bar;

gamma_X_i=zeros(T,I);
gamma_X_I=zeros(T,G);
if scenario
    for i=1:I
        gamma_X_i(:,i)=shock.gamma_X_gr(:,G_i(i),F_i(i));
    end
    gamma_X_I=shock.gamma_X_I;
end

for t=1:T
    [epsilon_]=epsilon(C);
    epsilon_gamma_G=epsilon_(1:F);
    epsilon_pi_G=epsilon_(F+1:2*F);
    epsilon_gamma_E=epsilon_(2*F+1);
    epsilon_pi_E=epsilon_(2*F+2);
    epsilon_gamma_I=epsilon_(2*F+3);
    epsilon_pi_I=epsilon_(2*F+4);
    % epsilon_gamma_G=0;
    % epsilon_pi_G=0;
    % epsilon_gamma_E=0;
    % epsilon_pi_E=0;
    % epsilon_gamma_I=0;
    % epsilon_pi_I=0;
    
    % C_G(T_prime+t,:)=exp(alpha_C_G*log(C_G(T_prime+t-1,:))+beta_C_G);
    gamma_G(T_prime+t,:)=alpha_gamma_G.*gamma_G(T_prime+t-1,:)+beta_gamma_G+epsilon_gamma_G;
    C_G(T_prime+t,:)=C_G(T_prime+t-1,:).*exp(gamma_G(T_prime+t,:));
    pi_G(T_prime+t,:)=alpha_pi_G.*pi_G(T_prime+t-1,:)+beta_pi_G+epsilon_pi_G;
    P_G(T_prime+t,:)=P_G(T_prime+t-1,:).*exp(pi_G(T_prime+t,:));
    
    % C_E(T_prime+t)=exp(alpha_C_E*log(C_E(T_prime+t-1))+beta_C_E);
    gamma_E(T_prime+t)=alpha_gamma_E*gamma_E(T_prime+t-1)+beta_gamma_E+epsilon_gamma_E;
    C_E(T_prime+t)=C_E(T_prime+t-1)*exp(gamma_E(T_prime+t));
    pi_E(T_prime+t)=alpha_pi_E*pi_E(T_prime+t-1)+beta_pi_E+epsilon_pi_E;
    P_E(T_prime+t)=P_E(T_prime+t-1)*exp(pi_E(T_prime+t));
    
    % Y_I(T_prime+t)=exp(alpha_Y_I*log(Y_I(T_prime+t-1))+beta_Y_I);
    gamma_I(T_prime+t)=alpha_gamma_I*gamma_I(T_prime+t-1)+beta_gamma_I+epsilon_gamma_I;
    Y_I(T_prime+t)=Y_I(T_prime+t-1)*exp(gamma_I(T_prime+t));
    pi_I(T_prime+t)=alpha_pi_I*pi_I(T_prime+t-1)+beta_pi_I+epsilon_pi_I;
    P_I(T_prime+t)=P_I(T_prime+t-1)*exp(pi_I(T_prime+t));
end

[nominal_gdp(2:T+1,:),real_gdp(2:T+1,:),nominal_gva(2:T+1,:),real_gva(2:T+1,:),nominal_household_consumption(2:T+1,:),real_household_consumption(2:T+1,:),nominal_government_consumption(2:T+1,:),real_government_consumption(2:T+1,:),nominal_capitalformation(2:T+1,:),real_capitalformation(2:T+1,:),nominal_fixed_capitalformation(2:T+1,:),real_fixed_capitalformation(2:T+1,:),nominal_fixed_capitalformation_dwellings(2:T+1,:),real_fixed_capitalformation_dwellings(2:T+1,:),nominal_exports(2:T+1,:),real_exports(2:T+1,:),nominal_imports(2:T+1,:),real_imports(2:T+1,:),operating_surplus(2:T+1,:),capital_consumption(2:T+1,:),compensation_employees(2:T+1,:),wages(2:T+1,:),taxes_production(2:T+1,:),nominal_sector_gva(2:T+1,:,:),real_sector_gva(2:T+1,:,:),sector_operating_surplus(2:T+1,:,:),sector_capital_consumption(2:T+1,:,:),nominal_output(2:T+1,:),real_output(2:T+1,:),nominal_sector_output(2:T+1,:,:),real_sector_output(2:T+1,:,:),government_debt(2:T+1,:),government_deficit(2:T+1,:),unemployment_rate(2:T+1,:),euribor(2:T+1),E_CB,D_RoW,L_G,D_k,D_i,D_h,E_k,L_i]=abm(G,H_act,H_inact,J,L,tau_INC,tau_FIRM,tau_VAT,tau_SIF,tau_SIW,tau_EXPORT,tau_CF,tau_G,theta_UB,psi,psi_H,theta_DIV,theta,mu,r_G,zeta,zeta_LTV,zeta_b,alpha_bar_i,beta_i,kappa_i,delta_i,w_bar_i,tau_Y_i,tau_K_i,b_CF_g,b_CFH_g,b_HH_g,c_G_g,c_E_g,c_I_g,a_sg,G_i,T,T_prime,T_max,P_i,K_i,M_i,S_i,N_i,D_i,L_i,D_h,w_h,K_h,L_G,E_k,E_CB,D_RoW,O_h,sb_inact,sb_other,Y,gamma,pi,P,Y_f,gamma_f,pi_f,P_f,r_bar,C_G,pi_G,P_G,gamma_G,C_E,pi_E,P_E,gamma_E,Y_I,pi_I,P_I,gamma_I,P_bar_g,P_bar_HH,P_bar_CF,Q_d_i,Pi_i,Pi_k,D_k,gamma_X_i,gamma_X_I,F,F_i,F_h,s_a_ffsg,s_CF_ffg,s_CFH_ffg,s_HH_ffg,s_G_ffg,s_E_fg,P_m,Y_m,G_m);

end
