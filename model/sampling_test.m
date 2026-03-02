c=1;

figure
hold
plot(s_HH_ffg(:,c,g));
[y,x]=hist(F_if(F_g(H_g>I&H_g<=H+I&F_hf(max(1,H_g-I))==c)),1:27);
plot(x,y/sum(y))