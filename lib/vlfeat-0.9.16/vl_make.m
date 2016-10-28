function vl_make
%VL_MAKE

  cwd = pwd;
  cd(fileparts(mfilename('fullpath')));
  cmd = sprintf('make ARCH=%s MEX=%s', computer('arch'), fullfile(matlabroot,'bin','mex'));
  system(cmd);
  cd(cwd);
end
