function flag = cursor_next(cursor_id)
%CURSOR_NEXT Move forward a cursor.
%
%    flag = bdb.cursor_next(cursor_id)
%
% The function advances a cursor. When it reaches the end of the table, it
% returns false. Otherwise it returns true.
%
% See also bdb.cursor_prev bdb.cursor_get
  flag = mex_function_(mfilename, cursor_id);
end
