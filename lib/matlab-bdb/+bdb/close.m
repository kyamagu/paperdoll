function close(varargin)
%CLOSE Close the database.
%
%    bdb.close
%    bdb.close(id, ...)
%
% The function closes the database session of the specified id. When the id is
% omitted, the default session is closed.
%
% ## Options
% 
% _Nosync_ [false]
% 
% Do not flush cached information to disk.
%
% See also bdb.open
  mex_function_(mfilename, varargin{:});
end
