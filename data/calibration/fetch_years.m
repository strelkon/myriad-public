function value = fetch_years(conn,sqlquery,start_time,end_time)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
nace={'A01';'A02';'A03';'B';'C10-C12';'C13-C15';'C16';'C17';'C18';'C19';'C20';'C21';'C22';'C23';'C24';'C25';'C26';'C27';'C28';'C29';'C30';'C31_C32';'C33';'D';'E36';'E37-E39';'F';'G45';'G46';'G47';'H49';'H50';'H51';'H52';'H53';'I';'J58';'J59_J60';'J61';'J62_J63';'K64';'K65';'K66';'L';'M69_M70';'M71';'M72';'M73';'M74_M75';'N77';'N78';'N79';'N80-N82';'O';'P';'Q86';'Q87_Q88';'R90-R92';'R93';'S94';'S95';'S96'};
T=fetch(conn,sqlquery);
T.time=dateshift(datetime(T.time,'InputFormat','y'),'end','year');
TT=table2timetable(T,'RowTimes','time');
value=NaN(62,length(unique(T.time)));
for g=1:62
   value(g,:)=retime(TT(string(TT.nace)==nace{g},:),dateshift(start_time:calyears(1):end_time,'end','year'),'nearest').value;
end
end

