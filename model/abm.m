function [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,capital_consumption,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,sector_operating_surplus,sector_capital_consumption,nominal_output,real_output,nominal_sector_output,real_sector_output,government_debt,government_deficit,unemployment_rate,euribor,E_CB,D_RoW,L_G,D_k,D_i,D_h,E_k,L_i,dyn_bilateral_trade_g,dyn_bilateral_trade_real_g,capital_stock_dynamics,capital_loss,sector_capital_loss,firms_damaged,loan_issuance,credit_constrained_pct,total_firms_demanding,credit_gap,credit_gap_to_gdp]=abm(G,H_act,H_inact,J,L,tau_INC,tau_FIRM,tau_VAT,tau_SIF,tau_SIW,tau_EXPORT,tau_CF,tau_G,theta_UB,psi,psi_H,theta_DIV,theta,mu,r_G,zeta,zeta_LTV,zeta_b,alpha_bar_i,beta_i,kappa_i,delta_i,w_bar_i,tau_Y_i,tau_K_i,b_CF_g,b_CFH_g,b_HH_g,c_G_g,c_E_g,c_I_g,a_sg,G_i,T,T_prime,T_max,P_i,K_i,M_i,S_i,N_i,D_i,L_i,D_h,w_h,K_h,L_G,E_k,E_CB,D_RoW,O_h,sb_inact,sb_other,Y,gamma,pi,P,Y_f,gamma_f,pi_f,P_f,r_bar,C_G,pi_G,P_G,gamma_G,C_E,pi_E,P_E,gamma_E,Y_I,pi_I,P_I,gamma_I,P_bar_g,P_bar_HH,P_bar_CF,Q_d_i,Pi_i,Pi_k,D_k,gamma_K_gr,gamma_X_i,gamma_X_I,F,F_i,F_h,s_a_ffsg,s_CF_ffg,s_CFH_ffg,s_HH_ffg,s_G_ffg,s_E_fg,P_m,Y_m,G_m,scenario,credit_constraints)
nominal_gdp=zeros(T,F);
real_gdp=zeros(T,F);
nominal_gva=zeros(T,F);
real_gva=zeros(T,F);
nominal_household_consumption=zeros(T,F);
real_household_consumption=zeros(T,F);
nominal_government_consumption=zeros(T,F);
real_government_consumption=zeros(T,F);
nominal_capitalformation=zeros(T,F);
real_capitalformation=zeros(T,F);
nominal_fixed_capitalformation=zeros(T,F);
real_fixed_capitalformation=zeros(T,F);
nominal_fixed_capitalformation_dwellings=zeros(T,F);
real_fixed_capitalformation_dwellings=zeros(T,F);
nominal_exports=zeros(T,F);
real_exports=zeros(T,F);
nominal_imports=zeros(T,F);
real_imports=zeros(T,F);
operating_surplus=zeros(T,F);
capital_consumption=zeros(T,F);
compensation_employees=zeros(T,F);
wages=zeros(T,F);
taxes_production=zeros(T,F);
nominal_sector_gva=zeros(T,F,G);
real_sector_gva=zeros(T,F,G);
sector_operating_surplus=zeros(T,F,G);
sector_capital_consumption=zeros(T,F,G);
nominal_output=zeros(T,F);
real_output=zeros(T,F);
nominal_sector_output=zeros(T,F,G);
real_sector_output=zeros(T,F,G);
government_debt=zeros(T,F);
government_deficit=zeros(T,F);
unemployment_rate=zeros(T,F);
euribor=zeros(1,T);
dyn_bilateral_trade=zeros(T,F+1,F+1);
dyn_bilateral_trade_real=zeros(T,F+1,F+1);
dyn_bilateral_trade_g=zeros(T,F+1,F+1,G);
dyn_bilateral_trade_real_g=zeros(T,F+1,F+1,G);

capital_stock_dynamics = zeros(T, F, G);
capital_loss = zeros(T, F);
sector_capital_loss = zeros(T, F, G);
firms_damaged = zeros(T, F, G);
loan_issuance = zeros(T, F);
credit_constrained_pct = zeros(T, F, G);
total_firms_demanding = zeros(T, F, G);
credit_gap = zeros(T, F);
credit_gap_to_gdp = zeros(T, F);

% The total number of firms
I = length(F_i);

% Save pre-shock capital for reconstruction reference
K_i_ = K_i;

AC_e_i=(1+tau_SIF(F_i)).*w_bar_i./alpha_bar_i+delta_i./kappa_i+1./beta_i;
mu_i=1./AC_e_i-1;
P_bar_HH_DM=ones(F,G);

for t=1:T
%     [alpha_Y,beta_Y,u_Y]=estimate(log(Y(1:T_prime+t-1)));
%     epsilon_Y=normrnd(0,sqrt(cov(u_Y)));
%     % epsilon_Y=0;
%     Y_e=exp(alpha_Y*log(Y(T_prime+t-1))+beta_Y+epsilon_Y);
%     gamma_e=Y_e/Y(T_prime+t-1)-1;
%     gamma_e_f=gamma_e*ones(1,F);
%     
%     [alpha_pi,beta_pi,u_pi]=estimate(pi(1:T_prime+t-1));
%     epsilon_pi=normrnd(0,sqrt(cov(u_pi)));
%     % epsilon_pi=0;
%     pi_e=exp(alpha_pi*pi(T_prime+t-1)+beta_pi+epsilon_pi)-1;
%     pi_e_f=pi_e*ones(1,F);
%     
%     if any(abs(alpha_Y)>1) || any(abs(alpha_pi)>1)
%         break;
%     end
    
    % u_Y=[];
    u_gamma=[];
    u_pi=[];
    for f=1:F
        % [alpha_Y(f),beta_Y(f),u_Y(:,f)]=estimate(log(Y_f(1:T_prime+t-1,f)));
        [alpha_gamma(f),beta_gamma(f),u_gamma(:,f)]=estimate(gamma_f(1:T_prime+t-1,f));
        [alpha_pi(f),beta_pi(f),u_pi(:,f)]=estimate(pi_f(1:T_prime+t-1,f));
        % epsilon_gamma(f)=normrnd(0,sqrt(cov(u_gamma(:,f))));
        % epsilon_pi(f)=normrnd(0,sqrt(cov(u_pi(:,f))));
    end
    
    if any(abs(alpha_gamma)>1) || any(abs(alpha_pi)>1)
        break;
    end
    
    [epsilon_]=epsilon(cov([u_gamma,u_pi]));

    if any(isnan(epsilon_(:)))
        warning('Breaking loop due to non-positive definite covariance matrix');
        break;
    end

    % epsilon_Y=0;
    epsilon_gamma=epsilon_(1:F);
    % epsilon_gamma=0;
    epsilon_pi=epsilon_(F+1:2*F);
    % epsilon_pi=0;
    % Y_e=exp(alpha_Y.*log(Y_f(T_prime+t-1,:))+beta_Y+epsilon_Y);
    % gamma_e_f=Y_e./Y_f(T_prime+t-1,:)-1;
    gamma_e_f=exp(alpha_gamma.*gamma_f(T_prime+t-1,:)+beta_gamma+epsilon_gamma)-1;
    pi_e_f=exp(alpha_pi.*pi_f(T_prime+t-1,:)+beta_pi+epsilon_pi)-1;
    
    % r_bar=rho*r_bar+(1-rho)*(r_star+pi_star+xi_pi*(pi_EA-pi_star)+xi_gamma*gamma_EA);
    r=r_bar+mu;
    
    Q_s_i=Q_d_i.*(1+gamma_X_i(t,:)).*(1+gamma_e_f(F_i));

    % Capital destruction shock
    if ~strcmp(scenario, 'S0') && sum(gamma_K_gr(:)) < 0
        sector_country_weights = abs(squeeze(gamma_K_gr(t, :, :)));
    else
        sector_country_weights = zeros(F, G);
    end

    X_i = zeros(1, I);
    for f = 1:F
        for g = 1:G
            inds = find(F_i == f & G_i == g);
            if isempty(inds), continue; end
            shuffled_inds = inds(randperm(numel(inds)));
            totalK = sum(K_i(inds));
            industry_loss = P_bar_CF(f) * sector_country_weights(f, g) * totalK;
            potential_losses = K_i(shuffled_inds) * P_bar_CF(f);
            cumsum_losses = cumsum(potential_losses);
            break_idx = find(cumsum_losses >= industry_loss, 1);
            if isempty(break_idx)
                X_i(shuffled_inds) = potential_losses;
            else
                if break_idx > 1
                    X_i(shuffled_inds(1:break_idx-1)) = potential_losses(1:break_idx-1);
                end
                X_i(shuffled_inds(break_idx)) = industry_loss - sum(potential_losses(1:break_idx-1));
            end
        end
    end
    K_i = K_i - X_i;

    % pi_c_i=(1+tau_SIF(F_i)).*w_bar_i./alpha_bar_i.*(P_bar_HH./P_i-1)+1./beta_i.*(sum(a_sg(:,G_i).*P_bar_g)./P_i-1)+delta_i./kappa_i.*(P_bar_CF./P_i-1);
    I=length(G_i);
    % pi_c_i=zeros(1,I);
    for i=1:I
        % pi_c_i(i)=(1+tau_SIF(F_i(i)))*w_bar_i(i)/alpha_bar_i(i)*(P_bar_HH(F_i(i))/P_i(i)-1)+1/beta_i(i)*(sum(a_sg(:,G_i(i),F_i(i)).*P_bar_g)/P_i(i)-1)+delta_i(i)/kappa_i(i)*(P_bar_CF(F_i(i))/P_i(i)-1);
        % pi_c_i(i)=(1+tau_SIF(F_i(i)))*w_bar_i(i)/alpha_bar_i(i)*(P_bar_HH(F_i(i))/P_i(i)-1)+1/beta_i(i)*(sum(P_bar_i(F_i==F_i(i)&G_i==G_i(i)).*DM_i(F_i==F_i(i)&G_i==G_i(i)))/sum(DM_i(F_i==F_i(i)&G_i==G_i(i)))/P_i(i)-1)+delta_i(i)/kappa_i(i)*(P_bar_CF(F_i(i))/P_i(i)-1);
        % pi_c_i(i)=(1+tau_SIF(F_i(i)))*w_bar_i(i)/alpha_bar_i(i)*(P_bar_HH(F_i(i))/P_i(i)-1)+1/beta_i(i)*(sum(P_bar_i(F_i==F_i(i)).*DM_i(F_i==F_i(i)))/sum(DM_i(F_i==F_i(i)))/P_i(i)-1)+delta_i(i)/kappa_i(i)*(P_bar_CF(F_i(i))/P_i(i)-1);
        AC_e_i(i)=((1+tau_SIF(F_i(i)))*w_bar_i(i)/alpha_bar_i(i)*P_bar_HH(F_i(i))+1/beta_i(i)*P_bar_HH_DM(F_i(i),G_i(i))+delta_i(i)/kappa_i(i)*P_bar_CF(F_i(i)))*(1+pi_e_f(F_i(i)));
    end
    
    % P_i=P_i.*(1+pi_c_i).*(1+pi_e_f(F_i));
    P_i=(1+mu_i).*AC_e_i;

    DM_d_i=min(Q_s_i,K_i.*kappa_i)./beta_i;
    
    N_d_i=max(1,round(min(Q_s_i,K_i.*kappa_i)./alpha_bar_i));
    
    Pi_e_i=Pi_i.*(1+pi_e_f(F_i)).*(1+gamma_e_f(F_i));
    DD_e_i=Pi_e_i-theta*L_i-tau_FIRM(F_i).*max(0,Pi_e_i)-(theta_DIV(F_i).*(1-tau_FIRM(F_i))).*max(0,Pi_e_i)+(K_i_-K_i).*P_bar_CF(F_i).*(1+pi_e_f(F_i));
    DL_d_i=max(0,-DD_e_i-D_i);

    K_e_i=P_bar_CF(F_i).*(1+pi_e_f(F_i)).*K_i;
    L_e_i=(1-theta)*L_i;
    DL_i=search_and_matching_credit(DL_d_i,K_e_i,L_e_i,E_k,zeta,zeta_LTV);

    if ~strcmp(scenario, 'S0') && (credit_constraints > 0)
        if credit_constraints == 2
            DL_i(:) = 0;
        else
            for i = 1:I
                if X_i(i) > 0
                    DL_i(i) = 0;
                end
            end
        end
        I_d_i = max(0, delta_i./kappa_i.*min(Q_s_i,K_i.*kappa_i) + max(0, (K_i_-K_i) - max(0, (DL_d_i-DL_i))./(P_bar_CF(F_i).*(1+pi_e_f(F_i)))));
    else
        I_d_i = max(0, delta_i./kappa_i.*min(Q_s_i,K_i.*kappa_i) + (K_i_-K_i));
    end

    V_i=N_d_i-N_i;
    [N_i,O_h]=search_and_matching_labor(N_i,V_i,O_h);
    
    % Y_m=c_I_g'*Y_I(T_prime+t).*(1+gamma_X_I(t,:));
    Y_m=Y_m*exp(gamma_I(T_prime+t));
    % P_m=P_bar_g'*(1+pi_e);
    % P_m=ones(1,G)*P_I(T_prime+t);
    P_m=P_m*exp(pi_I(T_prime+t));

    % Y_i=min(Q_s_i,min(N_i*1.5.*alpha_bar_i,min(K_i.*kappa_i,M_i.*beta_i)));
    Y_i=production_function(Q_s_i,alpha_bar_i,N_i,kappa_i,K_i,a_sg,beta_i,G_i,F_i,Y_m,G_m);
    
    w_i=w_bar_i.*Y_i./(N_i.*alpha_bar_i);
    
    H_W=sum(H_act)-I;
    for h=1:H_W
       i=O_h(h);
       if i~=0
          w_h(h)=w_i(i);
          if F_h(h)~=F_i(i)
            H_act(F_h(h))=H_act(F_h(h))-1;
            H_act(F_i(i))=H_act(F_i(i))+1;
            F_h(h)=F_i(i);
          end
       end
    end
    
    % sb_other=sb_other*(1+gamma_e);
    % sb_inact=sb_inact*(1+gamma_e);
    
    % Pi_e_k=Pi_k*(1+pi_e)*(1+gamma_e);
    
    H=sum(H_act)+sum(H_inact);
    Y_e_h=zeros(1,H);
    for h=1:H
        if h<=H_W
            if O_h(h)~=0
                Y_e_h(h)=(w_h(h)*(1-tau_SIW(F_h(h))-tau_INC(F_h(h))*(1-tau_SIW(F_h(h))))+sb_other(F_h(h)))*P_bar_HH(F_h(h))*(1+pi_e_f(F_h(h)));
            else
                Y_e_h(h)=(theta_UB(F_h(h))*w_h(h)+sb_other(F_h(h)))*P_bar_HH(F_h(h))*(1+pi_e_f(F_h(h)));
            end
        elseif h>H_W && h<=H_W+sum(H_inact)
            Y_e_h(h)=(sb_inact(F_h(h))+sb_other(F_h(h)))*P_bar_HH(F_h(h))*(1+pi_e_f(F_h(h)));
        elseif h>H_W+sum(H_inact) && h<=H_W+sum(H_inact)+I
            i=h-(H_W+sum(H_inact));
            Y_e_h(h)=theta_DIV(F_h(h))*(1-tau_INC(F_h(h)))*(1-tau_FIRM(F_h(h)))*max(0,Pi_e_i(i))+sb_other(F_h(h))*P_bar_HH(F_h(h))*(1+pi_e_f(F_h(h)));
        % elseif h>H_W+sum(H_inact)+I && h<=H
            % Y_e_h(h)=theta_DIV(F_h(h))*(1-tau_INC(F_h(h)))*(1-tau_FIRM(F_h(h)))*max(0,Pi_e_k)+sb_other(F_h(h))*P_bar_HH(F_h(h))*(1+pi_e_f(F_h(h)));
        end
    end
    
    C_d_h=psi(F_h).*Y_e_h./(1+tau_VAT(F_h));
    I_d_h=psi_H(F_h).*Y_e_h./(1+tau_CF(F_h));
    
    C_d_j=P_G(T_prime+t,:).*C_G(T_prime+t,:);
    
    C_d_l=P_E(T_prime+t)*C_E(T_prime+t)/L*ones(1,L);
    
    s_HH_ffg_=s_HH_ffg.*psi./(psi+psi_H)+s_CFH_ffg.*psi_H./(psi+psi_H);
    [Q_d_i,Q_d_m,P_bar_i,DM_i,P_CF_i,I_i,P_bar_h,C_h,P_bar_CF_h,I_h,P_j,C_j,P_l,C_l,bilateral_trade_g,bilateral_trade_real_g]=search_and_matching(P_i,Y_i,S_i,max(0,max(Y_i./(1+gamma_X_i(t,:)),K_i.*kappa_i)-Y_i),G_i,P_m,Y_m,Y_m,G_m,a_sg,DM_d_i,b_CF_g,I_d_i,b_HH_g,C_d_h,b_CFH_g,I_d_h,c_G_g,C_d_j,c_E_g,C_d_l,F,F_i,F_h,s_a_ffsg,s_CF_ffg,s_CFH_ffg,s_HH_ffg_,s_G_ffg,s_E_fg);
    P_bar_CF_h=fillmissing(P_bar_CF_h,'constant',1);
    
    Q_i=min(Y_i+S_i,Q_d_i);
    Q_m=min(Y_m,Q_d_m);
    
    K_h=K_h+I_h;
    
    pi(T_prime+t)=log(sum(P_i.*Y_i)/sum(Y_i)/P(T_prime+t-1));
    P(T_prime+t)=sum(P_i.*Y_i)/sum(Y_i);
    
    % for f=1:F
    %     pi_f(T_prime+t,f)=log(sum(P_i(F_i==f).*Y_i(F_i==f))/sum(Y_i(F_i==f))/P_f(T_prime+t-1,f));
    %     P_f(T_prime+t,f)=sum(P_i(F_i==f).*Y_i(F_i==f))/sum(Y_i(F_i==f));
    % end
    
    for f=1:F
        pi_f(T_prime+t,f)=log(sum(C_h(F_h==f))/sum(C_h(F_h==f)./P_bar_h(F_h==f))/P_f(T_prime+t-1,f));
        P_f(T_prime+t,f)=sum(C_h(F_h==f))/sum(C_h(F_h==f)./P_bar_h(F_h==f));
    end
    
    % for g=1:G
    %     if sum(Q_i(G_i==g))+Q_m(g)>0
    %         P_bar_g(g)=(sum(P_i(G_i==g).*Q_i(G_i==g))+P_m(g)*Q_m(g))/(sum(Q_i(G_i==g))+Q_m(g));
    %     end
    % end
    
    % P_bar_CF=sum(b_CF_g.*P_bar_g);
    % P_bar_HH=sum(b_HH_g.*P_bar_g);
    for f=1:F
        P_bar_CF(f)=sum(P_CF_i(F_i==f).*I_i(F_i==f))/sum(I_i(F_i==f));
        P_bar_HH(f)=sum(C_h(F_h==f))/sum(C_h(F_h==f)./P_bar_h(F_h==f));
        % P_bar_HH_DM(f)=sum(P_bar_i(F_i==f).*DM_i(F_i==f))/sum(DM_i(F_i==f));
        for g=1:G
            if sum(DM_i(F_i==f&G_i==g))>0
                P_bar_HH_DM(f,g)=sum(P_bar_i(F_i==f&G_i==g).*DM_i(F_i==f&G_i==g))/sum(DM_i(F_i==f&G_i==g));
            end
        end
    end
    
    K_i=K_i-delta_i./kappa_i.*Y_i+I_i;
    
    M_i=M_i-Y_i./beta_i+DM_i;
	
    DS_i=Y_i-Q_i;
    S_i=S_i+DS_i;
    
    Pi_i=P_i.*Q_i+P_i.*DS_i-(1+tau_SIF(F_i)).*w_i.*N_i.*P_bar_HH(F_i)-1./beta_i.*P_bar_i.*Y_i-delta_i./kappa_i.*P_CF_i.*Y_i-tau_Y_i.*P_i.*Y_i-tau_K_i.*P_i.*Y_i-r*(L_i+max(0,-D_i))+r_bar*max(0,D_i);
    
    Pi_k=r*sum(L_i+max(0,-D_i))+r*sum(max(0,-D_h))+r_bar*max(0,D_k)-r_bar*sum(max(0,D_i))-r_bar*sum(max(0,D_h))-r_bar*max(0,-D_k);
    
    E_k=E_k+Pi_k; %-theta_DIV*(1-tau_FIRM)*max(0,Pi_k)-tau_FIRM*max(0,Pi_k);
    
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
            % Y_h(h)=theta_DIV(F_h(h))*(1-tau_INC(F_h(h)))*(1-tau_FIRM(F_h(h)))*max(0,Pi_k)+sb_other(F_h(h))*P_bar_HH(F_h(h));
        end
    end
    
    D_h=D_h+Y_h-(1+tau_VAT(F_h)).*C_h-(1+tau_CF(F_h)).*I_h+r_bar*max(0,D_h)-r*max(0,-D_h);
    
    pi_CB=sum(r_G.*L_G)-r_bar*D_k;
    
    Y_G=zeros(size(L_G));
    Pi_G=zeros(size(L_G));
    for f=1:F
        Y_G(f)=(tau_SIF(f)+tau_SIW(f))*sum(w_h(O_h~=0&F_h(1:H_W)==f))*P_bar_HH(f)+tau_INC(f)*(1-tau_SIW(f))*P_bar_HH(f)*sum(w_h(O_h~=0&F_h(1:H_W)==f))+tau_VAT(f)*sum(C_h(F_h==f))+tau_INC(f)*(1-tau_FIRM(f))*theta_DIV(f)*sum(max(0,Pi_i(F_i==f)))+tau_FIRM(f)*sum(max(0,Pi_i(F_i==f)))+tau_CF(f)*sum(I_h(F_h==f))+sum(tau_Y_i(F_i==f).*P_i(F_i==f).*Y_i(F_i==f))+sum(tau_K_i(F_i==f).*P_i(F_i==f).*Y_i(F_i==f)); %+tau_EXPORT*C_l +tau_INC(f)*(1-tau_FIRM(f))*theta_DIV(f)*max(0,Pi_k)+tau_FIRM(f)*max(0,Pi_k)
        Pi_G(f)=C_j(f)+r_G(f)*L_G(f)+H_inact(f)*sb_inact(f)*P_bar_HH(f)+theta_UB(f)*sum(w_h(O_h==0&F_h(1:H_W)==f))*P_bar_HH(f)+(H_act(f)+H_inact(f))*sb_other(f)*P_bar_HH(f)-Y_G(f);
    end
    
    % Y_G=sum((tau_SIF(F_h(O_h~=0))+tau_SIW(F_h(O_h~=0))).*w_h(O_h~=0))*P_bar_HH+sum(tau_INC(F_h(O_h~=0)).*(1-tau_SIW(F_h(O_h~=0))).*w_h(O_h~=0))*P_bar_HH+sum(tau_VAT(F_h).*C_h)+sum(tau_INC(F_i).*(1-tau_FIRM(F_i)).*theta_DIV(F_i).*max(0,Pi_i))+sum(tau_FIRM(F_i).*max(0,Pi_i))+sum(tau_CF(F_h).*I_h)+sum(tau_Y_i.*P_i.*Y_i)+sum(tau_K_i.*P_i.*Y_i)+sum(tau_EXPORT.*C_E/sum(C_E)*C_l);
    % Pi_G=C_j+r_G*L_G+sum(H_inact.*sb_inact)*P_bar_HH+sum(theta_UB(F_h(O_h==0)).*w_h(O_h==0))*P_bar_HH+sum((H_act+H_inact).*sb_other)*P_bar_HH-Y_G;
    L_G=L_G+Pi_G;
    
    DD_i=P_i.*Q_i-(1+tau_SIF(F_i)).*w_i.*N_i.*P_bar_HH(F_i)-DM_i.*P_bar_i-P_CF_i.*I_i-tau_Y_i.*P_i.*Y_i-tau_K_i.*P_i.*Y_i-r*(L_i+max(0,-D_i))+r_bar*max(0,D_i)+DL_i-theta*L_i-tau_FIRM(F_i).*max(0,Pi_i)-theta_DIV(F_i).*(1-tau_FIRM(F_i)).*max(0,Pi_i);
    D_i=D_i+DD_i;
    L_i=(1-theta)*L_i+DL_i;
    % E_i=D_i+M_i.*sum(a_sg(:,G_i).*P_bar_g)+P_i.*S_i+P_bar_CF(F_i).*K_i-L_i;
    for i=1:I
        E_i(i)=D_i(i)+M_i(i)*P_bar_HH_DM(F_i(i),G_i(i))+P_i(i)*S_i(i)+P_bar_CF(F_i(i))*K_i(i)-L_i(i);
    end
    
    E_CB=E_CB+pi_CB;
    D_RoW=D_RoW-(1+tau_EXPORT).*C_l+sum(P_m.*Q_m);
    D_k=sum(D_i)+sum(D_h)+E_k-sum(L_i);
    
   	Y(T_prime+t)=sum(Q_d_i);
    gamma(T_prime+t)=log(sum(Q_d_i)/Y(T_prime+t-1));
    
    for f=1:F
        Y_f(T_prime+t,f)=sum(Q_d_i(F_i==f));
        gamma_f(T_prime+t,f)=log(sum(Q_d_i(F_i==f))/Y_f(T_prime+t-1,f));
    end
    
    for g=1:G
        dyn_bilateral_trade_g(t,:,:,g)=bilateral_trade_g(:,:,g);
        dyn_bilateral_trade_real_g(t,:,:,g)=bilateral_trade_real_g(:,:,g);
    end
    bilateral_trade=sum(bilateral_trade_g,3);
    bilateral_trade_real=sum(bilateral_trade_real_g,3);
    dyn_bilateral_trade(t,:,:)=sum(bilateral_trade_g,3);
    dyn_bilateral_trade_real(t,:,:)=sum(bilateral_trade_real_g,3);
    D=diag(diag(bilateral_trade));
    nom_imports=sum(bilateral_trade-D,2);
    nom_exports=sum(bilateral_trade-D,1);
    nom_imports_RoW=sum(bilateral_trade(:,F+1)); %=sum(P_m.*Q_m)
    D=diag(diag(bilateral_trade_real));
    rea_imports=sum(bilateral_trade_real-D,2);
    rea_exports=sum(bilateral_trade_real-D,1);
    rea_imports_RoW=sum(bilateral_trade_real(:,F+1));
    
    for f=1:F
        nominal_gdp(t,f)=sum(tau_Y_i(F_i==f).*Y_i(F_i==f).*P_i(F_i==f))+sum(tau_VAT(f).*C_h(F_h==f))+sum(tau_CF(f).*I_h(F_h==f))+sum((1-tau_Y_i(F_i==f)).*P_i(F_i==f).*Y_i(F_i==f))-sum(1./beta_i(F_i==f).*P_bar_i(F_i==f).*Y_i(F_i==f))+tau_G(f)*C_j(f); %+tau_EXPORT(f)*nom_exports(f)
        real_gdp(t,f)=sum(Y_i(F_i==f).*((1-tau_Y_i(F_i==f))-1./beta_i(F_i==f)))+sum(tau_Y_i(F_i==f).*Y_i(F_i==f))+sum(tau_VAT(f).*C_h(F_h==f)./P_bar_h(F_h==f))+sum(tau_CF(f).*I_h(F_h==f)./P_bar_CF_h(F_h==f))+tau_G(f)*C_j(f)./P_j(f);%+tau_EXPORT(f)*rea_exports(f)
        nominal_gva(t,f)=sum((1-tau_Y_i(F_i==f)).*P_i(F_i==f).*Y_i(F_i==f))-sum(1./beta_i(F_i==f).*P_bar_i(F_i==f).*Y_i(F_i==f));
        real_gva(t,f)=sum(Y_i(F_i==f).*((1-tau_Y_i(F_i==f))-1./beta_i(F_i==f)));
        nominal_household_consumption(t,f)=(1+tau_VAT(f))*sum(C_h(F_h==f));
        real_household_consumption(t,f)=(1+tau_VAT(f))*sum(C_h(F_h==f)./P_bar_h(F_h==f));
        nominal_government_consumption(t,f)=(1+tau_G(f))*C_j(f);
        real_government_consumption(t,f)=(1+tau_G(f))*C_j(f)./P_j(f);
        nominal_capitalformation(t,f)=sum(P_CF_i(F_i==f).*I_i(F_i==f))+(1+tau_CF(f))*sum(I_h(F_h==f))+sum(DS_i(F_i==f).*P_i(F_i==f))+sum(DM_i(F_i==f).*P_bar_i(F_i==f)-1./beta_i(F_i==f).*P_bar_i(F_i==f).*Y_i(F_i==f));
        real_capitalformation(t,f)=sum(I_i(F_i==f))+(1+tau_CF(f))*sum(I_h(F_h==f)./P_bar_CF_h(F_h==f))+sum(DM_i(F_i==f)-Y_i(F_i==f)./beta_i(F_i==f))+sum(DS_i(F_i==f));
        nominal_fixed_capitalformation(t,f)=sum(P_CF_i(F_i==f).*I_i(F_i==f))+(1+tau_CF(f))*sum(I_h(F_h==f));
        real_fixed_capitalformation(t,f)=sum(I_i(F_i==f))+(1+tau_CF(f))*sum(I_h(F_h==f)./P_bar_CF_h(F_h==f));
        nominal_fixed_capitalformation_dwellings(t,f)=(1+tau_CF(f))*sum(I_h(F_h==f));
        real_fixed_capitalformation_dwellings(t,f)=(1+tau_CF(f))*sum(I_h(F_h==f)./P_bar_CF_h(F_h==f));
        nominal_exports(t,f)=nom_exports(f); %(1+tau_EXPORT(f))
        real_exports(t,f)=rea_exports(f); %(1+tau_EXPORT(f))
        nominal_imports(t,f)=nom_imports(f);
        real_imports(t,f)=rea_imports(f);
        operating_surplus(t,f)=sum(P_i(F_i==f).*Q_i(F_i==f)+P_i(F_i==f).*DS_i(F_i==f)-(1+tau_SIF(f))*w_i(F_i==f).*N_i(F_i==f)*P_bar_HH(f)-1./beta_i(F_i==f).*P_bar_i(F_i==f).*Y_i(F_i==f)-tau_Y_i(F_i==f).*P_i(F_i==f).*Y_i(F_i==f)-tau_K_i(F_i==f).*P_i(F_i==f).*Y_i(F_i==f));
        capital_consumption(t,f)=sum(P_CF_i(F_i==f).*Y_i(F_i==f).*delta_i(F_i==f)./kappa_i(F_i==f));
        compensation_employees(t,f)=sum((1+tau_SIF(f)).*w_i(F_i==f).*N_i(F_i==f))*P_bar_HH(f);
        wages(t,f)=sum(w_i(F_i==f).*N_i(F_i==f))*P_bar_HH(f);
        taxes_production(t,f)=sum(tau_K_i(F_i==f).*Y_i(F_i==f).*P_i(F_i==f));
        
        for g=1:G
            nominal_sector_gva(t,f,g)=sum((1-tau_Y_i(F_i==f&G_i==g)).*P_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g))-sum(1./beta_i(F_i==f&G_i==g).*P_bar_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g));
            real_sector_gva(t,f,g)=sum(Y_i(F_i==f&G_i==g).*((1-tau_Y_i(F_i==f&G_i==g))-1./beta_i(F_i==f&G_i==g)));
            sector_operating_surplus(t,f,g)=sum(P_i(F_i==f&G_i==g).*Q_i(F_i==f&G_i==g)+P_i(F_i==f&G_i==g).*DS_i(F_i==f&G_i==g)-(1+tau_SIF(F_i(F_i==f&G_i==g))).*w_i(F_i==f&G_i==g).*N_i(F_i==f&G_i==g)*P_bar_HH(f)-1./beta_i(F_i==f&G_i==g).*P_bar_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g)-tau_Y_i(F_i==f&G_i==g).*P_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g)-tau_K_i(F_i==f&G_i==g).*P_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g));
            sector_capital_consumption(t,f,g)=sum(P_CF_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g).*delta_i(F_i==f&G_i==g)./kappa_i(F_i==f&G_i==g));
            nominal_sector_output(t,f,g)=sum(P_i(F_i==f&G_i==g).*Y_i(F_i==f&G_i==g));
            real_sector_output(t,f,g)=sum(Y_i(F_i==f&G_i==g));
        end
        
        nominal_output(t,f)=sum(P_i(F_i==f).*Y_i(F_i==f));
        real_output(t,f)=sum(Y_i(F_i==f));
        
        government_debt(t,f)=L_G(f);
        government_deficit(t,f)=Pi_G(f);
        unemployment_rate(t,f)=sum(O_h==0&F_h(1:H_W)==f)/sum(F_h(1:H_W)==f);
        loan_issuance(t,f) = sum(DL_i(F_i==f));
    end

    % Capital dynamics tracking
    capital_stock_dynamics(t, :, :) = accumarray([F_i(:), G_i(:)], K_i(:), [F, G]);
    capital_loss(t, :) = accumarray(F_i(:), X_i(:), [F, 1]) ./ max(1e-10, accumarray(F_i(:), K_i(:)+X_i(:), [F, 1]));
    sector_capital_loss(t, :, :) = accumarray([F_i(:), G_i(:)], X_i(:), [F, G]) ./ max(1e-10, accumarray([F_i(:), G_i(:)], K_i(:)+X_i(:), [F, G]));
    damaged_firms_mask = (X_i ./ max(1e-10, K_i+X_i)) > 0.15;
    firms_damaged(t, :, :) = accumarray([F_i(:), G_i(:)], damaged_firms_mask(:), [F, G]);

    % Credit constraint tracking
    credit_gap(t, :) = accumarray(F_i(:), max(0, DL_d_i(:) - DL_i(:)), [F, 1])';
    for f = 1:F
        credit_gap_to_gdp(t, f) = credit_gap(t, f) / max(1e-10, nominal_gdp(t, f));
    end
    demanding_mask = DL_d_i > 0;
    constrained_mask = demanding_mask & (DL_i < DL_d_i);
    total_firms_demanding(t, :, :) = accumarray([F_i(:), G_i(:)], demanding_mask(:), [F, G]);
    credit_constrained_pct(t, :, :) = accumarray([F_i(:), G_i(:)], constrained_mask(:), [F, G]) ./ max(1, squeeze(total_firms_demanding(t, :, :)));

    euribor(t)=r_bar;
    
    insolvent=find(D_i<0 & E_i<0);
    for q=1:length(insolvent)
        i=insolvent(q);
        E_k=E_k-(L_i(i)-D_i(i)-zeta_b*P_bar_CF(F_i(i))*K_i(i));
        E_i(i)=E_i(i)+(L_i(i)-D_i(i)-zeta_b*P_bar_CF(F_i(i))*K_i(i));
        L_i(i)=zeta_b*P_bar_CF(F_i(i))*K_i(i);
        D_i(i)=0;
    end
end

end
