function y=ordered_active(x,n)
% Inputs are unique positive indices. Preserve ascending order exactly.
if numel(x)>n/16
    keep=false(1,n);
    keep(x)=true;
    y=find(keep);
else
    y=sort(x);
end
end
