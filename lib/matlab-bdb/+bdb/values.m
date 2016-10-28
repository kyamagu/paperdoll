function results = values(varargin)
%VALUES Return a list of values in the database.
%
%    results = bdb.values()
%    results = bdb.values(id)
%
% The function retrieves all values from the specified database session. When
% the id is omitted, the default session is used.
%
% The results are returned as a cell array.
%
% See also bdb.keys
  results = mex_function_(mfilename, varargin{:});
end

