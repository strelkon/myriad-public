function [epsilon_] = epsilon(C)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if sum(sum(C))~=0
    L=chol(C,'lower');
    epsilon=randn(size(C,1),1);
else
    L=zeros(size(C));
    epsilon=zeros(size(C,1),1);
end
epsilon_=(L*epsilon)';
end

