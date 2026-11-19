module myriad_matching_fortran
use iso_c_binding
use, intrinsic :: ieee_arithmetic
implicit none
private
public :: matching_f
real(c_double), parameter :: tol=epsilon(1.0_c_double)
! Adapted from the macroMIP Fortran kernel for the manuscript's reviewer branch.
interface
 subroutine uniform_f(x,n) bind(C,name='myriad_uniform')
 import c_double,c_int
 real(c_double) :: x(*)
 integer(c_int),value :: n
 end subroutine
 subroutine sample_f(suppliers,weights,n,k,draws) bind(C,name='myriad_sample')
 import c_double,c_int
 integer(c_int),intent(in) :: suppliers(*)
 real(c_double),intent(in) :: weights(*)
 integer(c_int),value :: n,k
 integer(c_int),intent(out) :: draws(*)
 end subroutine
 function sum_f(x,n) result(y) bind(C,name='myriad_sum')
 import c_double,c_int
 real(c_double),intent(in) :: x(*)
 integer(c_int),value :: n
 real(c_double) :: y
 end function
 function power_f(x,gamma) result(y) bind(C,name='myriad_power')
 import c_double
 real(c_double),value :: x,gamma
 real(c_double) :: y
 end function
end interface
contains
function block_sum(x) result(y)
 real(c_double),intent(in) :: x(:)
 real(c_double) :: y
 integer :: i
 y=0
 do i=1,size(x)
  y=y+x(i)
 end do
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
 integer(c_int64_t),allocatable::keys(:),destination(:),temp(:)
 integer(c_int),allocatable::values(:),next_values(:),temp_values(:)
 integer::n,j,shift,bucket,counts(0:255),offset(0:255),running,slot
 n=size(ids);if(n==0)return
 allocate(u(n))
 call uniform_f(u,int(n,c_int))
 keys=transfer(u,0_c_int64_t,n)
 deallocate(u)
 allocate(destination(n),next_values(n))
 values=ids
 do shift=0,56,8
  counts=0
  do j=1,n
   bucket=int(ibits(keys(j),shift,8));counts(bucket)=counts(bucket)+1
  end do
  if(maxval(counts)==n)cycle
  running=1
  do bucket=0,255
   offset(bucket)=running;running=running+counts(bucket)
  end do
  do j=1,n
   bucket=int(ibits(keys(j),shift,8));slot=offset(bucket)
   destination(slot)=keys(j);next_values(slot)=values(j);offset(bucket)=slot+1
  end do
  call move_alloc(keys,temp)
  call move_alloc(destination,keys)
  call move_alloc(temp,destination)
  call move_alloc(values,temp_values)
  call move_alloc(next_values,values)
  call move_alloc(temp_values,next_values)
 end do
 ids=values
end subroutine
subroutine weighted_sample(suppliers,weights,k,draws)
 integer(c_int),intent(in) :: suppliers(:)
 real(c_double),intent(in) :: weights(:)
 integer,intent(in) :: k
 integer(c_int),intent(out) :: draws(k)
 if(size(suppliers)==1)then
  draws=suppliers(1)
 else
  call sample_f(suppliers,weights,int(size(suppliers),c_int),int(k,c_int),draws)
 end if
end subroutine
subroutine grouped_sample(suppliers,prices,countries,ids,gids,ngroups,table,gamma,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),ids(:),gids(:)
 integer,intent(in)::ngroups
 real(c_double),intent(in)::prices(:),table(:,:),gamma
 integer(c_int),intent(out)::matched(size(ids))
 integer,allocatable::counts(:),offset(:),next(:),positions(:)
 integer(c_int),allocatable::draws(:)
 real(c_double),allocatable::s(:),w(:),pg(:)
 real(c_double)::sc(27),ss,ws
 integer::n,m,j,g,idx,c,start,k
 n=size(suppliers);m=size(ids);matched=0;if(m==0)return
 allocate(counts(ngroups),offset(ngroups),next(ngroups),positions(m),s(n),w(n),pg(n))
 counts=0;sc=0.0_c_double
 do j=1,n;c=countries(suppliers(j));sc(c)=sc(c)+1.0_c_double;pg(j)=power_f(prices(suppliers(j)),gamma);end do
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
subroutine intermediate_sample(suppliers,prices,countries,buyers,sector,weights,g,gamma,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),buyers(:),sector(:)
 real(c_double),intent(in)::prices(:),weights(27,26,62,62),gamma
 integer,intent(in)::g
 integer(c_int),intent(out)::matched(size(buyers))
 integer,allocatable::gid(:)
 real(c_double)::table(27,1612)
 integer::j,c,s
 allocate(gid(size(buyers)))
 do j=1,size(buyers);gid(j)=sector(buyers(j))+62*(countries(buyers(j))-1);end do
 do c=1,26;do s=1,62;table(:,s+62*(c-1))=weights(:,c,g,s);end do;end do
 call grouped_sample(suppliers,prices,countries,buyers,gid,1612,table,gamma,matched)
end subroutine
subroutine final_sample(suppliers,prices,countries,buyers,hcountries,ni,nh,nl,cf,hh,gov,ex,gamma,matched)
 integer(c_int),intent(in)::suppliers(:),countries(:),buyers(:),hcountries(:)
 integer,intent(in)::ni,nh,nl
 real(c_double),intent(in)::prices(:),cf(27,26),hh(27,26),gov(27,26),ex(26),gamma
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
  case(1);call grouped_sample(suppliers,prices,countries,sub,gid,26,cf,gamma,draws)
  case(2);call grouped_sample(suppliers,prices,countries,sub,gid,26,hh,gamma,draws)
  case(3);call grouped_sample(suppliers,prices,countries,sub,gid,26,gov,gamma,draws)
  case(4)
   exports(1:26,1)=ex;exports(27,1)=0.0_c_double
   call grouped_sample(suppliers,prices,countries,sub,gid,1,exports,gamma,draws)
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
subroutine matching_f(ni,nm,nh,nl,inp,out,max_rounds,gamma) bind(C,name='matching_f')
 integer(c_int),value::ni,nm,nh,nl
 type(c_ptr),intent(in)::inp(31),out(22)
 real(c_double),value :: max_rounds,gamma
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
 real(c_double),pointer :: fraction(:),intermediate(:,:),investment(:,:),final(:,:),reconstruction(:,:),sales_i(:),sales_m(:)
 real(c_double),allocatable::price(:),stock(:),capacity(:),cur(:),future(:),future_orders(:),coef(:),d(:),dnom(:),future_d(:)
 real(c_double),allocatable::iv(:),inom(:),cd(:),cr(:),future_iv(:),future_cd(:),cfrow(:),hhrow(:),hcfrow(:),tmp(:)
 integer(c_int),allocatable::sector(:),country(:),hcountry(:),suppliers(:),available(:),buyers(:),matched(:)
 integer::g,j,k,f,h,i,c,cf,n,nhall,rounds
 real(c_double)::delta,z,hhvalue,ivalue,totalpaid,partcons,partinv
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
 call c_f_pointer(inp(31),fraction,[ni])
 call c_f_pointer(out(17),intermediate,[27,27])
 call c_f_pointer(out(18),investment,[27,27])
 call c_f_pointer(out(19),final,[27,27])
 call c_f_pointer(out(20),reconstruction,[27,27])
 call c_f_pointer(out(21),sales_i,[ni])
 call c_f_pointer(out(22),sales_m,[nm])
 intermediate=0;investment=0;final=0;reconstruction=0;sales_i=0;sales_m=0
 n=ni+nm;nhall=nh+nl+26
 allocate(price(n),stock(n),capacity(n),sector(n),country(n),hcountry(nhall))
 price=[pi,pm];stock=[yi+si,ym];capacity=[capacityi,capacitym]
 sector=int([gi,gm],c_int);country(1:ni)=int(fi,c_int);country(ni+1:)=27
 hcountry(1:nh)=int(fh,c_int);hcountry(nh+1:nh+nl)=27
 do j=1,26;hcountry(nh+nl+j)=j;end do
 qi=0;qm=0;pbar=0;dm=0;pcf=0;invest=0;ph=0;cons=0;phcf=0;hinvest=0;pgov=0;cgov=0;pexp=0;cexp=0;trade=0;realtrade=0
 allocate(cur(n),future(n),future_orders(n),coef(ni),d(ni),dnom(ni),future_d(ni),iv(ni),inom(ni),cd(nhall),cr(nhall))
 allocate(future_iv(ni),future_cd(nhall),cfrow(ni),hhrow(nh),hcfrow(nh),tmp(max(nl,1)))
 do g=1,62
  allocate(suppliers(count(sector==g)));k=0
  do j=1,n;if(sector(j)==g)then;k=k+1;suppliers(k)=j;end if;end do
  do i=1,ni;coef(i)=amat(g,sector(i),country(i));end do
  d=coef*dmd;dnom=0;buyers=active(d,0.0_c_double);cur=stock;future=capacity;future_orders=0
  available=supply_active(suppliers,cur,0.0_c_double)
  rounds=0
  do while(size(buyers)>0.and.size(available)>0.and.rounds<max_rounds)
   rounds=rounds+1
   call shuffle_ids(buyers);allocate(matched(size(buyers)))
   call intermediate_sample(available,price,country,buyers,sector,wa,g,gamma,matched)
   call remove_invalid(buyers,matched)
   if(size(matched)==0)then;deallocate(matched);exit;end if
   do j=1,size(buyers)
    i=buyers(j);f=matched(j)
    if(cur(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
    c=country(i);cf=country(f);delta=minval2(cur(f),d(i))
    cur(f)=cur(f)-delta;d(i)=d(i)-delta;dnom(i)=dnom(i)+delta*price(f)
    trade(c,cf,g)=trade(c,cf,g)+delta*price(f);realtrade(c,cf,g)=realtrade(c,cf,g)+delta
    intermediate(c,cf)=intermediate(c,cf)+delta
   end do
   deallocate(matched);call filter_buyers(buyers,d,[real(c_double)::],ni)
   available=supply_active(suppliers,cur,tol)
  end do
  if(size(buyers)>0)then
   future_d=d;buyers=active(future_d,0.0_c_double);available=supply_active(suppliers,future,0.0_c_double)
   do while(size(buyers)>0.and.size(available)>0)
    call shuffle_ids(buyers);allocate(matched(size(buyers)))
    call intermediate_sample(available,price,country,buyers,sector,wa,g,gamma,matched)
    call remove_invalid(buyers,matched)
    if(size(matched)==0)then;deallocate(matched);exit;end if
    do j=1,size(buyers)
     i=buyers(j);f=matched(j)
     if(future(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
     delta=minval2(future(f),future_d(i));future_orders(f)=future_orders(f)+delta;future(f)=future(f)-delta;future_d(i)=future_d(i)-delta
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
  rounds=0
  do while(size(buyers)>0.and.size(available)>0.and.rounds<max_rounds)
   rounds=rounds+1
   call shuffle_ids(buyers);allocate(matched(size(buyers)))
   call final_sample(available,price,country,buyers,hcountry,ni,nh,nl,wcf(:,:,g),whh(:,:,g),wgov(:,:,g),wexp(:,g),gamma,matched)
   call remove_invalid(buyers,matched)
   if(size(matched)==0)then;deallocate(matched);exit;end if
   do j=1,size(buyers)
    f=matched(j)
    if(cur(f)==0.and.price(f)>0.and.ieee_is_finite(price(f)))cycle
    cf=country(f);h=buyers(j)
    if(h<=ni)then
     i=h;c=country(i);delta=minval2(cur(f),iv(i));iv(i)=iv(i)-delta;inom(i)=inom(i)+delta*price(f)
     investment(c,cf)=investment(c,cf)+delta
     reconstruction(c,cf)=reconstruction(c,cf)+delta*fraction(i)
    else
     h=h-ni;c=hcountry(h);delta=minval2(cur(f),cd(h)/price(f));cd(h)=cd(h)-delta*price(f);cr(h)=cr(h)+delta
     final(c,cf)=final(c,cf)+delta
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
    call final_sample(available,price,country,buyers,hcountry,ni,nh,nl,wcf(:,:,g),whh(:,:,g),wgov(:,:,g),wexp(:,g),gamma,matched)
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
     future_orders(f)=future_orders(f)+delta;future(f)=future(f)-delta
    end do
    deallocate(matched);call filter_buyers(buyers,future_iv,future_cd,ni);available=supply_active(suppliers,future,tol)
   end do
  end if
  sales_i=sales_i+(stock(1:ni)-cur(1:ni))
  sales_m=sales_m+(stock(ni+1:)-cur(ni+1:))
  qi=stock(1:ni)-cur(1:ni)+future_orders(1:ni)+qi
  qm=stock(ni+1:)-cur(ni+1:)+future_orders(ni+1:)+qm
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
  cexp(1)=(sum_f(tmp(:nl),nl)-sum_f(cd(nh+1:nh+nl),nl))+cexp(1)
  pgov=pgov+cr(nh+nl+1:);pexp(1)=pexp(1)+sum_f(cr(nh+1:nh+nl),nl)
  deallocate(suppliers)
 end do
 do i=1,ni
  if(invest(i)>0)pcf(i)=pcf(i)/invest(i)
  if(dm(i)>0)pbar(i)=pbar(i)/dm(i)
 end do
 ph=cons/ph;phcf=hinvest/phcf;pgov=cgov/pgov;pexp=cexp/pexp
end subroutine
end module
