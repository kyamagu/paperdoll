function abort(varargin)
%ABORT Abort a transaction.
%
%    bdb.abort()
%    bdb.abort(transaction_id)
%
% The function aborts a transaction. If transaction_id is skipped, the default
% transaction is aborted.
%
% See also bdb.begin bdb.commit
  mex_function_(mfilename, varargin{:});
end
