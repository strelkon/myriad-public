"""Prepare an isolated Fortran MEX experiment from locally generated C sources.
Never point --output at a production model directory.
"""
from pathlib import Path
import argparse
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--generated", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()
source = args.generated.resolve()
target = args.output.resolve()
if target == source or source in target.parents:
    parser.error("Output directory must be outside the generated-source tree.")
if target.exists():
    parser.error("Output directory must not already exist; use a fresh experiment directory.")
for name in ("search_and_matching.h", "search_and_matching_emxutil.c", "interface/_coder_search_and_matching_api.c"):
    if not (source / name).is_file():
        parser.error(f"Missing generated input: {name}")
root = Path(__file__).resolve().parent
shutil.copytree(source, target / "candidate" / "c_src")
subprocess.run([sys.executable, str(root / "make_gateway.py"), str(target / "candidate" / "c_src")], check=True)
for name in ("matching.f90", "test_fortran.m"):
    shutil.copyfile(root / name, target / name)
print(f"Prepared {target}. Review test_fortran.m cluster paths before submitting.")
