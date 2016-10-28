function env_close(varargin)
%ENV_CLOSE Close the environment.
%
%    bdb.env_close(...)
%    bdb.env_close(environment_id, ...)
%
% The function closes an environment. When environment_id is skipped, the
% default opening environment is closed.
%
% ## Options
%
% _ForceSync_ [false]
%
% When closing each database handle internally, synchronize the database.
%
% See also bdb.open
  mex_function_(mfilename, varargin{:});
end
