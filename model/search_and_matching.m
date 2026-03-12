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

supplier_idx_by_country=zeros(G,length(G_f));
supplier_count_by_country=zeros(1,G);
for n=1:length(G_f)
    supplier_country=G_f(n);
    supplier_count_by_country(supplier_country)=supplier_count_by_country(supplier_country)+1;
    supplier_idx_by_country(supplier_country,supplier_count_by_country(supplier_country))=n;
end

a_sz=size(a_sg);
a_linear_offsets=a_sz(1).*((G_i-1)+a_sz(2).*(F_i-1));

for g=1:G
    supplier_idx_g=supplier_idx_by_country(g,1:supplier_count_by_country(g));
    a_g_i=a_sg(g+a_linear_offsets);
    DM_d_ig=a_g_i.*DM_d_i;
    DM_nominal_ig=zeros(size(DM_d_ig));
    I_g=find(DM_d_ig>0);
    S_fg=S_f;
    S_fg_=S_f_;
    F_g=supplier_idx_g(S_fg(supplier_idx_g)>0);
    s_a_ffsg_g=squeeze(s_a_ffsg(:,:,g,:));
    while ~isempty(I_g) && ~isempty(F_g)
        I_g=shuffle(I_g);
%         pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
%         pr_size_f=S_f(F_g)/sum(S_f(F_g));
%         pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
%         F_g=sample(F_g,length(I_g),pr_f);
        matched_F_g=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,s_a_ffsg_g,F,G);
        invalid_matches=isnan(matched_F_g);
        I_g(invalid_matches)=[];
        matched_F_g(invalid_matches)=[];
        if isempty(matched_F_g)
           break
        end
        for j=1:length(I_g)
            i=I_g(j);
            f=matched_F_g(j);
            c=F_if(i);
            cf=F_if(f);
            dS_fg=min(S_fg(f),DM_d_ig(i));
            S_fg(f)=S_fg(f)-dS_fg;
            DM_d_ig(i)=DM_d_ig(i)-dS_fg;
            DM_nominal_ig(i)=DM_nominal_ig(i)+dS_fg*P_f(f);
            bilateral_trade_g(c,cf,g)=bilateral_trade_g(c,cf,g)+dS_fg*P_f(f);
            bilateral_trade_real_g(c,cf,g)=bilateral_trade_real_g(c,cf,g)+dS_fg;
        end
        I_g=sort(I_g(DM_d_ig(I_g)>eps));
        F_g=supplier_idx_g(S_fg(supplier_idx_g)>eps);
    end
    if ~isempty(I_g)
        DM_d_ig_=DM_d_ig;
        I_g=find(DM_d_ig_>0);
        F_g=supplier_idx_g(S_fg_(supplier_idx_g)>0);
        while ~isempty(I_g) && ~isempty(F_g)
            I_g=shuffle(I_g);
%             pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
%             pr_size_f=S_f(F_g)/sum(S_f(F_g));
%             pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
%             F_g=sample(F_g,length(I_g),pr_f);
            matched_F_g=sample_intermediate_consumption(F_g,P_f,F_if,I_g,F_i,G_i,s_a_ffsg_g,F,G);
            invalid_matches=isnan(matched_F_g);
            I_g(invalid_matches)=[];
            matched_F_g(invalid_matches)=[];
            if isempty(matched_F_g)
                break
            end
            for j=1:length(I_g)
                i=I_g(j);
                f=matched_F_g(j);
                dS_fg=min(S_fg_(f),DM_d_ig_(i));
                S_fg(f)=S_fg(f)-dS_fg;
                S_fg_(f)=S_fg_(f)-dS_fg;
                DM_d_ig_(i)=DM_d_ig_(i)-dS_fg;
            end
            I_g=sort(I_g(DM_d_ig_(I_g)>eps));
            F_g=supplier_idx_g(S_fg_(supplier_idx_g)>eps);
        end
    end
    
    DM_i=DM_i+a_g_i.*DM_d_i-DM_d_ig;
    P_bar_i=P_bar_i+DM_nominal_ig;
    
    b_CF_row=b_CF_g(g,F_i);
    b_HH_row=b_HH_g(g,F_h);
    b_CFH_row=b_CFH_g(g,F_h);
    c_G_row=c_G_g(g,:);
    c_E_value=c_E_g(g);
    I_d_ig=b_CF_row.*I_d_i;
    I_nominal_ig=zeros(size(I_d_i));
    C_d_hg=[b_HH_row.*C_d_h+b_CFH_row.*I_d_h,c_E_value.*C_d_l,c_G_row.*C_d_j];
    C_real_hg=zeros(size(C_d_hg));
    H_g=[find(I_d_ig>0),length(I_d_i)+find(C_d_hg>0)];
    F_g=supplier_idx_g(S_fg(supplier_idx_g)>0);
    s_CF_ffg_g=squeeze(s_CF_ffg(:,:,g));
    s_CFH_ffg_g=squeeze(s_CFH_ffg(:,:,g));
    s_HH_ffg_g=squeeze(s_HH_ffg(:,:,g));
    s_G_ffg_g=squeeze(s_G_ffg(:,:,g));
    while ~isempty(H_g) && ~isempty(F_g)
        H_g=shuffle(H_g);
%         pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
%         pr_size_f=S_f(F_g)/sum(S_f(F_g));
%         pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
%         F_g=sample(F_g,length(H_g),pr_f);
        matched_F_g=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,s_CF_ffg_g,s_CFH_ffg_g,s_HH_ffg_g,s_G_ffg_g,s_E_fg(:,g),F,I,L,H);
        invalid_matches=isnan(matched_F_g);
        H_g(invalid_matches)=[];
        matched_F_g(invalid_matches)=[];
        if isempty(matched_F_g)
            break
        end
        for j=1:length(H_g)
            f=matched_F_g(j);
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
        if isempty(H_g)
            H_g=[];
        else
            active_h_mask=H_g<=I;
            next_H_mask=false(size(H_g));
            next_H_mask(active_h_mask)=I_d_ig(H_g(active_h_mask))>eps;
            remaining_H=H_g(~active_h_mask)-I;
            next_H_mask(~active_h_mask)=C_d_hg(remaining_H)>eps;
            H_g=sort(H_g(next_H_mask));
        end
        F_g=supplier_idx_g(S_fg(supplier_idx_g)>eps);
    end
    if ~isempty(H_g)
        I_d_ig_=I_d_ig;
        C_d_hg_=C_d_hg;
        H_g=[find(I_d_ig_>0),length(I_d_i)+find(C_d_hg_>0)];
        F_g=supplier_idx_g(S_fg_(supplier_idx_g)>0);
        while ~isempty(H_g) && ~isempty(F_g)
            H_g=shuffle(H_g);
%             pr_price_f=max(0,exp(-2*P_f(F_g))./sum(exp(-2*P_f(F_g))));
%             pr_size_f=S_f(F_g)/sum(S_f(F_g));
%             pr_f=(pr_price_f+pr_size_f)/sum(pr_price_f+pr_size_f);
%             F_g=sample(F_g,length(H_g),pr_f);
            matched_F_g=sample_final_demand(F_g,P_f,F_if,H_g,F_hf,s_CF_ffg_g,s_CFH_ffg_g,s_HH_ffg_g,s_G_ffg_g,s_E_fg(:,g),F,I,L,H);
            invalid_matches=isnan(matched_F_g);
            H_g(invalid_matches)=[];
            matched_F_g(invalid_matches)=[];
            if isempty(matched_F_g)
                break
            end
            for j=1:length(H_g)
                f=matched_F_g(j);
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
            if isempty(H_g)
                H_g=[];
            else
                active_h_mask=H_g<=I;
                next_H_mask=false(size(H_g));
                next_H_mask(active_h_mask)=I_d_ig_(H_g(active_h_mask))>eps;
                remaining_H=H_g(~active_h_mask)-I;
                next_H_mask(~active_h_mask)=C_d_hg_(remaining_H)>eps;
                H_g=sort(H_g(next_H_mask));
            end
            F_g=supplier_idx_g(S_fg_(supplier_idx_g)>eps);
        end
    end
    
    Q_d_i=S_f(1:I)-S_fg(1:I)+Q_d_i;
    Q_d_m=S_f(I+1:end)-S_fg(I+1:end)+Q_d_m;
    
    I_i=I_i+b_CF_row.*I_d_i-I_d_ig;
    P_CF_i=P_CF_i+I_nominal_ig;
    
    C_h=b_HH_row.*C_d_h-max(0,C_d_hg(1:H)-b_CFH_row.*I_d_h)+C_h;
    I_h=max(0,b_CFH_row.*I_d_h-C_d_hg(1:H))+I_h;
    C_j=c_G_row.*C_d_j-C_d_hg(H+L+1:H+L+J)+C_j;
    C_l=sum(c_E_value.*C_d_l)-sum(C_d_hg(H+1:H+L))+C_l;
    
    P_bar_h=P_bar_h+max(0,C_real_hg(1:H).*(C_d_h.*b_HH_row-max(0,C_d_hg(1:H)-b_CFH_row.*I_d_h))./(C_d_h.*b_HH_row+b_CFH_row.*I_d_h-C_d_hg(1:H)));
    P_bar_CF_h=P_bar_CF_h+max(0,C_real_hg(1:H).*(max(0,b_CFH_row.*I_d_h-C_d_hg(1:H)))./(C_d_h.*b_HH_row+b_CFH_row.*I_d_h-C_d_hg(1:H)));
    P_j=P_j+C_real_hg(H+L+1:H+L+J);
    P_l=P_l+sum(C_real_hg(H+1:H+L));
end

P_CF_i(I_i>0)=P_CF_i(I_i>0)./I_i(I_i>0);
P_bar_i(DM_i>0)=P_bar_i(DM_i>0)./DM_i(DM_i>0);

P_bar_h=C_h./P_bar_h;
P_bar_CF_h=I_h./P_bar_CF_h;
P_j=C_j./P_j;
P_l=C_l./P_l;

end
