function flag = cursor_prev(cursor_id)
%CURSOR_PREV Move back a cursor.
%
%    flag = bdb.cursor_prev(cursor_id)
%
% The function moves a cursor back to the previous record. If it reaches the
% end of the table, it returns false. Otherwise it returns true.
%
% See also bdb.cursor_next bdb.cursor_get
  flag = mex_function_(mfilename, cursor_id);
end
