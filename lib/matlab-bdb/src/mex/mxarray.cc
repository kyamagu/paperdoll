/// MxArray data conversion library.
///
/// Kota Yamaguchi 2013 <kyamagu@cs.stonybrook.edu>

#include "mxarray.h"

namespace mex {

MxArray::MxArray() : array_(NULL), mutable_array_(NULL) {}

MxArray::MxArray(mxArray* array) : array_(array), mutable_array_(array) {}

MxArray::MxArray(const mxArray* array) : array_(array), mutable_array_(NULL) {}

MxArray::MxArray(const MxArray& array) :
    array_(array.array_), mutable_array_(array.mutable_array_) {}

MxArray& MxArray::operator=(const MxArray& rhs) {
  if (this != &rhs)
    this->reset(rhs.mutable_array_);
  return *this;
}

MxArray::MxArray(const int value) :
    mutable_array_(mxCreateDoubleScalar(static_cast<double>(value))) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

MxArray::MxArray(const double value) :
    mutable_array_(mxCreateDoubleScalar(value)) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

MxArray::MxArray(const bool value) :
    mutable_array_(mxCreateLogicalScalar(value)) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

MxArray::MxArray(const std::string& value) :
    mutable_array_(mxCreateString(value.c_str())) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

MxArray::MxArray(std::vector<MxArray>* values) :
    array_(NULL), mutable_array_(NULL) {
  if (values == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  mutable_array_ = mxCreateCellMatrix(1, values->size());
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  for (int i = 0; i < values->size(); ++i)
    set(i, (*values)[i].getMutable());
}

MxArray::MxArray(int nfields, const char** fields, int rows, int columns) :
    mutable_array_(mxCreateStructMatrix(rows, columns, nfields, fields)) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

MxArray MxArray::Cell(int rows, int columns) {
  mxArray* cell_array = mxCreateCellMatrix(rows, columns);
  if (cell_array == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  return MxArray(cell_array);
}

MxArray MxArray::Struct(int nfields,
                        const char** fields,
                        int rows,
                        int columns) {
  return MxArray(nfields, fields, rows, columns);
}

MxArray::~MxArray() {}

void MxArray::reset(const mxArray* array) {
  array_ = array;
  mutable_array_ = NULL;
}

void MxArray::reset(mxArray* array) {
  array_ = array;
  mutable_array_ = array;
}

MxArray MxArray::clone() {
  mxArray* array = mxDuplicateArray(array_);
  if (array == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  return MxArray(array);
}

void MxArray::destroy() {
  if (mutable_array_ != NULL)
    mxDestroyArray(mutable_array_);
  reset(static_cast<mxArray*>(NULL));
}

mxArray* MxArray::getMutable() {
  if (isConst())
    mexErrMsgIdAndTxt("mxarray:error",
                      "const MxArray cannot be converted to mxArray*.");
  return mutable_array_;
}

int MxArray::toInt() const {
  if (numel() != 1)
    mexErrMsgIdAndTxt("mxarray:error", "MxArray is not a scalar.");
  return at<int>(0);
}

double MxArray::toDouble() const {
  if (numel() != 1)
    mexErrMsgIdAndTxt("mxarray:error", "MxArray is not a scalar.");
  return at<double>(0);
}

bool MxArray::toBool() const {
  if (numel() != 1)
    mexErrMsgIdAndTxt("mxarray:error", "MxArray is not a scalar.");
  return at<bool>(0);
}

std::string MxArray::toString() const {
  if (!isChar())
    mexErrMsgIdAndTxt("mxarray:error",
                      "Cannot convert %s to string.",
                      className().c_str());
  return std::string(mxGetChars(array_), mxGetChars(array_) + numel());
}

void MxArray::size(std::vector<mwSize>* size_value) const {
  if (size_value == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  size_value->assign(dims(), dims() + ndims());
}

std::string MxArray::fieldName(int index) const {
  const char* field_name = mxGetFieldNameByNumber(array_, index);
  if (field_name == NULL)
    mexErrMsgIdAndTxt("mxarray:error",
                      "Failed to get field name at %d.",
                      index);
  return std::string(field_name);
}

void MxArray::fieldNames(std::vector<std::string>* field_names) const {
  if (field_names == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (!isStruct())
    mexErrMsgIdAndTxt("mxarray:error", "MxArray is not a struct array.");
  field_names->resize(nfields());
  for (int i = 0; i < field_names->size(); ++i)
    (*field_names)[i] = fieldName(i);
}

mwIndex MxArray::subs(mwIndex row, mwIndex column) const {
  if (row < 0 || row >= rows() || column < 0 || column >= cols())
    mexErrMsgIdAndTxt("mxarray:error", "Subscript is out of range.");
  mwIndex subscripts[] = {row, column};
  return mxCalcSingleSubscript(array_, 2, subscripts);
}

mwIndex MxArray::subs(const std::vector<mwIndex>& subscripts) const {
  return mxCalcSingleSubscript(array_, subscripts.size(), &subscripts[0]);
}

MxArray MxArray::at(const std::string& field_name, mwIndex index) const {
  if (!isStruct())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a struct array but %s.",
                      className().c_str());
  if (index < 0 || numel() <= index)
    mexErrMsgIdAndTxt("mxarray:error", "Index is out of range.");
  mxArray* array = mxGetField(array_, index, field_name.c_str());
  if (array == NULL)
    mexErrMsgIdAndTxt("mxarray:error",
                      "Field '%s' doesn't exist",
                      field_name.c_str());
  return (isConst()) ? 
      MxArray(static_cast<const mxArray*>(array)) : MxArray(array);
}

void MxArray::set(mwIndex index, mxArray* value) {
  if (mutable_array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (value == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (!isCell())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a cell array but %s.",
                      className().c_str());
  if (index < 0 || numel() <= index)
    mexErrMsgIdAndTxt("mxarray:error", "Index is out of range.");
  mxSetCell(mutable_array_, index, value);
}

void MxArray::set(const std::string& field_name,
                  mxArray* value,
                  mwIndex index) {
  if (mutable_array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (value == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (!isStruct())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a struct array but %s.",
                      className().c_str());
  if (!isField(field_name)) {
    if (mxAddField(mutable_array_, field_name.c_str()) < 0)
      mexErrMsgIdAndTxt("mxarray:error",
                        "Failed to create a field '%s'",
                        field_name.c_str());
  }
  mxSetField(mutable_array_, index, field_name.c_str(), value);
}

template <>
MxArray::MxArray(const std::vector<char>& values) :
    array_(NULL), mutable_array_(NULL) {
  std::string string_value(values.begin(), values.end());
  mutable_array_ = mxCreateString(string_value.c_str());
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
}

template <>
MxArray::MxArray(const std::vector<bool>& values) :
    mutable_array_(mxCreateLogicalMatrix(1, values.size())) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  std::copy(values.begin(), values.end(), mxGetLogicals(mutable_array_));
}

template <>
MxArray::MxArray(const std::vector<std::string>& values) :
    mutable_array_(mxCreateCellMatrix(1, values.size())) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  for (int i = 0; i < values.size(); ++i) {
    set(i, MxArray(values[i]).getMutable());
  }
}

template <>
MxArray MxArray::at(mwIndex index) const {
  if (!isCell())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a cell array but %s.",
                      className().c_str());
  mxArray* array = mxGetCell(array_, index);
  if (array == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  return (isConst()) ?
      MxArray(static_cast<const mxArray*>(array)) : MxArray(array);
}

template <>
void MxArray::toVector(std::vector<MxArray>* values) const {
  if (values == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (!isCell())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a cell array but %s.",
                      className().c_str());
  values->resize(numel());
  for (int i = 0; i < values->size(); ++i)
    (*values)[i] = at<MxArray>(i);
}

template <>
void MxArray::toVector(std::vector<std::string>* values) const {
  if (values == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (!isCell())
    mexErrMsgIdAndTxt("mxarray:error",
                      "MxArray is not a cell array but %s.",
                      className().c_str());
  values->resize(numel());
  for (int i = 0; i < values->size(); ++i)
    (*values)[i] = at<MxArray>(i).toString();
}

} // namespace mex