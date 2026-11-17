"""Create a thin MEX ABI adapter from a locally generated licensed C header.
Generated MathWorks code is deliberately neither embedded nor committed here.
"""
from pathlib import Path
import argparse,re
p=argparse.ArgumentParser();p.add_argument('generated',type=Path);a=p.parse_args()
h=(a.generated/'search_and_matching.h').read_text();decl=re.search(r'void search_and_matching\([\s\S]*?\);',h).group(0)[:-1]
inputs=['P_i','Y_i','S_i','S_i_','G_i','P_m','Y_m','Y_m_','G_m','a_sg','DM_d_i','b_CF_g','I_d_i','b_HH_g','C_d_h','b_CFH_g','I_d_h','c_G_g','C_d_j','c_E_g','C_d_l','F','F_i','F_h','s_a_ffsg','s_CF_ffg','s_CFH_ffg','s_HH_ffg','s_G_ffg','s_E_fg']
outputs=['Q_d_i','Q_d_m','P_bar_i','DM_i','P_CF_i','I_i','P_bar_h','C_h','P_bar_CF_h','I_h','P_j','C_j','P_l','C_l','bilateral_trade_g','bilateral_trade_real_g']
emx_in={'P_i','Y_i','S_i','S_i_','G_i','P_m','Y_m','Y_m_','G_m','DM_d_i','I_d_i','C_d_h','I_d_h','C_d_l','F_i','F_h'}
emx_out=set(outputs)-{'P_j','C_j','P_l','C_l'}
s='''#include "search_and_matching.h"
#include "search_and_matching_emxutil.h"
#include "mwmathutil.h"
#include <limits.h>
extern void matching_f(int ni,int nm,int nh,int nl,const double *const inp[],double *const out[]);
void myriad_uniform(double *x,int n){emlrtRandu(x,n);}
double myriad_power(double x){return muDoubleScalarPower(x,-2.0);}
static const emlrtRTEInfo allocation_info={1,1,"Fortran research adapter","matching.f90"};
static void row(const emlrtStack *sp,emxArray_real_T *x,int n){int old=x->size[0]*x->size[1];x->size[0]=1;x->size[1]=n;emxEnsureCapacity_real_T(sp,x,old,&allocation_info);}
static void trade_array(const emlrtStack *sp,emxArray_real_T*x){int old=x->size[0]*x->size[1]*x->size[2];x->size[0]=27;x->size[1]=27;x->size[2]=62;emxEnsureCapacity_real_T(sp,x,old,&allocation_info);}
static void ids(const double*x,int n,int upper){for(int j=0;j<n;j++)if(!isfinite(x[j])||x[j]!=floor(x[j])||x[j]<1||x[j]>upper)mexErrMsgIdAndTxt("myriad:FortranInput","Invalid country or sector ID.");}
'''+decl+''' {
(void)SD;
int ni=P_i->size[1],nm=P_m->size[1],nh=C_d_h->size[1],nl=C_d_l->size[1];
if(F!=26 || ni>INT_MAX-nm || nh>INT_MAX-ni-26 || nl>INT_MAX-ni-nh-26)mexErrMsgIdAndTxt("myriad:FortranInput","Invalid model dimensions.");
'''
for name in emx_in:
 size='ni' if name in ['P_i','Y_i','S_i','S_i_','G_i','DM_d_i','I_d_i','F_i'] else 'nm' if name in ['P_m','Y_m','Y_m_','G_m'] else 'nl' if name=='C_d_l' else 'nh'
 s+=f'if({name}->size[0]!=1||{name}->size[1]!={size})mexErrMsgIdAndTxt("myriad:FortranInput","Mismatched {name} shape.");\n'
s+='ids(G_i->data,ni,62);ids(G_m->data,nm,62);ids(F_i->data,ni,26);ids(F_h->data,nh,26);\n'
for name in outputs:
 if name not in emx_out:continue
 if name.startswith('bilateral'):s+=f'trade_array(sp,{name});\n'
 else:s+=f'row(sp,{name},'+('nm' if name=='Q_d_m' else 'nh' if name in ['P_bar_h','C_h','P_bar_CF_h','I_h'] else 'ni')+');\n'
s+='const double *inp[30]={'+','.join(n+'->data' if n in emx_in else '&F' if n=='F' else n for n in inputs)+'};\n'
s+='double *out[16]={'+','.join(n+'->data' if n in emx_out else n for n in outputs)+'};\nmatching_f(ni,nm,nh,nl,inp,out);\n}\n'
(a.generated/'search_and_matching.c').write_text(s)
