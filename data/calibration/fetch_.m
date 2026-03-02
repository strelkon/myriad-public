function value = fetch_(conn,sqlquery,quarters_num)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
T=fetch(conn,sqlquery);
T.time=dateshift(datetime(T.time,'InputFormat','y-QQQ'),'end','quarter');
TT=table2timetable(T,'RowTimes','time');
value=retime(TT,datetime(datestr(quarters_num)),'linear').value;
end

