"""Reapply the validated native optimisations after MATLAB R2025b codegen."""
from pathlib import Path
import argparse,shutil
p=argparse.ArgumentParser();p.add_argument('generated',type=Path);a=p.parse_args();root=Path(__file__).resolve().parent
for n in ['stable_uniform_order.c','stable_uniform_order.h']:shutil.copyfile(root/'c'/n,a.generated/n)
f=a.generated/'randperm.c';s=f.read_text();anchor='  if (p->size[1] != 0) {'
if '#include "stable_uniform_order.h"' not in s:
 assert s.count(anchor)==1,'Unexpected generated randperm structure'
 s='#include "stable_uniform_order.h"\n'+s.replace(anchor,'  if (loop_ub >= 4096 && stable_uniform_order(p_data, idx_data, loop_ub)) {\n    /* Same draws and stable order. */\n  } else '+anchor.strip());f.write_text(s)
f=a.generated/'bsearch.c';s=f.read_text();pos=s.index('int32_T b_bsearch(');f.write_text(s[:pos]+(root/'c/search_function.c.txt').read_text())
