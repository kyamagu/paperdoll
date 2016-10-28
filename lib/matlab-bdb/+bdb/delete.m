function delete(varargin)
%DELETE Delete an entry for a key.
%
%    bdb.delete(key)
%    bdb.delete(id, key, ...)
%
% The function deletes an entry with the given key in the specified
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
% _Consume_ [false]
%
% If the database is of type DB_QUEUE then this flag may be set to force the
% head of the queue to move to the first non-deleted item in the queue.
%
% _Multiple_ [false]
%
% Delete multiple data items using keys from the buffer to which the key
% parameter refers.
%
% _MultipleKey_ [false]
%
% Delete multiple data items using keys and data from the buffer to which the
% key parameter refers.
%
% See also bdb.put bdb.get
  mex_function_(mfilename, varargin{:});
end
