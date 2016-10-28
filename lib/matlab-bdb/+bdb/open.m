function id = open(filename, varargin)
%OPEN Open a Berkeley DB database.
%
%    id = bdb.open(filename, ...)
%
% The function opens the database session for the given db file. When empty
% filename is give, the database will be in-memory.
%
% ## Options
%
% _Environment_ [0]
% 
% Environment in which to open the database. Use bdb.env_open().
%
% _Transaction_ [0]
%
% Transaction in which to open the database.
%
% _Name_ ['']
%
% Name of the database in a file.
%
% _Type_ ['btree']
%
% Data structure for the database. One of 'btree', 'hash', 'heap', 'queue',
% 'recno', or 'unknown'.
%
% _AutoCommit_ [true]
%
% Enclose the operation within a transaction.
%
% _Create_ [true]
%
% Create the database if not existing.
%
% _Excl_ [false]
%
% Return an error if the database already exists.
%
% _Multiversion_ [false]
%
% Open the database with support for multiversion concurrency control.
%
% _Nommap_ [false]
%
% Do not map this database into process memory.
%
% _Rdonly_ [false]
%
% Open for read-only.
%
% _ReadUncommited_ [false]
%
% Support transactional read operations with degree 1 isolation.
%
% _Thread_ [false]
%
% Support threading.
%
% _Truncate_ [false]
% 
% Physically truncate the underlying file, discarding all previous databases it
% might have held.
%
% _Mode_ [0]
%
% UNIX file mode to create the file. When it is 0, it follows the system
% default configuration.
%
% See also bdb.close bdb.put bdb.get bdb.delete bdb.stat bdb.keys
% bdb.values bdb.env_open
  id = mex_function_(mfilename, filename, varargin{:});
end
