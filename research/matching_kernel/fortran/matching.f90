module myriad_matching_fortran
use iso_c_binding
use, intrinsic :: ieee_arithmetic
implicit none
private
public :: matching_f
real(c_double), parameter :: tol=epsilon(1.0_c_double)
interface
 subroutine uniform_f(x,n) bind(C,name='myriad_uniform')
 import c_double,c_int
 real(c_double) :: x(*)
 integer(c_int),value :: n
 end subroutine
 function power_f(x) result(y) bind(C,name='myriad_power')
 import c_double
 real(c_double),value :: x
 real(c_double) :: y
 end function
end interface
contains
! Match MATLAB Coder's 1024/4096-element reduction tree, not Fortran SUM.
function block_sum(x) result(y)
 real(c_double),intent(in)::x(:)
 real(c_double)::y,t,p(4)
 integer::n,k,j,b,start,stop,full
 n=size(x);y=0.0_c_double
 if(n==0)return
 if(n<4096)then
  y=x(1)
  do k=2,min(n,1024);y=y+x(k);end do
  do start=1025,n,1024
   t=x(start);do k=start+1,min(start+1023,n);t=t+x(k);end do
   y=y+t
  end do
 else
  full=n/4096
  do b=0,full-1
   do j=1,4
    start=b*4096+(j-1)*1024+1;p(j)=x(start)
    do k=start+1,start+1023;p(j)=p(j)+x(k);end do
   end do
   t=(p(1)+p(2))+(p(3)+p(4))
   if(b==0)then;y=t;else;y=y+t;end if
  end do
  start=full*4096+1
  if(start<=n)then
   t=x(start)
   do k=start+1,min(start+1023,n);t=t+x(k);end do
   do stop=start+1024,n,1024
    p(1)=x(stop);do k=stop+1,min(stop+1023,n);p(1)=p(1)+x(k);end do
    t=t+p(1)
   end do
   y=y+t
  end if
 end if
end function
function maxzero(x) result(y)
 real(c_double),intent(in)::x
 real(c_double)::y
 y=0.0_c_double
 if(x>0.0_c_double)y=x
end function
function minval2(x,y) result(z)
 real(c_double),intent(in)::x,y
 real(c_double)::z
 if(ieee_is_nan(x))then;z=y
 else if(ieee_is_nan(y))then;z=x
 else if(x<y)then;z=x
 else;z=y
 end if
end function
subroutine shuffle_ids(ids)
 integer(c_int),intent(inout)::ids(:)
 real(c_double),allocatable::u(:)
 integer(c_int),allocatable::order(:),work(:),copy(:)
 integer(c_int64_t),allocatable::keys(:)
 integer::n,j,k,shift,bucket,counts(0:255),offset(0:255),running
 n=size(ids);if(n==0)return
 allocate(u(n),keys(n),order(n),work(n),copy(n))
 call uniform_f(u,int(n,c_int))
 do j=1,n
  keys(j)=transfer(u(j),keys(j));order(j)=j
 end do
 ! Uniform values are nonnegative finite doubles. Stable byte passes preserve ties.
 do shift=0,56,8
  counts=0
  do j=1,n
   bucket=int(iand(shiftr(keys(order(j)),shift),255_c_int64_t));counts(bucket)=counts(bucket)+1
  end do
  if(maxval(counts)==n)cycle
  running=1
  do k=0,255;offset(k)=running;running=running+counts(k);end do
  do j=1,n
   bucket=int(iand(shiftr(keys(order(j)),shift),255_c_int64_t));work(offset(bucket))=order(j);offset(bucket)=offset(bucket)+1
  end do
  order=work
 end do
 copy=ids
 do j=1,n;ids(j)=copy(order(j));end do
end subroutine
subroutine weighted_sample(suppliers,weights,k,draws)
 integer(c_int),intent(in)::suppliers(:)
 real(c_double),intent(in)::weights(:)
 integer,intent(in)::k
 integer(c_int),intent(out)::draws(k)
 real(c_double),allocatable::edges(:),u(:)
 real(c_double)::sw
 integer::n,j,lo,hi,mid
 n=size(suppliers)
 if(n==1)then;draws=suppliers(1);return;end if
 sw=block_sum(weights);allocate(edges(n+1));edges(1)=0.0_c_double;edges(n+1)=1.0_c_double
 do j=1,n-1;edges(j+1)=minval2(edges(j)+weights(j)/sw,1.0_c_double);end do
 if(k==0)return
 allocate(u(k));call uniform_f(u,int(k,c_int))
 do j=1,k
  lo=1;hi=n+1
  do while(hi-lo>1)
   mid=lo+(hi-lo)/2
   if(u(j)>=edges(mid))then;lo=mid;else;hi=mid;end if
  end do
  if(u(j)==edges(n+1))lo=n+1
  ! MATLAB's RNG produces values strictly below 1; no endpoint remapping.
  if(lo>n)error stop 'Unexpected uniform endpoint in weighted sampling'
  draws(j)=suppliers(lo)
 end do
end subroutine
subroutine grouped_sample(suppliers,prices,countries,ids,gids,ngroups,table,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),ids(:),gids(:)
 integer,intent(in)::ngroups
 real(c_double),intent(in)::prices(:),table(:,:)
 integer(c_int),intent(out)::matched(size(ids))
 integer,allocatable::counts(:),offset(:),next(:),positions(:)
 integer(c_int),allocatable::draws(:)
 real(c_double),allocatable::s(:),w(:),pg(:)
 real(c_double)::sc(27),ss,ws
 integer::n,m,j,g,idx,c,start,k
 n=size(suppliers);m=size(ids);matched=0;if(m==0)return
 allocate(counts(ngroups),offset(ngroups),next(ngroups),positions(m),s(n),w(n),pg(n))
 counts=0;sc=0.0_c_double
 do j=1,n;c=countries(suppliers(j));sc(c)=sc(c)+1.0_c_double;pg(j)=power_f(prices(suppliers(j)));end do
 do j=1,m;counts(gids(j))=counts(gids(j))+1;end do
 start=1
 do g=1,ngroups;offset(g)=start;next(g)=start;start=start+counts(g);end do
 do j=1,m;g=gids(j);positions(next(g))=j;next(g)=next(g)+1;end do
 do g=1,ngroups
  k=counts(g);if(k==0)cycle
  do j=1,n;s(j)=table(countries(suppliers(j)),g)/sc(countries(suppliers(j)))+tol;end do
  ss=block_sum(s)
  if(ss>0.0_c_double)then
   do j=1,n;s(j)=s(j)/ss;w(j)=pg(j)*s(j);end do
   ws=block_sum(w);do j=1,n;w(j)=w(j)/ws;end do
   allocate(draws(k));call weighted_sample(suppliers,w,k,draws)
   do j=1,k;matched(positions(offset(g)+j-1))=draws(j);end do
   deallocate(draws)
  end if
 end do
end subroutine
subroutine intermediate_sample(suppliers,prices,countries,buyers,sector,weights,g,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),buyers(:),sector(:)
 real(c_double),intent(in)::prices(:),weights(27,26,62,62)
 integer,intent(in)::g
 integer(c_int),intent(out)::matched(size(buyers))
 integer,allocatable::gid(:)
 real(c_double)::table(27,1612)
 integer::j,c,s
 allocate(gid(size(buyers)))
 do j=1,size(buyers);gid(j)=sector(buyers(j))+62*(countries(buyers(j))-1);end do
 do c=1,26;do s=1,62;table(:,s+62*(c-1))=weights(:,c,g,s);end do;end do
 call grouped_sample(suppliers,prices,countries,buyers,gid,1612,table,matched)
end subroutine
subroutine final_sample(suppliers,prices,countries,buyers,hcountries,ni,nh,nl,cf,hh,gov,ex,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),buyers(:),hcountries(:)
 integer,intent(in)::ni,nh,nl
 real(c_double),intent(in)::prices(:),cf(27,26),hh(27,26),gov(27,26),ex(26)
 integer(c_int),intent(out)::matched(size(buyers))
 integer(c_int),allocatable::pos(:),sub(:),gid(:),draws(:)
 real(c_double)::exports(27,1)
 integer::category,j,k,h
 logical::include
 matched=0
 do category=1,4
  allocate(pos(size(buyers)));k=0
  do j=1,size(buyers)
   h=buyers(j)
   select case(category)
   case(1);include=h<=ni
   case(2);include=h>ni.and.h<=ni+nh
   case(3);include=h>ni+nh+nl
   case(4);include=h>ni+nh.and.h<=ni+nh+nl
   end select
   if(include)then;k=k+1;pos(k)=j;end if
  end do
  allocate(sub(k),gid(k),draws(k))
  do j=1,k
   h=buyers(pos(j));sub(j)=h
   if(category==1)then;gid(j)=countries(h)
   else if(category==4)then;gid(j)=1
   else;gid(j)=hcountries(h-ni)
   end if
  end do
  select case(category)
  case(1);call grouped_sample(suppliers,prices,countries,sub,gid,26,cf,draws)
  case(2);call grouped_sample(suppliers,prices,countries,sub,gid,26,hh,draws)
  case(3);call grouped_sample(suppliers,prices,countries,sub,gid,26,gov,draws)
  case(4)
   exports(1:26,1)=ex;exports(27,1)=0.0_c_double
   call grouped_sample(suppliers,prices,countries,sub,gid,1,exports,draws)
  end select
  do j=1,k;matched(pos(j))=draws(j);end do
  deallocate(pos,sub,gid,draws)
 end do
end subroutine
! Compact without reordering; ascending active sets are reconstructed explicitly.
subroutine remove_invalid(buyers,matched)
 integer(c_int),allocatable,intent(inout)::buyers(:),matched(:)
 integer::j,k
 k=0
 do j=1,size(buyers)
  if(matched(j)/=0)then;k=k+1;buyers(k)=buyers(j);matched(k)=matched(j);end if
 end do
 buyers=buyers(:k);matched=matched(:k)
end subroutine
function active(d,threshold) result(ids)
 real(c_double),intent(in)::d(:),threshold
 integer(c_int),allocatable::ids(:)
 integer::j,k
 allocate(ids(count(d>threshold)));k=0
 do j=1,size(d);if(d(j)>threshold)then;k=k+1;ids(k)=j;end if;end do
end function
function supply_active(supplier_ids,stock,threshold) result(ids)
 integer(c_int),intent(in)::supplier_ids(:)
 real(c_double),intent(in)::stock(:),threshold
 integer(c_int),allocatable::ids(:)
 integer::j,k
 allocate(ids(size(supplier_ids)));k=0
 do j=1,size(supplier_ids)
  if(stock(supplier_ids(j))>threshold)then;k=k+1;ids(k)=supplier_ids(j);end if
 end do
 ids=ids(:k)
end function
subroutine sort_ids(x)
 integer(c_int),intent(inout)::x(:)
 integer(c_int),allocatable::work(:)
 integer::n,width,left,middle,right,a,b,k
 n=size(x);allocate(work(n));width=1
 do while(width<n)
  do left=1,n,2*width
   middle=min(left+width,n+1);right=min(left+2*width-1,n);a=left;b=middle
   do k=left,right
    if(a>=middle)then;work(k)=x(b);b=b+1
    else if(b>right)then;work(k)=x(a);a=a+1
    else if(x(a)<=x(b))then;work(k)=x(a);a=a+1
    else;work(k)=x(b);b=b+1
    end if
   end do
  end do
  x=work;width=2*width
 end do
end subroutine
subroutine filter_buyers(buyers,d,other,ni)
 integer(c_int),allocatable,intent(inout)::buyers(:)
 real(c_double),intent(in)::d(:),other(:)
 integer,intent(in)::ni
 logical,allocatable::keep(:)
 integer(c_int),allocatable::next(:)
 integer::j,h,k,n
 logical::alive
 n=ni+size(other)
 if(size(buyers)<=n/16)then
  allocate(next(size(buyers)));k=0
  do j=1,size(buyers)
   h=buyers(j)
   if(h<=ni)then;alive=d(h)>tol;else;alive=other(h-ni)>tol;end if
   if(alive)then;k=k+1;next(k)=h;end if
  end do
  buyers=next(:k);call sort_ids(buyers)
 else
  allocate(keep(n));keep=.false.
  do j=1,size(buyers)
   h=buyers(j)
   if(h<=ni)then;keep(h)=d(h)>tol;else;keep(h)=other(h-ni)>tol;end if
  end do
  k=count(keep);deallocate(buyers);allocate(buyers(k));k=0
  do h=1,n;if(keep(h))then;k=k+1;buyers(k)=h;end if;end do
 end if
end subroutine
subroutine matching_f(ni,nm,nh,nl,inp,out) bind(C,name='matching_f')
 integer(c_int),value::ni,nm,nh,nl
 type(c_ptr),intent(in)::inp(30),out(16)
 real(c_double),pointer::pi(:)
 real(c_double),pointer::yi(:)
 real(c_double),pointer::si(:)
 real(c_double),pointer::capacityi(:)
 real(c_double),pointer::gi(:)
 real(c_double),pointer::pm(:)
 real(c_double),pointer::ym(:)
 real(c_double),pointer::capacitym(:)
 real(c_double),pointer::gm(:)
 real(c_double),pointer::amat(:,:,:)
 real(c_double),pointer::dmd(:)
 real(c_double),pointer::bcf(:,:)
 real(c_double),pointer::idemand(:)
 real(c_double),pointer::bhh(:,:)
 real(c_double),pointer::cdemand(:)
 real(c_double),pointer::bcfh(:,:)
 real(c_double),pointer::hdemand(:)
 real(c_double),pointer::bgov(:,:)
 real(c_double),pointer::govd(:)
 real(c_double),pointer::bexp(:)
 real(c_double),pointer::expd(:)
 real(c_double),pointer::ncountry(:)
 real(c_double),pointer::fi(:)
 real(c_double),pointer::fh(:)
 real(c_double),pointer::wa(:,:,:,:)
 real(c_double),pointer::wcf(:,:,:)
 real(c_double),pointer::wcfh(:,:,:)
 real(c_double),pointer::whh(:,:,:)
 real(c_double),pointer::wgov(:,:,:)
 real(c_double),pointer::wexp(:,:)
 real(c_double),pointer::qi(:)
 real(c_double),pointer::qm(:)
 real(c_double),pointer::pbar(:)
 real(c_double),pointer::dm(:)
 real(c_double),pointer::pcf(:)
 real(c_double),pointer::invest(:)
 real(c_double),pointer::ph(:)
 real(c_double),pointer::cons(:)
 real(c_double),pointer::phcf(:)
 real(c_double),pointer::hinvest(:)
 real(c_double),pointer::pgov(:)
 real(c_double),pointer::cgov(:)
 real(c_double),pointer::pexp(:)
 real(c_double),pointer::cexp(:)
 real(c_double),pointer::trade(:,:,:)
 real(c_double),pointer::realtrade(:,:,:)
 real(c_double),allocatable::price(:),stock(:),capacity(:),cur(:),future(:),coef(:),d(:),dnom(:),future_d(:)
 real(c_double),allocatable::iv(:),inom(:),cd(:),cr(:),future_iv(:),future_cd(:),cfrow(:),hhrow(:),hcfrow(:),tmp(:)
 integer(c_int),allocatable::sector(:),country(:),hcountry(:),suppliers(:),available(:),buyers(:),matched(:)
 integer::g,j,k,f,h,i,c,cf,n,nhall,pass
 real(c_double)::delta,z,hhvalue,ivalue,totalpaid,partcons,partinv
 logical::future_pass
 call c_f_pointer(inp(1),pi,[ni])
 call c_f_pointer(inp(2),yi,[ni])
 call c_f_pointer(inp(3),si,[ni])
 call c_f_pointer(inp(4),capacityi,[ni])
 call c_f_pointer(inp(5),gi,[ni])
 call c_f_pointer(inp(6),pm,[nm])
 call c_f_pointer(inp(7),ym,[nm])
 call c_f_pointer(inp(8),capacitym,[nm])
 call c_f_pointer(inp(9),gm,[nm])
 call c_f_pointer(inp(10),amat,[62,62,26])
 call c_f_pointer(inp(11),dmd,[ni])
 call c_f_pointer(inp(12),bcf,[62,26])
 call c_f_pointer(inp(13),idemand,[ni])
 call c_f_pointer(inp(14),bhh,[62,26])
 call c_f_pointer(inp(15),cdemand,[nh])
 call c_f_pointer(inp(16),bcfh,[62,26])
 call c_f_pointer(inp(17),hdemand,[nh])
 call c_f_pointer(inp(18),bgov,[62,26])
 call c_f_pointer(inp(19),govd,[26])
 call c_f_pointer(inp(20),bexp,[62])
 call c_f_pointer(inp(21),expd,[nl])
 call c_f_pointer(inp(22),ncountry,[1])
 call c_f_pointer(inp(23),fi,[ni])
 call c_f_pointer(inp(24),fh,[nh])
 call c_f_pointer(inp(25),wa,[27,26,62,62])
 call c_f_pointer(inp(26),wcf,[27,26,62])
 call c_f_pointer(inp(27),wcfh,[27,26,62])
 call c_f_pointer(inp(28),whh,[27,26,62])
 call c_f_pointer(inp(29),wgov,[27,26,62])
 call c_f_pointer(inp(30),wexp,[26,62])
 call c_f_pointer(out(1),qi,[ni])
 call c_f_pointer(out(2),qm,[nm])
 call c_f_pointer(out(3),pbar,[ni])
 call c_f_pointer(out(4),dm,[ni])
 call c_f_pointer(out(5),pcf,[ni])
 call c_f_pointer(out(6),invest,[ni])
 call c_f_pointer(out(7),ph,[nh])
 call c_f_pointer(out(8),cons,[nh])
 call c_f_pointer(out(9),phcf,[nh])
 call c_f_pointer(out(10),hinvest,[nh])
 call c_f_pointer(out(11),pgov,[26])
 call c_f_pointer(out(12),cgov,[26])
 call c_f_pointer(out(13),pexp,[1])
 call c_f_pointer(out(14),cexp,[1])
 call c_f_pointer(out(15),trade,[27,27,62])
 call c_f_pointer(out(16),realtrade,[27,27,62])
 n=ni+nm;nhall=nh+nl+26
 allocate(price(n),stock(n),capacity(n),sector(n),country(n),hcountry(nhall))
 price=[pi,pm];stock=[yi+si,ym];capacity=[capacityi,capacitym]
 sector=int([gi,gm],c_int);country(1:ni)=int(fi,c_int);country(ni+1:)=27
 hcountry(1:nh)=int(fh,c_int);hcountry(nh+1:nh+nl)=27
 do j=1,26;hcountry(nh+nl+j)=j;end do
 qi=0;qm=0;pbar=0;dm=0;pcf=0;invest=0;ph=0;cons=0;phcf=0;hinvest=0;pgov=0;cgov=0;pexp=0;cexp=0;trade=0;realtrade=0
 allocate(cur(n),future(n),coef(ni),d(ni),dnom(ni),future_d(ni),iv(ni),inom(ni),cd(nhall),cr(nhall))
 allocate(future_iv(ni),future_cd(nhall),cfrow(ni),hhrow(nh),hcfrow(nh),tmp(max(nl,1)))
 do g=1,62
  allocate(suppliers(count(sector==g)));k=0
  do j=1,n;if(sector(j)==g)then;k=k+1;suppliers(k)=j;end if;end do
  do i=1,ni;coef(i)=amat(g,sector(i),country(i));end do
  d=coef*dmd;dnom=0;buyers=active(d,0.0_c_double);cur=stock;future=capacity
  available=supply_active(suppliers,cur,0.0_c_double)
  do while(size(buyers)>0.and.size(available)>0)
   call shuffle_ids(buyers);allocate(matched(size(buyers)))
   call intermediate_sample(available,price,country,buyers,sector,wa,g,matched)
   call remove_invalid(buyers,matched)
   if(size(matched)==0)then;deallocate(matched);exit;end if
   do j=1,size(buyers)
    i=buyers(j);f=matched(j)
    if(cur(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
    c=country(i);cf=country(f);delta=minval2(cur(f),d(i))
    cur(f)=cur(f)-delta;d(i)=d(i)-delta;dnom(i)=dnom(i)+delta*price(f)
    trade(c,cf,g)=trade(c,cf,g)+delta*price(f);realtrade(c,cf,g)=realtrade(c,cf,g)+delta
   end do
   deallocate(matched);call filter_buyers(buyers,d,[real(c_double)::],ni)
   available=supply_active(suppliers,cur,tol)
  end do
  if(size(buyers)>0)then
   future_d=d;buyers=active(future_d,0.0_c_double);available=supply_active(suppliers,future,0.0_c_double)
   do while(size(buyers)>0.and.size(available)>0)
    call shuffle_ids(buyers);allocate(matched(size(buyers)))
    call intermediate_sample(available,price,country,buyers,sector,wa,g,matched)
    call remove_invalid(buyers,matched)
    if(size(matched)==0)then;deallocate(matched);exit;end if
    do j=1,size(buyers)
     i=buyers(j);f=matched(j)
     if(future(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
     delta=minval2(future(f),future_d(i));cur(f)=cur(f)-delta;future(f)=future(f)-delta;future_d(i)=future_d(i)-delta
    end do
    deallocate(matched);call filter_buyers(buyers,future_d,[real(c_double)::],ni)
    available=supply_active(suppliers,future,tol)
   end do
  end if
  dm=dm+coef*dmd-d;pbar=pbar+dnom
  do i=1,ni;cfrow(i)=bcf(g,country(i));end do
  do h=1,nh;hhrow(h)=bhh(g,hcountry(h));hcfrow(h)=bcfh(g,hcountry(h));end do
  iv=cfrow*idemand;inom=0
  cd(1:nh)=hhrow*cdemand+hcfrow*hdemand
  cd(nh+1:nh+nl)=bexp(g)*expd;cd(nh+nl+1:)=bgov(g,:)*govd;cr=0
  buyers=[active(iv,0.0_c_double),ni+active(cd,0.0_c_double)]
  available=supply_active(suppliers,cur,0.0_c_double)
  do while(size(buyers)>0.and.size(available)>0)
   call shuffle_ids(buyers);allocate(matched(size(buyers)))
   call final_sample(available,price,country,buyers,hcountry,ni,nh,nl,wcf(:,:,g),whh(:,:,g),wgov(:,:,g),wexp(:,g),matched)
   call remove_invalid(buyers,matched)
   if(size(matched)==0)then;deallocate(matched);exit;end if
   do j=1,size(buyers)
    f=matched(j)
    if(cur(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
    cf=country(f);h=buyers(j)
    if(h<=ni)then
     i=h;c=country(i);delta=minval2(cur(f),iv(i));iv(i)=iv(i)-delta;inom(i)=inom(i)+delta*price(f)
    else
     h=h-ni;c=hcountry(h);delta=minval2(cur(f),cd(h)/price(f));cd(h)=cd(h)-delta*price(f);cr(h)=cr(h)+delta
    end if
    cur(f)=cur(f)-delta;trade(c,cf,g)=trade(c,cf,g)+delta*price(f);realtrade(c,cf,g)=realtrade(c,cf,g)+delta
   end do
   deallocate(matched);call filter_buyers(buyers,iv,cd,ni);available=supply_active(suppliers,cur,tol)
  end do
  if(size(buyers)>0)then
   future_iv=iv;future_cd=cd;buyers=[active(future_iv,0.0_c_double),ni+active(future_cd,0.0_c_double)]
   available=supply_active(suppliers,future,0.0_c_double)
   do while(size(buyers)>0.and.size(available)>0)
    call shuffle_ids(buyers);allocate(matched(size(buyers)))
    call final_sample(available,price,country,buyers,hcountry,ni,nh,nl,wcf(:,:,g),whh(:,:,g),wgov(:,:,g),wexp(:,g),matched)
    call remove_invalid(buyers,matched)
    if(size(matched)==0)then;deallocate(matched);exit;end if
    do j=1,size(buyers)
     f=matched(j)
     if(future(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
     h=buyers(j)
     if(h<=ni)then
      i=h;delta=minval2(future(f),future_iv(i));future_iv(i)=future_iv(i)-delta
     else
      h=h-ni;delta=minval2(future(f),future_cd(h)/price(f));future_cd(h)=future_cd(h)-delta*price(f)
     end if
     cur(f)=cur(f)-delta;future(f)=future(f)-delta
    end do
    deallocate(matched);call filter_buyers(buyers,future_iv,future_cd,ni);available=supply_active(suppliers,future,tol)
   end do
  end if
  qi=stock(1:ni)-cur(1:ni)+qi;qm=stock(ni+1:)-cur(ni+1:)+qm
  invest=invest+cfrow*idemand-iv;pcf=pcf+inom
  do h=1,nh
   hhvalue=hhrow(h)*cdemand(h);ivalue=hcfrow(h)*hdemand(h)
   cons(h)=hhvalue-maxzero(cd(h)-ivalue)+cons(h)
   hinvest(h)=maxzero(ivalue-cd(h))+hinvest(h)
   ! Preserve each expression's parenthesisation from the MATLAB source.
   partcons=cdemand(h)*hhrow(h)-maxzero(cd(h)-hcfrow(h)*hdemand(h))
   totalpaid=cdemand(h)*hhrow(h)+hcfrow(h)*hdemand(h)-cd(h)
   ph(h)=ph(h)+maxzero((cr(h)*partcons)/totalpaid)
   partinv=maxzero(hcfrow(h)*hdemand(h)-cd(h))
   phcf(h)=phcf(h)+maxzero((cr(h)*partinv)/totalpaid)
  end do
  cgov=bgov(g,:)*govd-cd(nh+nl+1:)+cgov
  tmp(:nl)=bexp(g)*expd
  cexp(1)=(block_sum(tmp(:nl))-block_sum(cd(nh+1:nh+nl)))+cexp(1)
  pgov=pgov+cr(nh+nl+1:);pexp(1)=pexp(1)+block_sum(cr(nh+1:nh+nl))
  deallocate(suppliers)
 end do
 do i=1,ni
  if(invest(i)>0)pcf(i)=pcf(i)/invest(i)
  if(dm(i)>0)pbar(i)=pbar(i)/dm(i)
 end do
 ph=cons/ph;phcf=hinvest/phcf;pgov=cgov/pgov;pexp=cexp/pexp
end subroutine
end module
