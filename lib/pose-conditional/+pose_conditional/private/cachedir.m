function dirname = cachedir(dirname)
%CACHEDIR Return cache directory

  persistent dirname_;
  if nargin == 1 && ischar(dirname)
    dirname_ = dirname;
  end
  if isempty(dirname_)
    dirname_ = ['tmp', filesep];
  end
  if dirname_(end) ~= filesep
    dirname_ = [dirname_, filesep];
  end
  if ~exist(dirname_, 'dir')
    fprintf('%s: creating %s\n', mfilename, dirname_);
    mkdir(dirname_);
  end
  dirname = dirname_;

end

