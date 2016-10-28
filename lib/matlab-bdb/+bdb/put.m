function put(varargin)
%PUT Store a key-value pair.
%
%    bdb.put(key, value)
%    bdb.put(id, key, value, ...)
%
% The function stores a value for the given key in the specified database
% session. When the id is omitted, the default session is used.
%
% The key and the value must be an ordinary object. When there is an existing
% entry for the given key, the entry will be overwritten.
%
% ## Options
%
% _Transaction_ [0]
%
% Transaction ID. When 0, it looks for an active transaction and use it if any.
%
% _Append_ [false]
%
% Append the key/data pair to the end of the database.
%
% _Nodupdata_ [false]
%
% In the case of the Btree and Hash access methods, enter the new key/data pair
% only if it does not already appear in the database.
%
% _Nooverwrite_ [false]
%
% Enter the new key/data pair only if the key does not already appear in the
% database.
%
% _Multiple_ [false]
%
% Put multiple data items using keys from the buffer to which the key parameter
% refers and data values from the buffer to which the data parameter refers.
%
% _MultipleKey_ [false]
%
% Put multiple data items using keys and data from the buffer to which the key
% parameter refers.
%
% _OverwriteDup_ [false]
%
% Ignore duplicate records when overwriting records in a database configured
% for sorted duplicates.
%
% See also bdb.get bdb.delete
  mex_function_(mfilename, varargin{:});
end
