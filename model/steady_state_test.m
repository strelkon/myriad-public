for y=2015
    for q=4
        [nominal_gdp,real_gdp]=simulate_abm(y,q,0,0);
        sum(sum(abs(diff(log(nominal_gdp)))))
    end
end
