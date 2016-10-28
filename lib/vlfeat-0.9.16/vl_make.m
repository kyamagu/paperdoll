function vl_make
%VL_MAKE

  cwd = pwd;
  cd(fileparts(mfilename('fullpath')));
  cmd = sprintf('make ARCH=%s MEX=%s MATLAB_PATH=%s', computer('arch'), ...
                fullfile(matlabroot,'bin','mex'), matlabroot);
  system(cmd);
  cd(cwd);
end
