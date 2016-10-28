function id = env_open(home_dir, varargin)
%ENV_OPEN Open a Berkeley DB environment.
%
%    environment_id = bdb.env_open(home, ...)
%
% The function opens a specified environment.
%
% ## Options
%
% _InitCDB_ [false]
% 
% Initialize locking for the Berkeley DB Concurrent Data Store product.
%
% _InitLock_ [true]
%
% Initialize the locking subsystem.
%
% _InitLog_ [true]
%
% Initialize the logging subsystem.
%
% _InitMPool_ [true]
%
% Initialize the shared memory buffer pool subsystem.
%
% _InitRep_ [false]
%
% Initialize the replication subsystem.
%
% _InitTXN_ [true]
%
% Initialize the transaction subsystem.
%
% _Recover_ [false]
%
% Run normal recovery on this environment before opening it for normal use.
%
% _RecoverFatal_ [false]
% 
% Run catastrophic recovery on this environment before opening it for normal
% use.
%
% _UseEnviron_ [false]
%
% Environment information will be used in file naming for all users only if
% the UseEnviron flag is set.
%
% _UseEnvironRoot_ [false]
%
% Environment information will be used in file naming only for users with
% appropriate permissions.
%
% _Create_ [true]
%
% Cause Berkeley DB subsystems to create any underlying files, as necessary.
%
% _Lockdown_ [false]
%
% Lock shared Berkeley DB environment files and memory-mapped databases into
% memory.
%
% _Failchk_ [false]
%
% Internally call the DB_ENV->failchk() method as part of opening the
% environment.
%
% _Private_ [false]
%
% Allocate region memory from the heap instead of from memory backed by the
% filesystem or system shared memory.
%
% _Register_ [false]
%
% Check to see if recovery needs to be performed before opening the database
% environment.
%
% _SystemMem_ [false]
%
% Allocate region memory from system shared memory instead of from heap memory
% or memory backed by the filesystem.
%
% _Thread_ [false]
%
% Cause the DB_ENV handle returned by DB_ENV->open() to be free-threaded.
%
% _Mode_ [0]
% 
% UNIX file mode.
%
% See also bdb.close_environment bdb.open
  id = mex_function_(mfilename, home_dir, varargin{:});
end
