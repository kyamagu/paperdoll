function session_ids = sessions()
%VALUES Return a list of open session ids.
%
%    session_ids = bdb.sessions()
%
% The function retrieves a list of ids for the currently opening database.
%
% See also bdb.open
  session_ids = mex_function_(mfilename);
end

