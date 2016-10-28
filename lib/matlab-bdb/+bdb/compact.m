function compact_data = compact(varargin)
%COMPACT Free unused blocks and shrink the database.
%
%    compact_data = bdb.compact()
%    compact_data = bdb.compact(id, ...)
%
% The function apply compact operation to the specified database session. When
% the id is omitted, the default session is used. The compact_data is a struct
% containing statistics during the operation.
%
% ## Options
%
% _Transaction_ [0]
%
% Transaction ID. When 0, it looks for an active transaction and use it if any.
% 
% _FreelistOnly_ [false]
% 
% Do no page compaction, only returning pages to the filesystem that are
% already free and at the end of the file.
%
% _FreeSpace_ [true]
%
% Return pages to the filesystem when possible.
%
% _Fillpercent_ [0]
%
% If non-zero, this provides the goal for filling pages, specified as a
% percentage between 1 and 100.
%
% _Pages_ [0]
%
% If non-zero, the call will return after the specified number of pages have
% been freed, or no more pages can be freed.
%
% _Timeout_ [0]
%
% If non-zero, and no Transaction parameter was specified, this parameter
% identifies the lock timeout used for implicit transactions, in microseconds.
%
% See also bdb.open
  compact_data = mex_function_(mfilename, varargin{:});
end
