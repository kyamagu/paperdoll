/// Berkeley DB matlab driver library.
///
/// Kota Yamaguchi 2012 <kyamagu@cs.stonybrook.edu>

#include "libbdbmex.h"
#include "mex/mxarray.h"
#include <cstring>
#ifdef ENABLE_ZLIB
#include <zlib.h>
#endif

using mex::MxArray;

// MX_API_VER has unfortunately not changed between R2013b and R2014a,
// so we use the new MATRIX_DLL_EXPORT_SYM as an ugly hack instead
//
#if defined(__cplusplus) && defined(MATRIX_DLL_EXPORT_SYM)
  #define EXTERN_C extern
  namespace matrix{
    namespace detail{
      namespace noninlined{
        namespace mx_array_api{
#endif

EXTERN_C mxArray* mxSerialize(mxArray const *);
EXTERN_C mxArray* mxDeserialize(const void *, size_t);

#if defined(__cplusplus) && defined(MATRIX_DLL_EXPORT_SYM)
        }
      }
    }
  }
  using namespace matrix::detail::noninlined::mx_array_api;
#endif

namespace mex {

template class Session<bdbmex::Cursor>;
template class Session<bdbmex::Database>;
template class Session<bdbmex::Environment>;
template class Session<bdbmex::Transaction>;

}

namespace bdbmex {

Record::Record() {
  reset(DB_DBT_REALLOC, DB_DBT_REALLOC);
}

Record::Record(const mxArray* key) {
  reset(DB_DBT_USERMEM, DB_DBT_REALLOC);
  set_key(key);
}

Record::Record(const mxArray* key, const mxArray* value) {
  reset(DB_DBT_USERMEM, DB_DBT_USERMEM);
  set_key(key);
  set_value(value);
}

Record::~Record() {
  if (key_.flags == DB_DBT_REALLOC && key_.data)
    free(key_.data);
  if (value_.flags == DB_DBT_REALLOC && value_.data)
    free(value_.data);
}

void Record::reset(u_int32_t key_flags, u_int32_t value_flags) {
  memset(&key_, 0, sizeof(DBT));
  memset(&value_, 0, sizeof(DBT));
  key_.flags = key_flags;
  value_.flags = value_flags;
}

void Record::set_key(const mxArray* key) {
  serialize_mxarray(key, &key_buffer_);
  key_.data = &key_buffer_[0];
  key_.size = key_buffer_.size();
}

void Record::set_value(const mxArray* value) {
  compress_mxarray(value, &value_buffer_);
  value_.data = &value_buffer_[0];
  value_.size = value_buffer_.size();
}

void Record::get_key(mxArray** key) {
  const uint8_t* key_data = static_cast<const uint8_t*>(key_.data);
  key_buffer_.assign(key_data, key_data + key_.size);
  deserialize_mxarray(key_buffer_, key);
}

void Record::get_value(mxArray** value) {
  const uint8_t* value_data = static_cast<const uint8_t*>(value_.data);
  value_buffer_.assign(value_data, value_data + value_.size);
  decompress_mxarray(value_buffer_, value);
}

void Record::serialize_mxarray(const mxArray* value, vector<uint8_t>* binary) {
  mxArray* serialized_array = static_cast<mxArray*>(mxSerialize(value));
  if (serialized_array == NULL)
    ERROR("Failed to serialize mxArray.");
  const uint8_t* data = static_cast<uint8_t*>(mxGetData(serialized_array));
  binary->assign(data, data + mxGetNumberOfElements(serialized_array));
  mxDestroyArray(serialized_array);
}

void Record::deserialize_mxarray(const vector<uint8_t>& binary,
                                 mxArray** value) {
  *value = static_cast<mxArray*>(mxDeserialize(&binary[0], binary.size()));
  if (*value == NULL)
    ERROR("Failed to deserialize mxArray.");
}

#ifdef ENABLE_ZLIB

void Record::compress_mxarray(const mxArray* value, vector<uint8_t>* binary) {
  mxArray* serialized_array = static_cast<mxArray*>(mxSerialize(value));
  if (serialized_array == NULL)
    ERROR("Failed to serialize mxArray.");
  uLongf array_size = mxGetNumberOfElements(serialized_array);
  vector<uint8_t> buffer(compressBound(array_size));
  uLongf actual_size = buffer.size();
  int code_ = compress(&buffer[0],
                       &actual_size,
                       static_cast<const Bytef*>(mxGetData(serialized_array)),
                       array_size);
  binary->resize(sizeof(uLongf) + actual_size);
  memcpy(&(*binary)[0], &array_size, sizeof(uLongf));
  copy(buffer.begin(),
       buffer.begin() + actual_size,
       binary->begin() + sizeof(uLongf));
  mxDestroyArray(serialized_array);
  if (code_ != Z_OK)
    ERROR("Fatal error in compress_mxarray");
}

void Record::decompress_mxarray(const vector<uint8_t>& binary,
                                mxArray** value) {
  if (binary.size() <= sizeof(uint32_t))
    ERROR("Fatal error in decompress_mxarray: invalid binary.");
  uLongf array_size = 0;
  memcpy(&array_size, &binary[0], sizeof(uLongf));
  vector<uint8_t> buffer(array_size);
  uLongf actual_size = array_size;
  int code_ = uncompress(&buffer[0],
                         &actual_size,
                         &binary[0] + sizeof(uLongf),
                         binary.size() - sizeof(uLongf));
  *value = static_cast<mxArray*>(mxDeserialize(&buffer[0], buffer.size()));
  if (*value == NULL)
    ERROR("Failed to deserialize mxArray.");
  if (code_ != Z_OK)
    ERROR("Fatal error in decompress_mxarray: code = %d.", code_);
}

#else

void Record::compress_mxarray(const mxArray* value, vector<uint8_t>* binary) {
  serialize_mxarray(value, binary);
}

void Record::decompress_mxarray(const vector<uint8_t>& binary,
                                mxArray** value) {
  deserialize_mxarray(binary, value);
}

#endif // ENABLE_ZLIB

Cursor::~Cursor() {
  if (cursor_)
    cursor_->close(cursor_);
}

int Cursor::open(DB* database_) {
  code_ = database_->cursor(database_, NULL, &cursor_, 0);
  return code_;
}

int Cursor::next() {
  code_ = cursor_->get(cursor_, record_.key(), record_.value(), DB_NEXT);
  return code_;
}

int Cursor::prev() {
  code_ = cursor_->get(cursor_, record_.key(), record_.value(), DB_PREV);
  return code_;
}

Environment::Environment() : environment_(NULL) {}

Environment::~Environment() {
  close(0);
}

bool Environment::open(const string& home, uint32_t flags, int mode) {
  code_ = db_env_create(&environment_, 0);
  if (!ok()) return false;
  code_ = environment_->open(environment_,
                             home.c_str(),
                             flags,
                             mode);
  return ok();
}

bool Environment::close(uint32_t flags) {
  if (environment_) {
    code_ = environment_->close(environment_, flags);
    environment_ = NULL;
  }
  return ok();
}

bool Environment::txn_begin(uint32_t flags,
                            Transaction* parent,
                            Transaction* transaction) {
  DB_TXN* txnid;
  code_ = environment_->txn_begin(environment_,
                                  (parent == NULL) ? NULL : parent->get(),
                                  &txnid,
                                  flags);
  transaction->reset(txnid);
  return ok();
}

bool Transaction::abort() {
  code_ = transaction_->abort(transaction_);
  return ok();
}

bool Transaction::commit(uint32_t flags) {
  code_ = transaction_->commit(transaction_, flags);
  return ok();
}

Database::Database() : code_(0), database_(NULL) {}

Database::~Database() {
  close(0);
}

bool Database::open(const string& filename,
                    const string& name,
                    DBTYPE type,
                    uint32_t flags,
                    int mode,
                    Environment* environment,
                    Transaction* transaction) {
  code_ = db_create(&database_,
                    (environment == NULL) ? NULL : environment->get(),
                    0);
  if (!ok()) return false;
  code_ = database_->open(database_,
                          (transaction == NULL) ? NULL : transaction->get(),
                          (filename.empty()) ? NULL : filename.c_str(),
                          (name.empty()) ? NULL : name.c_str(),
                          type,
                          flags,
                          mode);
  return ok();
}

bool Database::close(uint32_t flags) {
  if (database_) {
    code_ = database_->close(database_, flags);
    database_ = NULL;
  }
  return ok();
}

int Database::error_code() const {
  return code_;
}

const char* Database::error_message() const {
  return db_strerror(code_);
}

bool Database::get(const mxArray* key,
                   uint32_t flags,
                   mxArray** value,
                   Transaction* transaction) {
  Record record = (*value != NULL) ? Record(key, *value) : Record(key);
  code_ = database_->get(database_,
                         (transaction == NULL) ? NULL : transaction->get(),
                         record.key(),
                         record.value(),
                         flags);
  if (code_ == 0)
    record.get_value(value);
  else if (code_ == DB_NOTFOUND)
    *value = mxCreateDoubleMatrix(0, 0, mxREAL);
  return ok() || (code_ == DB_NOTFOUND);
}

bool Database::put(const mxArray* key,
                   const mxArray* value,
                   uint32_t flags,
                   Transaction* transaction) {
  Record record(key, value);
  code_ = database_->put(database_,
                         (transaction == NULL) ? NULL : transaction->get(),
                         record.key(),
                         record.value(),
                         flags);
  return ok();
}

bool Database::del(const mxArray* key,
                   uint32_t flags,
                   Transaction* transaction) {
  Record record(key);
  code_ = database_->del(database_,
                         (transaction == NULL) ? NULL : transaction->get(),
                         record.key(),
                         flags);
  return ok();
}

bool Database::exists(const mxArray* key,
                      uint32_t flags,
                      mxArray** value,
                      Transaction* transaction) {
  Record record(key);
  code_ = database_->exists(database_,
                            (transaction == NULL) ? NULL : transaction->get(),
                            record.key(),
                            flags);
  *value = mxCreateLogicalScalar(ok());
  return ok() || code_ == DB_NOTFOUND;
}

bool Database::stat(uint32_t flags,
                    mxArray** output,
                    Transaction* transaction) {
  DBTYPE type;
  code_ = database_->get_type(database_, &type);
  if (!ok()) return false;
  switch (type) {
    case DB_HASH: {
      DB_HASH_STAT* stats;
      code_ = database_->stat(database_,
                              (transaction == NULL) ? NULL : transaction->get(),
                              &stats,
                              flags);
      if (output != NULL) {
        const char* kFields[] = {
            "buckets", "ffactor", "magic", "ndata", "nkeys", "pagecnt",
            "pagesize", "version",
            "bfree", "bigpages", "big_bfree", "dup", "dup_free", "free",
            "overflows", "ovfl_free"
            };
        MxArray output_data = MxArray::Struct(8 + !(flags & DB_FAST_STAT) * 8,
                                              kFields);
        output_data.set(kFields[0], double(stats->hash_buckets));
        output_data.set(kFields[1], double(stats->hash_ffactor));
        output_data.set(kFields[2], double(stats->hash_magic));
        output_data.set(kFields[3], double(stats->hash_ndata));
        output_data.set(kFields[4], double(stats->hash_nkeys));
        output_data.set(kFields[5], double(stats->hash_pagecnt));
        output_data.set(kFields[6], double(stats->hash_pagesize));
        output_data.set(kFields[7], double(stats->hash_version));
        if (!(flags & DB_FAST_STAT)) {
          output_data.set(kFields[8], double(stats->hash_bfree));
          output_data.set(kFields[9], double(stats->hash_bigpages));
          output_data.set(kFields[10], double(stats->hash_big_bfree));
          output_data.set(kFields[11], double(stats->hash_dup));
          output_data.set(kFields[12], double(stats->hash_dup_free));
          output_data.set(kFields[13], double(stats->hash_free));
          output_data.set(kFields[14], double(stats->hash_overflows));
          output_data.set(kFields[15], double(stats->hash_ovfl_free));
        }
        *output = output_data.getMutable();
      }
      free(stats);
      break;
    }
    // case DB_HEAP: {
    //   DB_HEAP_STAT* stats;
    //   code_ = database_->stat(database_,
    //                           (transaction == NULL) ? NULL : transaction->get(),
    //                           &stats,
    //                           flags);
    //   if (output != NULL) {
    //     const char* kFields[] = {
    //         "magic", "version", "nrecs", "pagecnt", "pagesize", "nregions",
    //         "regionsize"
    //         };
    //     MxArray output_data = MxArray::Struct(7, kFields);
    //     output_data.set(kFields[0], double(stats->heap_magic));
    //     output_data.set(kFields[1], double(stats->heap_version));
    //     output_data.set(kFields[2], double(stats->heap_nrecs));
    //     output_data.set(kFields[3], double(stats->heap_pagecnt));
    //     output_data.set(kFields[4], double(stats->heap_pagesize));
    //     output_data.set(kFields[5], double(stats->heap_nregions));
    //     output_data.set(kFields[6], double(stats->heap_regionsize));
    //     *output = output_data.getMutable();
    //   }
    //   free(stats);
    //   break;
    // }
    case DB_BTREE:
    case DB_RECNO: {
      DB_BTREE_STAT* stats;
      code_ = database_->stat(database_,
                              (transaction == NULL) ? NULL : transaction->get(),
                              &stats,
                              flags);
      if (output != NULL) {
        const char* kFields[] = {
            "magic", "minkey", "ndata", "nkeys", "pagecnt", "pagesize",
            "re_len", "re_pad", "version",
            "dup_pg", "dup_pgfree", "empty_pg", "free", "int_pg", "int_pgfree",
            "leaf_pg", "leaf_pgfree", "levels", "over_pg", "over_pgfree"
            };
        MxArray output_data = MxArray::Struct(9 + !(flags & DB_FAST_STAT) * 11,
                                              kFields);
        output_data.set(kFields[0], double(stats->bt_magic));
        output_data.set(kFields[1], double(stats->bt_minkey));
        output_data.set(kFields[2], double(stats->bt_ndata));
        output_data.set(kFields[3], double(stats->bt_nkeys));
        output_data.set(kFields[4], double(stats->bt_pagecnt));
        output_data.set(kFields[5], double(stats->bt_pagesize));
        output_data.set(kFields[6], double(stats->bt_re_len));
        output_data.set(kFields[7], double(stats->bt_re_pad));
        output_data.set(kFields[8], double(stats->bt_version));
        if (!(flags & DB_FAST_STAT)) {
          output_data.set(kFields[9], double(stats->bt_dup_pg));
          output_data.set(kFields[10], double(stats->bt_dup_pgfree));
          output_data.set(kFields[11], double(stats->bt_empty_pg));
          output_data.set(kFields[12], double(stats->bt_free));
          output_data.set(kFields[13], double(stats->bt_int_pg));
          output_data.set(kFields[14], double(stats->bt_int_pgfree));
          output_data.set(kFields[15], double(stats->bt_leaf_pg));
          output_data.set(kFields[16], double(stats->bt_leaf_pgfree));
          output_data.set(kFields[17], double(stats->bt_levels));
          output_data.set(kFields[18], double(stats->bt_over_pg));
          output_data.set(kFields[19], double(stats->bt_over_pgfree));
        }
        *output = output_data.getMutable();
      }
      free(stats);
      break;
    }
    case DB_QUEUE: {
      DB_QUEUE_STAT* stats;
      code_ = database_->stat(database_,
                              (transaction == NULL) ? NULL : transaction->get(),
                              &stats,
                              flags);
      if (output != NULL) {
        const char* kFields[] = {
            "cur_recno", "extentsize", "first_recno", "magic", "nkeys",
            "ndata", "pagesize", "re_len", "re_pad", "version",
            "pages", "pgfree"
            };
        MxArray output_data = MxArray::Struct(10 + !(flags & DB_FAST_STAT) * 2,
                                              kFields);
        output_data.set(kFields[0], double(stats->qs_cur_recno));
        output_data.set(kFields[1], double(stats->qs_extentsize));
        output_data.set(kFields[2], double(stats->qs_first_recno));
        output_data.set(kFields[3], double(stats->qs_magic));
        output_data.set(kFields[4], double(stats->qs_nkeys));
        output_data.set(kFields[5], double(stats->qs_ndata));
        output_data.set(kFields[6], double(stats->qs_pagesize));
        output_data.set(kFields[7], double(stats->qs_re_len));
        output_data.set(kFields[8], double(stats->qs_re_pad));
        output_data.set(kFields[9], double(stats->qs_version));
        if (!(flags & DB_FAST_STAT)) {
          output_data.set(kFields[10], double(stats->qs_pages));
          output_data.set(kFields[11], double(stats->qs_pgfree));
        }
        *output = output_data.getMutable();
      }
      free(stats);
      break;
    }
    default: {
      ERROR("Fatal error. Unknown db_type.");
    }
  }
  return ok();
}

bool Database::keys(mxArray** output) {
  // Count the number of keys.
  DB_BTREE_STAT* stats = NULL;
  stats = static_cast<DB_BTREE_STAT*>(malloc(sizeof(DB_BTREE_STAT)));
  if (stats == NULL)
    return false;
  code_ = database_->stat(database_, NULL, &stats, 0);
  uint32_t num_keys = stats->bt_nkeys;
  free(stats);
  if (code_)
    return false;
  // Retrieve records.
  Cursor cursor;
  code_ = cursor.open(database_);
  if (code_)
    return false;
  *output = mxCreateCellMatrix(num_keys, 1);
  int index = 0;
  while (index < num_keys && 0 == (code_ = cursor.next())) {
    mxArray* key_array;
    cursor.get()->get_key(&key_array);
    mxSetCell(*output, index++, key_array);
  }
  return ok() || (code_ == DB_NOTFOUND);
}

bool Database::values(mxArray** output) {
  // Count the number of values.
  DB_BTREE_STAT* stats = NULL;
  stats = static_cast<DB_BTREE_STAT*>(malloc(sizeof(DB_BTREE_STAT)));
  if (stats == NULL)
    return false;
  code_ = database_->stat(database_, NULL, &stats, 0);
  uint32_t num_values = stats->bt_ndata;
  free(stats);
  if (code_)
    return false;
  // Retrieve records.
  Cursor cursor;
  code_ = cursor.open(database_);
  if (code_)
    return false;
  *output = mxCreateCellMatrix(num_values, 1);
  int index = 0;
  while (index < num_values && 0 == (code_ = cursor.next())) {
    mxArray* value_array;
    cursor.get()->get_value(&value_array);
    mxSetCell(*output, index++, value_array);
  }
  return ok() || (code_ == DB_NOTFOUND);
}

bool Database::compact(uint32_t flags,
                       DB_COMPACT* compact_data,
                       Transaction* transaction) {
  code_ = database_->compact(database_,
                             (transaction == NULL) ? NULL : transaction->get(),
                             NULL,
                             NULL,
                             compact_data,
                             flags,
                             NULL);
  return ok();
}

bool Database::cursor(Cursor* cursor) {
  if (cursor == NULL)
    ERROR("Null pointer exception.");
  code_ = cursor->open(database_);
  return ok();
}


} // namespace bdbmex
