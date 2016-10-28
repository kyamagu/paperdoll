function [key, value] = cursor_get(cursor_id)
%CURSOR_GET Retrieve a key and a value from a cursor.
%
%    [key, value] = bdb.cursor_get(cursor_id)
%
% The function retrieves a key and a value from a cursor.
%
% See also bdb.cursor_open bdb.cursor_close bdb.cursor_next bdb.cursor_prev
  [key, value] = mex_function_(mfilename, cursor_id);
end
