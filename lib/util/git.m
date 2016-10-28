function git(varargin)
%GIT

  args = sprintf(' %s', varargin{:});
  system(sprintf('git%s', args));

end

