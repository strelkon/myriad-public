function y=sample(population,k,w)
if isscalar(population)
    y=population*ones(1,k);
else
    y=randsample(population,k,true,w);
end
end
