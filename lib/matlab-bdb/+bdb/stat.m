function result = stat(varargin)
%STAT Get a statistics of the database.
%
%    result = bdb.stat(...)
%    result = bdb.stat(id, ...)
%
% The function retrieves statistics of the specified database session. When
% the id is omitted, the default session is used.
%
% The result is a struct array.
%
% ## Options
%
% _Transaction_ [0]
%
% Transaction ID. When 0, it looks for an active transaction and use it if any.
%
% _FastStat_ [true]
%
% Return only the values which do not require traversal of the database.
%
% _ReadCommitted_ [false]
%
% Database items read during a transactional call will have degree 2 isolation.
%
% _ReadUncommitted_ [false]
%
% Database items read during a transactional call will have degree 1 isolation,
% including modified but not yet committed data.
%
% See also bdb.open bdb.close
  result = mex_function_(mfilename, varargin{:});
end
