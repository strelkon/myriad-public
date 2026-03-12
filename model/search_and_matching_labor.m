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

vacancies=max(0,V_i);
total_vacancies=sum(vacancies);
hires=min(sum(O_h==0),total_vacancies);
H_U=shuffle(find(O_h==0),hires);
if hires>0
    vacancy_positions=randperm(total_vacancies,hires);
    positive_firms=find(vacancies>0);
    I_V=positive_firms(discretize(vacancy_positions,[0,cumsum(vacancies(positive_firms))],'IncludedEdge','right'));
else
    I_V=zeros(1,0);
end
O_h(H_U)=I_V;
N_i(I_V)=N_i(I_V)+vacancies(I_V);
end
