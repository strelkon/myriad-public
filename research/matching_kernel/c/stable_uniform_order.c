#include "stable_uniform_order.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
typedef struct {uint64_t key; int32_t index;} entry;
int stable_uniform_order(const double *values, int32_t *indices, int n) {
  entry *a=malloc((size_t)n*sizeof(entry)),*b=malloc((size_t)n*sizeof(entry));
  if(!a||!b){free(a);free(b);return 0;}
  uint64_t different=0,first=0;
  for(int i=0;i<n;i++) {
    /* Positive finite IEEE doubles sort in unsigned bit order. Canonicalize
       signed zeros for stable numeric tie handling. Fallback for other values. */
    if(!isfinite(values[i]) || values[i]<0.0){free(a);free(b);return 0;}
    uint64_t key=0;if(values[i]!=0.0)memcpy(&key,values+i,sizeof(key));
    a[i].key=key;a[i].index=i+1;
    if(i==0)first=key;different|=key^first;
  }
  for(unsigned shift=0;shift<64;shift+=8) {
    if(((different>>shift)&255)==0)continue;
    size_t offsets[256]={0};
    for(int i=0;i<n;i++)offsets[(a[i].key>>shift)&255]++;
    size_t total=0;
    for(int k=0;k<256;k++){size_t count=offsets[k];offsets[k]=total;total+=count;}
    for(int i=0;i<n;i++){unsigned k=(a[i].key>>shift)&255;b[offsets[k]++]=a[i];}
    entry *tmp=a;a=b;b=tmp;
  }
  for(int i=0;i<n;i++)indices[i]=a[i].index;
  free(a);free(b);return 1;
}
