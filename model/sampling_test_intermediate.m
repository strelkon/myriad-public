c=6;
s=1;

figure
hold
plot(squeeze(s_a_ffsg(:,c,g,s)));
[y,x]=hist(F_if(F_g(F_i(I_g)==c&G_i(I_g)==s)),1:27);
plot(x,y/sum(y))