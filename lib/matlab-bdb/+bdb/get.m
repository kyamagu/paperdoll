function value = get(varargin)
%GET Retrieve a value given key.
%
%    value = bdb.get(key)
%    value = bdb.get(id, key, ...)
%
% The function retrieves an entry with the given key in the specified
% database session. The first form is used when retrieving a record from the
% default database with default option. The key must be an ordinary object.
%
% ## Options
%
% _Transaction_ [0]
%
% Transaction ID. When 0, it looks for an active transaction and use it if any.
%
% _Consume_ [false]
%
% Return the record number and data from the available record closest to the 
% head of the queue, and delete the record.
%
% _ConsumeWait_ [false]
%
% Same as _Consume_, except that if the Queue database is empty, the thread of
% control will wait until there is data in the queue before returning.
%
% _GetBoth_ [false]
%
% Retrieve the key/data pair only if both the key and data match the arguments.
%
% _SetRecno_ [false]
%
% Retrieve the specified numbered key/data pair from a database. Upon return,
% both the key and data items will have been filled in.
%
% _IgnoreLease_ [false]
%
% Return the data item irrespective of the state of master leases.
%
% _Multiple_ [false]
%
% Return multiple data items in the buffer to which the data parameter refers.
%
% _ReadCommitted_ [false]
%
% Configure a transactional get operation to have degree 2 isolation (the read
% is not repeatable).
%
% _ReadUncommitted_ [false]
%
% Configure a transactional get operation to have degree 1 isolation, reading
% modified but not yet committed data.
%
% _RMW_ [false]
%
% Acquire write locks instead of read locks when doing the read, if locking is
% configured.
%
% See also bdb.put bdb.delete
  value = mex_function_(mfilename, varargin{:});
end
