function make(varargin)
%MAKE Compile mex files
%
%    pf.make
%
  root_dir = fileparts(fileparts(mfilename('fullpath')));
  cwd = cd(root_dir);
  cmd = sprintf('mex -outdir %s -output segment segment-mex.cpp', fullfile(root_dir, '+pf'));
  disp(cmd);
  eval(cmd);
  cd(cwd);
end
