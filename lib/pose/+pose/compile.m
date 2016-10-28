function compile
%COMPILE Build mex functions.
  cwd = pwd;
  cd(fullfile(fileparts(mfilename('fullpath')),'private'));
  % =============
  % Detection code
  % use one of the following depending on your setup
  % 1 is fastest, 3 is slowest 
  % 1) multithreaded convolution using blas
  % mex -O fconvblas.cc -lmwblas -o fconv
  % 2) mulththreaded convolution without blas
  % mex -O fconvMT.cc -o fconv 
  % 3) basic convolution, very compatible
  mex -O fconv.cc -output fconv

  mex -O resize.cc
  mex -O reduce.cc
  mex -O dt.cc
  mex -O shiftdt.cc
  mex -O features.cc

  % =============
  % Learning code
  mex -O -largeArrayDims qp_one_sparse.cc
  mex -O -largeArrayDims score.cc
  mex -O -largeArrayDims lincomb.cc
  cd(cwd);
end
