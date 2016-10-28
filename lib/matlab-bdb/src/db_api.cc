/// Berkeley DB database mex interface.
///
/// Kota Yamaguchi 2012 <kyamagu@cs.stonybrook.edu>

#include <cstring>
#include "libbdbmex.h"
#include "mex/arguments.h"
#include "mex/function.h"
#include "mex/mxarray.h"

using bdbmex::Database;
using bdbmex::Environment;
using bdbmex::Transaction;
using mex::CheckInputArguments;
using mex::CheckOutputArguments;
using mex::MxArray;
using mex::Session;
using mex::VariableInputArguments;

namespace {

/// Get type enum from name.
DBTYPE get_dbtype(const string& name) {
  map<string, DBTYPE> db_types;
  db_types["btree"] = DB_BTREE;
  db_types["hash"] = DB_HASH;
  db_types["queue"] = DB_QUEUE;
  db_types["recno"] = DB_RECNO;
  db_types["unknown"] = DB_UNKNOWN;
  map<string, DBTYPE>::const_iterator it = db_types.find(name);
  if (it == db_types.end())
    ERROR("Invalid type: %s", name.c_str());
  return it->second;
}

MEX_FUNCTION(open) (int nlhs,
                    mxArray *plhs[],
                    int nrhs,
                    const mxArray *prhs[]) {
  CheckInputArguments(1, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  string filename(MxArray(prhs[0]).toString());
  VariableInputArguments options;
  options.set("Environment",      0);
  options.set("Transaction",      0);
  options.set("Name",             string(""));
  options.set("Type",             string("btree"));
  options.set("AutoCommit",       true);
  options.set("Create",           true);
  options.set("Excl",             false);
  options.set("Multiversion",     false);
  options.set("Nommap",           false);
  options.set("Rdonly",           false);
  options.set("ReadUncommitted",  false);
  options.set("Thread",           false);
  options.set("Truncate",         false);
  options.set("Mode",             0);
  options.update(prhs + 1, prhs + nrhs);
  Environment* environment = Session<Environment>::get(
      options["Environment"].toInt());
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  DBTYPE type = get_dbtype(options["Type"].toString());
  string name = options["Name"].toString();
  uint32_t flags =
      ((options["AutoCommit"].toBool() && environment) ? DB_AUTO_COMMIT : 0) |
      (options["Create"].toBool()          ? DB_CREATE : 0) |
      (options["Excl"].toBool()            ? DB_EXCL : 0) |
      (options["Multiversion"].toBool()    ? DB_MULTIVERSION : 0) |
      (options["Nommap"].toBool()          ? DB_NOMMAP : 0) |
      (options["Rdonly"].toBool()          ? DB_RDONLY : 0) |
      (options["ReadUncommitted"].toBool() ? DB_READ_UNCOMMITTED : 0) |
      (options["Thread"].toBool()          ? DB_THREAD : 0) |
      (options["Truncate"].toBool()        ? DB_TRUNCATE : 0);
  int mode = options["Mode"].toInt();
  Database* database = NULL;
  int database_id = Session<Database>::create(&database);
  if (!database->open(filename,
                      name,
                      type,
                      flags,
                      mode,
                      environment,
                      transaction)) {
    const char* error_message = database->error_message();
    Session<Database>::destroy(database_id);
    ERROR("Failed to open a database at %s: %s",
          filename.c_str(),
          error_message);
  }
  plhs[0] = MxArray(database_id).getMutable();
}

MEX_FUNCTION(close) (int nlhs,
                     mxArray *plhs[],
                     int nrhs,
                     const mxArray *prhs[]) {
  CheckInputArguments(0, 3, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  int index = 0;
  int database_id = (nrhs > 0 && MxArray(prhs[index]).isNumeric()) ?
      MxArray(prhs[index++]).toInt() : 0;
  VariableInputArguments options;
  options.set("Nosync", false);
  options.update(prhs + index, prhs + nrhs);
  uint32_t flags = (options["Nosync"].toBool() ? DB_NOSYNC : 0);
  Database* database = Session<Database>::get(database_id);
  if (!database)
    ERROR("No open database found.");
  database->close(flags);
  Session<Database>::destroy(database_id);
}

MEX_FUNCTION(get) (int nlhs,
                   mxArray *plhs[],
                   int nrhs,
                   const mxArray *prhs[]) {
  CheckInputArguments(1, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("Transaction",     0);
  options.set("Consume",         false);
  options.set("ConsumeWait",     false);
  options.set("GetBoth",         false);
  options.set("SetRecno",        false);
  options.set("IgnoreLease",     false);
  options.set("Multiple",        false);
  options.set("ReadCommitted",   false);
  options.set("ReadUncommitted", false);
  options.set("RMW",             false);
  Database* database = NULL;
  MxArray key;
  if (nrhs == 1) {
    database = Session<Database>::get(0);
    key.reset(prhs[0]);
  }
  else {
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
    key.reset(prhs[1]);
    options.update(prhs + 2, prhs + nrhs);
  }
  if (!database)
    ERROR("No open database found.");
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  uint32_t flags =
      (options["Consume"].toBool()         ? DB_CONSUME : 0) |
      (options["ConsumeWait"].toBool()     ? DB_CONSUME_WAIT : 0) |
      (options["GetBoth"].toBool()         ? DB_GET_BOTH : 0) |
      (options["SetRecno"].toBool()        ? DB_SET_RECNO : 0) |
      (options["IgnoreLease"].toBool()     ? DB_IGNORE_LEASE : 0) |
      (options["Multiple"].toBool()        ? DB_MULTIPLE : 0) |
      (options["ReadCommitted"].toBool()   ? DB_READ_COMMITTED : 0) |
      (options["ReadUncommitted"].toBool() ? DB_READ_UNCOMMITTED : 0) |
      (options["RMW"].toBool()             ? DB_RMW : 0);
  plhs[0] = NULL; // TODO: Set value for GetBoth option.
  if (!database->get(key.get(), flags, &plhs[0], transaction))
    ERROR("Failed to get an entry: %s", database->error_message());
}

MEX_FUNCTION(put) (int nlhs,
                   mxArray *plhs[],
                   int nrhs,
                   const mxArray *prhs[]) {
  CheckInputArguments(2, 1024, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  VariableInputArguments options;
  options.set("Transaction",  0);
  options.set("Append",       false);
  options.set("Nodupdata",    false);
  options.set("Nooverwrite",  false);
  options.set("Multiple",     false);
  options.set("MultipleKey",  false);
  options.set("OverwriteDup", false);
  Database* database = NULL;
  MxArray key, value;
  if (nrhs == 2) {
    database = Session<Database>::get(0);
    key.reset(prhs[0]);
    value.reset(prhs[1]);
  }
  else {
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
    key.reset(prhs[1]);
    value.reset(prhs[2]);
    options.update(prhs + 3, prhs + nrhs);
  }
  if (!database)
    ERROR("No open database found.");
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  uint32_t flags =
      (options["Append"].toBool()       ? DB_APPEND : 0) |
      (options["Nodupdata"].toBool()    ? DB_NODUPDATA : 0) |
      (options["Nooverwrite"].toBool()  ? DB_NOOVERWRITE : 0) |
      (options["Multiple"].toBool()     ? DB_MULTIPLE : 0) |
      (options["MultipleKey"].toBool()  ? DB_MULTIPLE_KEY : 0) |
      (options["OverwriteDup"].toBool() ? DB_OVERWRITE_DUP : 0);
  if (!database->put(key.get(), value.get(), flags, transaction))
    ERROR("Failed to put an entry: %s", database->error_message());
}

MEX_FUNCTION(delete) (int nlhs,
                      mxArray *plhs[],
                      int nrhs,
                      const mxArray *prhs[]) {
  CheckInputArguments(1, 2, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  VariableInputArguments options;
  options.set("Transaction",  0);
  options.set("Consume",         false);
  options.set("Multiple",        false);
  options.set("MultipleKey",  false);
  Database* database = NULL;
  MxArray key;
  if (nrhs == 1) {
    database = Session<Database>::get(0);
    key.reset(prhs[0]);
  }
  else {
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
    key.reset(prhs[1]);
    options.update(prhs + 2, prhs + nrhs);
  }
  if (!database)
    ERROR("No open database found.");
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  uint32_t flags =
      (options["Consume"].toBool()       ? DB_CONSUME : 0) |
      (options["Multiple"].toBool()     ? DB_MULTIPLE : 0) |
      (options["MultipleKey"].toBool()  ? DB_MULTIPLE_KEY : 0);
  if (!database->del(key.get(), flags, transaction))
    ERROR("Failed to delete an entry: %s", database->error_message());
}

MEX_FUNCTION(exist) (int nlhs,
                     mxArray *plhs[],
                     int nrhs,
                     const mxArray *prhs[]) {
  CheckInputArguments(1, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("Transaction",     0);
  options.set("ReadCommitted",   false);
  options.set("ReadUncommitted", false);
  options.set("RMW",             false);
  Database* database = NULL;
  MxArray key;
  if (nrhs == 1) {
    database = Session<Database>::get(0);
    key.reset(prhs[0]);
  }
  else {
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
    key.reset(prhs[1]);
    options.update(prhs + 2, prhs + nrhs);
  }
  if (!database)
    ERROR("No open database found.");
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  uint32_t flags =
      (options["ReadCommitted"].toBool()   ? DB_READ_COMMITTED : 0) |
      (options["ReadUncommitted"].toBool() ? DB_READ_UNCOMMITTED : 0) |
      (options["RMW"].toBool()             ? DB_RMW : 0);
  if (!database->exists(key.get(), flags, &plhs[0], transaction))
    ERROR("Failed to query a key: %s", database->error_message());
}

MEX_FUNCTION(stat) (int nlhs,
                    mxArray *plhs[],
                    int nrhs,
                    const mxArray *prhs[]) {
  CheckInputArguments(0, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("Transaction",     0);
  options.set("FastStat",        true);
  options.set("ReadCommitted",   false);
  options.set("ReadUncommitted", false);
  Database* database = Session<Database>::get(
      (nrhs == 0 || !MxArray(prhs[0]).isNumeric()) ?
          0 : MxArray(prhs[0]).toInt());
  options.update(prhs, prhs + nrhs);
  if (!database)
    ERROR("No open database found.");
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  uint32_t flags =
      (options["FastStat"].toBool()        ? DB_FAST_STAT : 0) |
      (options["ReadCommitted"].toBool()   ? DB_READ_COMMITTED : 0) |
      (options["ReadUncommitted"].toBool() ? DB_READ_UNCOMMITTED : 0);
  if (!database->stat(flags, &plhs[0], transaction))
    ERROR("Failed to query stat: %s", database->error_message());
}

MEX_FUNCTION(keys) (int nlhs,
                    mxArray *plhs[],
                    int nrhs,
                    const mxArray *prhs[]) {
  CheckInputArguments(0, 1, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  Database* database = NULL;
  if (nrhs == 0)
    database = Session<Database>::get(0);
  else
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
  if (!database)
    ERROR("No open database found.");
  if (!database->keys(&plhs[0]))
    ERROR("Failed to query keys: %s", database->error_message());
}

MEX_FUNCTION(values) (int nlhs,
                      mxArray *plhs[],
                      int nrhs,
                      const mxArray *prhs[]) {
  CheckInputArguments(0, 1, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  Database* database = NULL;
  if (nrhs == 0)
    database = Session<Database>::get(0);
  else
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
  if (!database)
    ERROR("No open database found.");
  if (!database->values(&plhs[0]))
    ERROR("Failed to query values: %s", database->error_message());
}

MEX_FUNCTION(compact) (int nlhs,
                       mxArray *plhs[],
                       int nrhs,
                       const mxArray *prhs[]) {
  CheckInputArguments(0, 1024, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  VariableInputArguments options;
  options.set("Transaction",  0);
  options.set("FreelistOnly", false);
  options.set("FreeSpace",    true);
  options.set("Fillpercent",  0);
  options.set("Pages",        0);
  options.set("Timeout",      0);
  Database* database = NULL;
  if (nrhs == 0)
    database = Session<Database>::get(0);
  else {
    database = Session<Database>::get(MxArray(prhs[0]).toInt());
    options.update(prhs + 1, prhs + nrhs);
  }
  if (!database)
    ERROR("No open database found.");
  uint32_t flags =
      (options["FreelistOnly"].toBool() ? DB_FREELIST_ONLY : 0) |
      (options["FreeSpace"].toBool()    ? DB_FREE_SPACE : 0);
  Transaction* transaction = Session<Transaction>::get(
      options["Transaction"].toInt());
  DB_COMPACT compact_data;
  memset(&compact_data, 0, sizeof(DB_COMPACT));
  compact_data.compact_fillpercent = options["Fillpercent"].toInt();
  compact_data.compact_pages = options["Pages"].toInt();
  compact_data.compact_timeout = options["Timeout"].toInt();
  if (!database->compact(flags, &compact_data, transaction))
    ERROR("Failed to compact: %s", database->error_message());
  if (nlhs > 0) {
    const char* kCompactFields[] = {
        "deadlock",
        "pages_examine",
        "empty_buckets",
        "pages_free",
        "levels",
        "pages_truncated"};
    MxArray output = MxArray::Struct(6, kCompactFields);
    output.set(kCompactFields[0], double(compact_data.compact_deadlock));
    output.set(kCompactFields[1], double(compact_data.compact_pages_examine));
    output.set(kCompactFields[2], double(compact_data.compact_empty_buckets));
    output.set(kCompactFields[3], double(compact_data.compact_pages_free));
    output.set(kCompactFields[4], double(compact_data.compact_levels));
    output.set(kCompactFields[5], double(compact_data.compact_pages_truncated));
    plhs[0] = output.getMutable();
  }
}

MEX_FUNCTION(sessions) (int nlhs,
                        mxArray *plhs[],
                        int nrhs,
                        const mxArray *prhs[]) {
  CheckInputArguments(0, 0, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  const map<int, Database>& instances =
      Session<Database>::get_const_instances();
  vector<int> session_ids;
  session_ids.reserve(instances.size());
  for (map<int, Database>::const_iterator it = instances.begin();
       it != instances.end(); ++it)
    session_ids.push_back(it->first);
  plhs[0] = MxArray(session_ids).getMutable();
}

} // namespace
