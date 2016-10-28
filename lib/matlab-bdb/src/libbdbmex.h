/// Berkeley DB matlab driver library.
///
/// Kota Yamaguchi 2012 <kyamagu@cs.stonybrook.edu>

#ifndef __LIBBDBMEX_H__
#define __LIBBDBMEX_H__

#include <db.h>
#include <map>
#include <mex.h>
#include <string>
#include <vector>
#include "mex/session.h"

using namespace std;

/// Alias for the mex error function.
#define ERROR(...) mexErrMsgIdAndTxt("bdb:error", __VA_ARGS__)

namespace bdbmex {

/// Database record consisting of (key, value) pair of DBT struct.
class Record {
public:
  /// Construct a new record for cursor operation.
  Record();
  /// Construct a new record for retrieval.
  Record(const mxArray* key);
  /// Construct a new record for store.
  Record(const mxArray* key, const mxArray* value);
  virtual ~Record();
  /// Get key.
  void get_key(mxArray** key);
  /// Get value.
  void get_value(mxArray** value);
  /// Mutable key.
  DBT* key() { return &key_; }
  /// Mutable value.
  DBT* value() { return &value_; }

private:
  /// Reset the record.
  void reset(u_int32_t key_flags, u_int32_t value_flags);
  /// Set key.
  void set_key(const mxArray* key);
  /// Set value.
  void set_value(const mxArray* value);
  /// Serialize an mxArray.
  void serialize_mxarray(const mxArray* value, vector<uint8_t>* binary);
  /// Deserialize an mxArray.
  void deserialize_mxarray(const vector<uint8_t>& binary, mxArray** value);
  /// Serialize and compress an mxArray.
  void compress_mxarray(const mxArray* value, vector<uint8_t>* binary);
  /// Decompress and deserialize mxArray.
  void decompress_mxarray(const vector<uint8_t>& binary, mxArray** value);

  /// Key or the record.
  DBT key_;
  /// Value of the record.
  DBT value_;
  /// Temporary buffer for reference.
  vector<uint8_t> key_buffer_;
  /// Temporary buffer for reference.
  vector<uint8_t> value_buffer_;
};

/// Database cursor.
class Cursor {
public:
  /// Create an empty cursor.
  Cursor() : cursor_(NULL), code_(0) {}
  /// Destructor.
  virtual ~Cursor();
  /// Open a new cursor.
  int open(DB* database_);
  /// Return the last error code.
  int error_code() const { return code_; }
  /// Return the last error message.
  const char* error_message() const { return db_strerror(code_); }
  /// Go to the next record.
  int next();
  /// Go to the previous record.
  int prev();
  /// Get the record.
  Record* get() { return &record_; }

private:
  /// Last return code.
  int code_;
  /// Temporary record holder.
  Record record_;
  /// Cursor pointer.
  DBC* cursor_;
};

/// Transaction.
class Transaction {
public:
  /// Destructor.
  virtual ~Transaction() {}
  /// Reset the transaction.
  void reset(DB_TXN* txnid) { transaction_ = txnid; }
  /// Return if the status is okay.
  bool ok() const { return code_ == 0; }
  /// Return the last error message.
  const char* error_message() const { return db_strerror(code_); }
  /// Get the transaction.
  DB_TXN* get() { return transaction_; }
  /// Abort the transaction.
  bool abort();
  /// Commit the transaction.
  bool commit(uint32_t flags);

private:
  /// Last return code.
  int code_;
  /// Transaction C object.
  DB_TXN* transaction_;
};

/// Database environment.
class Environment {
public:
  /// Create an empty environment.
  Environment();
  /// Descructor.
  virtual ~Environment();
  /// Open an environment.
  bool open(const string& home, uint32_t flags, int mode);
  /// Close the environment.
  bool close(uint32_t flags);
  /// Return if the status is okay.
  bool ok() const { return code_ == 0; }
  /// Return the last error message.
  const char* error_message() const { return db_strerror(code_); }
  /// Get mutable pointer.
  DB_ENV* get() { return environment_; }
  /// Transaction.
  bool txn_begin(uint32_t flags,
                 Transaction* parent,
                 Transaction* transaction);

private:
  /// Last return code.
  int code_;
  /// Environment C object.
  DB_ENV* environment_;
};

/// Database connection.
class Database {
public:
  /// Create an empty database connection.
  Database();
  /// Destructor.
  virtual ~Database();
  /// Open a connection.
  bool open(const string& filename,
            const string& name,
            DBTYPE type,
            uint32_t flags,
            int mode,
            Environment* environment,
            Transaction* transaction);
  /// Close the connection.
  bool close(uint32_t flags);
  /// Return the last error code.
  int error_code() const;
  /// Return the last error message.
  const char* error_message() const;
  /// Return if the status is okay.
  bool ok() const { return code_ == 0; }
  /// Get an entry.
  bool get(const mxArray* key,
           uint32_t flags,
           mxArray** value,
           Transaction* transaction);
  /// Put an entry.
  bool put(const mxArray* key,
           const mxArray* value,
           uint32_t flags,
           Transaction* transaction);
  /// Delete an entry.
  bool del(const mxArray* key,
           uint32_t flags,
           Transaction* transaction);
  /// Check if the entry exists.
  bool exists(const mxArray* key,
              uint32_t flags,
              mxArray** value,
              Transaction* transaction);
  /// Return database statistics.
  bool stat(uint32_t flags, mxArray** output, Transaction* transaction);
  /// Dump keys in the database.
  bool keys(mxArray** output);
  /// Dump values in the database.
  bool values(mxArray** output);
  /// Shrink the database file.
  bool compact(uint32_t flags,
               DB_COMPACT* compact_data,
               Transaction* transaction);
  /// Create a new cursor.
  bool cursor(Cursor* cursor);

private:

  /// Last return code.
  int code_;
  /// DB C object.
  DB* database_;
};

} // namespace bdbmex

namespace mex {

// Template instanciations.
extern template class Session<bdbmex::Cursor>;
extern template class Session<bdbmex::Database>;
extern template class Session<bdbmex::Environment>;
extern template class Session<bdbmex::Transaction>;

}

#endif // __LIBBDBMEX_H__
