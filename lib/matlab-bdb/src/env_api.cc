/// Berkeley DB environment mex interface.
///
/// Kota Yamaguchi 2012 <kyamagu@cs.stonybrook.edu>

#include "libbdbmex.h"
#include "mex/arguments.h"
#include "mex/function.h"
#include "mex/mxarray.h"

using bdbmex::Environment;
using bdbmex::Transaction;
using mex::CheckInputArguments;
using mex::CheckOutputArguments;
using mex::MxArray;
using mex::Session;
using mex::VariableInputArguments;

namespace {

MEX_FUNCTION(env_open) (int nlhs,
                        mxArray *plhs[],
                        int nrhs,
                        const mxArray *prhs[]) {
  CheckInputArguments(1, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("InitCDB",        false);
  options.set("InitLock",       true);
  options.set("InitLog",        true);
  options.set("InitMPool",      true);
  options.set("InitRep",        false);
  options.set("InitTXN",        true);
  options.set("Recover",        false);
  options.set("RecoverFatal",   false);
  options.set("UseEnviron",     false);
  options.set("UseEnvironRoot", false);
  options.set("Create",         true);
  options.set("Lockdown",       false);
  options.set("Failchk",        false);
  options.set("Private",        false);
  options.set("Register",       false);
  options.set("SystemMem",      false);
  options.set("Thread",         false);
  options.set("Mode",           0);

  string home = MxArray(prhs[0]).toString();
  options.update(prhs + 1, prhs + nrhs);
  uint32_t flags =
      (options["InitCDB"].toBool()        ? DB_INIT_CDB : 0) |
      (options["InitLock"].toBool()       ? DB_INIT_LOCK : 0) |
      (options["InitLog"].toBool()        ? DB_INIT_LOG : 0) |
      (options["InitMPool"].toBool()      ? DB_INIT_MPOOL : 0) |
      (options["InitRep"].toBool()        ? DB_INIT_REP : 0) |
      (options["InitTXN"].toBool()        ? DB_INIT_TXN : 0) |
      (options["Recover"].toBool()        ? DB_RECOVER : 0) |
      (options["RecoverFatal"].toBool()   ? DB_RECOVER_FATAL : 0) |
      (options["UseEnviron"].toBool()     ? DB_USE_ENVIRON : 0) |
      (options["UseEnvironRoot"].toBool() ? DB_USE_ENVIRON_ROOT : 0) |
      (options["Create"].toBool()         ? DB_CREATE : 0) |
      (options["Lockdown"].toBool()       ? DB_LOCKDOWN : 0) |
      (options["Failchk"].toBool()        ? DB_FAILCHK : 0) |
      (options["Private"].toBool()        ? DB_PRIVATE : 0) |
      (options["Register"].toBool()       ? DB_REGISTER : 0) |
      (options["SystemMem"].toBool()      ? DB_SYSTEM_MEM : 0) |
      (options["Thread"].toBool()         ? DB_THREAD : 0);
  int mode = options["Mode"].toInt();

  Environment* environment = NULL;
  int environment_id = Session<Environment>::create(&environment);
  if (!environment->open(home, flags, mode)) {
    const char* error_message = environment->error_message();
    Session<Environment>::destroy(environment_id);
    ERROR("Failed to open an environment: %s", error_message);
  }
  plhs[0] = MxArray(environment_id).getMutable();
}

MEX_FUNCTION(env_close) (int nlhs,
                         mxArray *plhs[],
                         int nrhs,
                         const mxArray *prhs[]) {
  CheckInputArguments(0, 1024, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  VariableInputArguments options;
  options.set("Forcesync", false);

  int environment_id = (nrhs == 0 || !MxArray(prhs[0]).isNumeric()) ?
      0 : MxArray(prhs[0]).toInt();
  options.update(prhs, prhs + nrhs);
  uint32_t flags = (options["Forcesync"].toBool() ? DB_FORCESYNC : 0);

  Environment* environment = Session<Environment>::get(environment_id);
  if (!environment)
    ERROR("No open environment found.");
  environment->close(flags);
  Session<Environment>::destroy(environment_id);
}

MEX_FUNCTION(begin) (int nlhs,
                         mxArray *plhs[],
                         int nrhs,
                         const mxArray *prhs[]) {
  CheckInputArguments(0, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("Environment",     0);
  options.set("Parent",          0);
  options.set("ReadCommitted",   false);
  options.set("ReadUncommitted", false);
  options.set("TxnBulk",         true);
  options.set("TxnNosync",       false);
  options.set("TxnNowait",       false);
  options.set("TxnSnapshot",     false);
  options.set("TxnSync",         false);
  options.set("TxnWait",         false);
  options.set("TxnWriteNosync",  false);
  options.update(prhs, prhs + nrhs);
  Environment* environment = Session<Environment>::get(
      (nrhs == 0 || !MxArray(prhs[0]).isNumeric()) ?
      0 : MxArray(prhs[0]).toInt());
  if (!environment)
    ERROR("No open environment found.");
  Transaction* parent = (options["Parent"].toInt() == 0) ?
      NULL : Session<Transaction>::get(options["Parent"].toInt());
  uint32_t flags =
      (options["ReadCommitted"].toBool()   ? DB_READ_COMMITTED : 0) |
      (options["ReadUncommitted"].toBool() ? DB_READ_UNCOMMITTED : 0) |
      (options["TxnBulk"].toBool()         ? DB_TXN_BULK : 0) |
      (options["TxnNosync"].toBool()       ? DB_TXN_NOSYNC : 0) |
      (options["TxnNowait"].toBool()       ? DB_TXN_NOWAIT : 0) |
      (options["TxnSnapshot"].toBool()     ? DB_TXN_SNAPSHOT : 0) |
      (options["TxnSync"].toBool()         ? DB_TXN_SYNC : 0) |
      (options["TxnWait"].toBool()         ? DB_TXN_WAIT : 0) |
      (options["TxnWriteNosync"].toBool()  ? DB_TXN_WRITE_NOSYNC : 0);
  Transaction* transaction = NULL;
  int transaction_id = Session<Transaction>::create(&transaction);
  if (!environment->txn_begin(flags, parent, transaction)) {
    const char* error_message = environment->error_message();
    Session<Transaction>::destroy(transaction_id);
    ERROR("Unable to create a new transaction: %s", error_message);
  }
  plhs[0] = MxArray(transaction_id).getMutable();
}

MEX_FUNCTION(commit) (int nlhs,
                      mxArray *plhs[],
                      int nrhs,
                      const mxArray *prhs[]) {
  CheckInputArguments(0, 1024, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  VariableInputArguments options;
  options.set("TxnNosync",       false);
  options.set("TxnSync",         false);
  options.set("TxnWriteNosync",  false);
  options.update(prhs, prhs + nrhs);
  int transaction_id = (nrhs == 0 || !MxArray(prhs[0]).isNumeric()) ?
      0 : MxArray(prhs[0]).toInt();
  Transaction* transaction = Session<Transaction>::get(transaction_id);
  if (!transaction)
    ERROR("No active transaction found.");
  uint32_t flags =
      (options["TxnNosync"].toBool()       ? DB_TXN_NOSYNC : 0) |
      (options["TxnSync"].toBool()         ? DB_TXN_SYNC : 0) |
      (options["TxnWriteNosync"].toBool()  ? DB_TXN_WRITE_NOSYNC : 0);
  if (!transaction->commit(flags))
    ERROR("Unable to commit: %s", transaction->error_message());
  Session<Transaction>::destroy(transaction_id);
}

MEX_FUNCTION(abort) (int nlhs,
                     mxArray *plhs[],
                     int nrhs,
                     const mxArray *prhs[]) {
  CheckInputArguments(0, 1, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  int transaction_id = (nrhs == 0) ? 0 : MxArray(prhs[0]).toInt();
  Transaction* transaction = Session<Transaction>::get(transaction_id);
  if (!transaction)
    ERROR("No active transaction found.");
  if (!transaction->abort())
    ERROR("Unable to abort: %s", transaction->error_message());
  Session<Transaction>::destroy(transaction_id);
}

} // namespace