function results = keys(varargin)
%KEYS Return a list of keys in the database.
%
%    results = bdb.keys()
%    results = bdb.keys(id)
%
% The function retrieves all keys from the specified database session. When
% the id is omitted, the default session is used.
%
% The results are returned as a cell array.
%
% See also bdb.values
  results = mex_function_(mfilename, varargin{:});
end
