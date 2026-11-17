function y=active_final_buyers(x,firm_demand,other_demand,I,n)
% Preserve the exact ascending set of original buyers whose demand exceeds eps.
if isempty(x), y=zeros(1,0); return; end
if numel(x)>n/16
    keep=false(1,n);
    for k=1:numel(x)
        h=x(k);
        if h<=I
            keep(h)=firm_demand(h)>eps;
        else
            keep(h)=other_demand(h-I)>eps;
        end
    end
    y=reshape(find(keep),1,[]);
else
    next=zeros(size(x));
    count=0;
    for k=1:numel(x)
        h=x(k);
        if h<=I
            active=firm_demand(h)>eps;
        else
            active=other_demand(h-I)>eps;
        end
        if active
            count=count+1;
            next(count)=h;
        end
    end
    y=reshape(sort(next(1:count)),1,[]);
end
end
