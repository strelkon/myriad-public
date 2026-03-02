function [alpha,beta,epsilon]=estimate(ydata)
var=rfvar3(ydata,1,ones(size(ydata,1),1),[],0,0);
alpha=var.By;
beta=var.Bx(1);
epsilon=var.u;
end
