function commit(varargin)
%COMMIT Commit a transaction.
%
%    bdb.commit(...)
%    bdb.commit(transaction_id, ...)
%
% The function opens a specified environment. When transaction_id is skipped,
% the function commits an active transaction.
%
% ## Options
%
% _TxnNosync_ [false]
%
% Do not synchronously flush the log.
%
% _TxnSync_ [false]
%
% Synchronously flush the log.
%
% _TxnWriteNosync_ [false]
%
% Write but do not synchronously flush the log on transaction commit.
%
% See also bdb.begin bdb.abort bdb.env_open bdb.env_close
  mex_function_(mfilename, varargin{:});
end
