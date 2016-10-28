function startup
%STARTUP Initializes environment.

  % set up path
  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root, 'lib'));
  for d = dir(fullfile(root, 'lib'))'
    if d.isdir && d.name(1) ~= '.'
      addpath(fullfile(root, 'lib', d.name));
    end
  end
  addpath(fullfile(root, 'tasks'));

  % initialize
  run(fullfile('lib','vlfeat-0.9.16','toolbox','vl_setup'));

end
