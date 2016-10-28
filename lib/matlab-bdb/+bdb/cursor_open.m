function cursor_id = cursor_open(varargin)
%CURSOR_OPEN Open a new cursor.
%
%    cursor_id = bdb.cursor_open()
%    cursor_id = bdb.cursor_open(db_id)
%
% The function creates a new cursor.
%
% See also bdb.cursor_close
  cursor_id = mex_function_(mfilename, varargin{:});
end
