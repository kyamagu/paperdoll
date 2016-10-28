function value = exist(varargin)
%EXISTS Check if an entry exists.
%
%    flag = bdb.exist(key)
%    flag = bdb.exist(id, key, ...)
%
% The function checks if an entry with the given key exists in the specified
% database session. When the id is omitted, the default session is used.
%
% The key must be an ordinary object.
%
% ## Options
%
% _Transaction_ [0]
%
% Transaction ID. When 0, it looks for an active transaction and use it if any.
%
% _ReadCommitted_ [false]
%
% Configure a transactional get operation to have degree 2 isolation (the read
% is not repeatable).
%
% _ReadUncommitted_ [false]
%
% Configure a transactional get operation to have degree 1 isolation, reading
% modified but not yet committed data.
%
% _RMW_ [false]
%
% Acquire write locks instead of read locks when doing the read, if locking is
% configured.
%
% See also bdb.get
  value = mex_function_(mfilename, varargin{:});
end
