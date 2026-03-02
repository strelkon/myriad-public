function y=shuffle(population,varargin)
y=population(randperm(length(population),varargin{:}));
end

