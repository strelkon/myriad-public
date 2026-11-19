function build_reviewer_fortran
root = fileparts(mfilename('fullpath'));
gcc = '/apps/software/GCCcore/12.3.0';
obj = fullfile(root, 'matching.o');
cmd = sprintf(['%s/bin/gfortran -O2 -fPIC -frecursive -ffp-contract=off ' ...
    '-fno-unsafe-math-optimizations -ffree-line-length-none -J%s -c %s -o %s'], ...
    gcc, root, fullfile(root,'matching.f90'), obj);
[code, msg] = system(cmd);
assert(code == 0, 'Fortran compilation failed: %s', msg);
lib = fullfile(gcc, 'lib64');
mex('-R2017b', '-outdir', fullfile(root,'model'), '-output','search_and_matching_review_mex', ...
    fullfile(root,'reviewer_gateway.c'), obj, ['-L' lib],'-lgfortran', ...
    ['LDFLAGS=$LDFLAGS -Wl,-rpath,' lib]);
end
