function [Q_d_i,Q_d_m,P_bar_i,DM_i,P_CF_i,I_i,P_bar_h,C_h,P_bar_CF_h,I_h,P_j,C_j,P_l,C_l,bilateral_trade_g,bilateral_trade_real_g]=search_and_matching(P_i,Y_i,S_i,S_i_,G_i,P_m,Y_m,Y_m_,G_m,a_sg,DM_d_i,b_CF_g,I_d_i,b_HH_g,C_d_h,b_CFH_g,I_d_h,c_G_g,C_d_j,c_E_g,C_d_l,F,F_i,F_h,s_a_ffsg,s_CF_ffg,s_CFH_ffg,s_HH_ffg,s_G_ffg,s_E_fg)

G=size(b_HH_g,1);
I=size(P_i,2);
H=size(C_d_h,2);
L=size(C_d_l,2);
J=size(C_d_j,2);

P_f=[P_i,P_m];
S_f=[Y_i+S_i,Y_m];
S_f_=[S_i_,Y_m_];

G_f=[G_i,G_m];
F_if=[F_i,(F+1)*ones(1,length(G_m))];
F_hf=[F_h,(F+1)*ones(1,L),1:F];

Q_d_i=zeros(size(Y_i));
Q_d_m=zeros(size(Y_m));

I_i=zeros(1,I);
P_CF_i=zeros(1,I);
DM_i=zeros(1,I);
P_bar_i=zeros(1,I);

C_h=zeros(size(C_d_h));
I_h=zeros(size(I_d_h));
C_j=zeros(size(C_d_j));
C_l=0;

P_bar_h=zeros(size(C_d_h));
P_bar_CF_h=zeros(size(I_d_h));
P_j=zeros(size(C_d_j));
P_l=0;

bilateral_trade_g=zeros(F+1,F+1,G);
bilateral_trade_real_g=zeros(F+1,F+1,G);
s_E_fg_=[s_E_fg;zeros(1,G)];
for g=1:G
    S_fg=S_f;
    S_fg_=S_f_;
    for e=1:F+1
    DM_d_ig=zeros(size(DM_d_i));
    for i=1:I
        DM_d_ig(i)=s_a_ffsg(e,F_i(i),g,G_i(i))*a_sg(g,G_i(i),F_i(i))*DM_d_i(i);
    end
    DM_nominal_ig=zeros(size(DM_d_ig));
    I_g=find(DM_d_ig>0);
    F_g=find(G_f==g&F_if==e&S_fg>0);
    while ~isempty(I_g) && ~isempty(F_g)
        I_g=shuffle(I_g);
        pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
        pr_size_f=S_f(F_g)/sum(S_f(F_g));
        pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
        F_g=sample(F_g,length(I_g),pr_f);
        % F_g=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,squeeze(s_a_ffsg(:,:,g,:)),F,G);
        I_g(isnan(F_g))=[];
        F_g(isnan(F_g))=[];
        if isempty(F_g)
           break
        end
        for j=1:length(I_g)
            i=I_g(j);
            f=F_g(j);
            c=F_if(i);
            cf=F_if(f);
            dS_fg=min(S_fg(f),DM_d_ig(i));
            S_fg(f)=S_fg(f)-dS_fg;
            DM_d_ig(i)=DM_d_ig(i)-dS_fg;
            DM_nominal_ig(i)=DM_nominal_ig(i)+dS_fg*P_f(f);
            bilateral_trade_g(c,cf,g)=bilateral_trade_g(c,cf,g)+dS_fg*P_f(f);
            bilateral_trade_real_g(c,cf,g)=bilateral_trade_real_g(c,cf,g)+dS_fg;
        end
        I_g=find(DM_d_ig>eps);
        F_g=find(G_f==g&F_if==e&S_fg>eps);
    end
    if ~isempty(I_g)
        DM_d_ig_=DM_d_ig;
        I_g=find(DM_d_ig_>0);
        F_g=find(G_f==g&F_if==e&S_fg_>0);
        while ~isempty(I_g) && ~isempty(F_g)
            I_g=shuffle(I_g);
            pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
            pr_size_f=S_f(F_g)/sum(S_f(F_g));
            pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
            F_g=sample(F_g,length(I_g),pr_f);
            % F_g=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,squeeze(s_a_ffsg(:,:,g,:)),F,G);
            I_g(isnan(F_g))=[];
            F_g(isnan(F_g))=[];
            if isempty(F_g)
                break
            end
            for j=1:length(I_g)
                i=I_g(j);
                f=F_g(j);
                dS_fg=min(S_fg_(f),DM_d_ig_(i));
                S_fg(f)=S_fg(f)-dS_fg;
                S_fg_(f)=S_fg_(f)-dS_fg;
                DM_d_ig_(i)=DM_d_ig_(i)-dS_fg;
            end
            I_g=find(DM_d_ig_>eps);
            F_g=find(G_f==g&F_if==e&S_fg_>eps);
        end
    end
    
    for i=1:I
        DM_i(i)=s_a_ffsg(e,F_i(i),g,G_i(i))*a_sg(g,G_i(i),F_i(i))*DM_d_i(i)-DM_d_ig(i)+DM_i(i);
    end
    P_bar_i=P_bar_i+DM_nominal_ig;
    
    I_d_ig=s_CF_ffg(e,F_i,g).*b_CF_g(g,F_i).*I_d_i;
    I_nominal_ig=zeros(size(I_d_i));
    C_d_hg=[s_HH_ffg(e,F_h,g).*b_HH_g(g,F_h).*C_d_h+b_CFH_g(g,F_h).*I_d_h,s_E_fg_(e,g)*c_E_g(g)*C_d_l,s_G_ffg(e,:,g).*c_G_g(g,:).*C_d_j];
    C_real_hg=zeros(size(C_d_hg));
    H_g=[find(I_d_ig>0),length(I_d_i)+find(C_d_hg>0)];
    F_g=find(G_f==g&F_if==e&S_fg>0);
    while ~isempty(H_g) && ~isempty(F_g)
        H_g=shuffle(H_g);
        pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
        pr_size_f=S_f(F_g)/sum(S_f(F_g));
        pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
        F_g=sample(F_g,length(H_g),pr_f);
        % F_g=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,squeeze(s_CF_ffg(:,:,g)),squeeze(s_CFH_ffg(:,:,g)),squeeze(s_HH_ffg(:,:,g)),squeeze(s_G_ffg(:,:,g)),s_E_fg(:,g),F,I,L,H);
        H_g(isnan(F_g))=[];
        F_g(isnan(F_g))=[];
        if isempty(F_g)
            break
        end
        for j=1:length(H_g)
            f=F_g(j);
            cf=F_if(f);
            h=H_g(j);
            if h<=length(I_d_i)
                i=h;
                c=F_if(i);
                dS_fg=min(S_fg(f),I_d_ig(i));
                I_d_ig(i)=I_d_ig(i)-dS_fg;
                I_nominal_ig(i)=I_nominal_ig(i)+dS_fg*P_f(f);
            else
                h=h-length(I_d_i);
                c=F_hf(h);
                dS_fg=min(S_fg(f),C_d_hg(h)/(P_f(f)));
                C_d_hg(h)=C_d_hg(h)-dS_fg*P_f(f);
                C_real_hg(h)=C_real_hg(h)+dS_fg;
            end
            S_fg(f)=S_fg(f)-dS_fg;
            bilateral_trade_g(c,cf,g)=bilateral_trade_g(c,cf,g)+dS_fg*P_f(f);
            bilateral_trade_real_g(c,cf,g)=bilateral_trade_real_g(c,cf,g)+dS_fg;
        end
        H_g=[find(I_d_ig>eps),length(I_d_ig)+find(C_d_hg>eps)];
        F_g=find(G_f==g&F_if==e&S_fg>eps);
    end
    if ~isempty(H_g)
        I_d_ig_=I_d_ig;
        C_d_hg_=C_d_hg;
        H_g=[find(I_d_ig_>0),length(I_d_i)+find(C_d_hg_>0)];
        F_g=find(G_f==g&F_if==e&S_fg_>0);
        while ~isempty(H_g) && ~isempty(F_g)
            H_g=shuffle(H_g);
            pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
            pr_size_f=S_f(F_g)/sum(S_f(F_g));
            pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
            F_g=sample(F_g,length(H_g),pr_f);
            % F_g=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,squeeze(s_CF_ffg(:,:,g)),squeeze(s_CFH_ffg(:,:,g)),squeeze(s_HH_ffg(:,:,g)),squeeze(s_G_ffg(:,:,g)),s_E_fg(:,g),F,I,L,H);
            H_g(isnan(F_g))=[];
            F_g(isnan(F_g))=[];
            if isempty(F_g)
                break
            end
            for j=1:length(H_g)
                f=F_g(j);
                h=H_g(j);
                if h<=length(I_d_i)
                    i=h;
                    dS_fg=min(S_fg_(f),I_d_ig_(i));
                    I_d_ig_(i)=I_d_ig_(i)-dS_fg;
                else
                    h=h-length(I_d_i);
                    dS_fg=min(S_fg_(f),C_d_hg_(h)/P_f(f));
                    C_d_hg_(h)=C_d_hg_(h)-dS_fg*P_f(f);
                end
                S_fg(f)=S_fg(f)-dS_fg;
                S_fg_(f)=S_fg_(f)-dS_fg;
            end
            H_g=[find(I_d_ig_>eps),length(I_d_i)+find(C_d_hg_>eps)];
            F_g=find(G_f==g&F_if==e&S_fg_>eps);
        end
    end
    
    I_i=I_i+s_CF_ffg(e,F_i,g).*b_CF_g(g,F_i).*I_d_i-I_d_ig;
    P_CF_i=P_CF_i+I_nominal_ig;
    
    C_h=s_HH_ffg(e,F_h,g).*b_HH_g(g,F_h).*C_d_h-max(0,C_d_hg(1:H)-b_CFH_g(g,F_h).*I_d_h)+C_h;
    I_h=max(0,b_CFH_g(g,F_h).*I_d_h-C_d_hg(1:H))+I_h;
    C_j=s_G_ffg(e,:,g).*c_G_g(g,:).*C_d_j-C_d_hg(H+L+1:H+L+J)+C_j;
    C_l=sum(s_E_fg_(e,g)*c_E_g(g)*C_d_l)-sum(C_d_hg(H+1:H+L))+C_l;
    
    P_bar_h=P_bar_h+max(0,C_real_hg(1:H).*(C_d_h.*s_HH_ffg(e,F_h,g).*b_HH_g(g,F_h)-max(0,C_d_hg(1:H)-b_CFH_g(g,F_h).*I_d_h))./(C_d_h.*s_HH_ffg(e,F_h,g).*b_HH_g(g,F_h)+b_CFH_g(g,F_h).*I_d_h-C_d_hg(1:H)));
    P_bar_CF_h=P_bar_CF_h+max(0,C_real_hg(1:H).*(max(0,b_CFH_g(g,F_h).*I_d_h-C_d_hg(1:H)))./(C_d_h.*s_HH_ffg(e,F_h,g).*b_HH_g(g,F_h)+b_CFH_g(g,F_h).*I_d_h-C_d_hg(1:H)));
    P_j=P_j+C_real_hg(H+L+1:H+L+J);
    P_l=P_l+sum(C_real_hg(H+1:H+L));
    end
    
    Q_d_i=S_f(1:I)-S_fg(1:I)+Q_d_i;
    Q_d_m=S_f(I+1:end)-S_fg(I+1:end)+Q_d_m;
end

P_CF_i(I_i>0)=P_CF_i(I_i>0)./I_i(I_i>0);
P_bar_i(DM_i>0)=P_bar_i(DM_i>0)./DM_i(DM_i>0);

P_bar_h=C_h./P_bar_h;
P_bar_CF_h=I_h./P_bar_CF_h;
P_j=C_j./P_j;
P_l=C_l./P_l;

end
