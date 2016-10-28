function transaction_id = begin(varargin)
%BEGIN Begin a transaction
%
%    transaction_id = bdb.begin(...)
%
% The function starts a new transaction. The returned transaction_id must be
% closed either by bdb.commit() or bdb.abort().
%
% ## Options
%
% _Environment_ [0]
% 
% Environment id. By default, the function looks for an active environment.
%
% _Parent_ [0]
%
% If the parent parameter is non-zero, the new transaction will be a nested
% transaction, with the transaction indicated by parent as its parent.
%
% _ReadCommitted_ [false]
%
% This transaction will have degree 2 isolation.
%
% _ReadUncommitted_ [false]
%
% This transaction will have degree 1 isolation.
%
% _TxnBulk_ [true]
%
% Enable transactional bulk insert optimization.
%
% _TxnNosync_ [false]
%
% Do not synchronously flush the log when this transaction commits or prepares.
%
% _TxnNowait_ [false]
%
% If a lock is unavailable for any Berkeley DB operation performed in the
% context of this transaction, cause the operation to return DB_LOCK_DEADLOCK
% (or DB_LOCK_NOTGRANTED if the database environment has been configured using
% the DB_TIME_NOTGRANTED flag).
%
% _TxnSnapshot_ [false]
%
% This transaction will execute with snapshot isolation.
%
% _TxnSync_ [false]
%
% Synchronously flush the log when this transaction commits or prepares.
%
% _TxnWait_ [false]
%
% If a lock is unavailable for any Berkeley DB operation performed in the
% context of this transaction, wait for the lock.
%
% _TxnWriteNosync_ [false]
%
% Write, but do not synchronously flush, the log when this transaction commits.
%
% See also bdb.commit bdb.abort bdb.env_open bdb.env_close
  transaction_id = mex_function_(mfilename, varargin{:});
end
