/// MxArray data conversion library.
///
/// The library provides mex::MxArray class for data conversion between
/// mxArray* and C++ types. Examples are the following.
///
/// Conversion from mxArray* to C++ types.
///
///     int value            = MxArray(prhs[0]).toInt();
///     double value         = MxArray(prhs[0]).toDouble();
///     bool value           = MxArray(prhs[0]).toBool();
///     std::string value    = MxArray(prhs[0]).toString();
///     std::vector<double>  = MxArray(prhs[0]).toVector<double>();
///     std::vector<MxArray> = MxArray(prhs[0]).toVector<MxArray>();
///
/// Conversion from C++ types to mxArray*.
///
///     plhs[0] = MxArray(value).getMutable();
///
/// Kota Yamaguchi 2013 <kyamagu@cs.stonybrook.edu>

#ifndef __MXARRAY_H__
#define __MXARRAY_H__

#include <mex.h>
#include <stdint.h>
#include <string>
#include <vector>

namespace mex {

/// mxArray object wrapper for data conversion and manipulation.
class MxArray {
public:
  /// Empty MxArray constructor. Use reset() to set a pointer.
  MxArray();
  /// MxArray constructor from const mxArray*. This will be a const MxArray.
  /// @param array mxArray pointer given by mexFunction.
  explicit MxArray(const mxArray* array);
  /// MxArray constructor from mutable mxArray*.
  /// @param array mxArray pointer.
  explicit MxArray(mxArray* array);
  /// Copy constructor.
  /// @param array Another MxArray.
  MxArray(const MxArray& array);
  /// Assignment operator.
  MxArray& operator=(const MxArray& rhs);
  /// MxArray constructor from int.
  /// @param value int value.
  explicit MxArray(const int value);
  /// MxArray constructor from double.
  /// @param value double value.
  explicit MxArray(const double value);
  /// MxArray constructor from bool.
  /// @param value bool value.
  explicit MxArray(const bool value);
  /// MxArray constructor from std::string.
  /// @param value reference to a string value.
  explicit MxArray(const std::string& value);
  /// MxArray constructor from vector<T>.
  /// @param values vector of type T.
  template <typename T> explicit MxArray(const std::vector<T>& values);
  /// MxArray constructor from std::vector<MxArray>*.
  /// @param values vector values to be converted to a cell array.
  explicit MxArray(std::vector<MxArray>* values);
  /// Generic constructor for a struct array.
  /// @param fields field names.
  /// @param nfields number of field names.
  /// @param rows size of the first dimension.
  /// @param columns size of the second dimension.
  ///
  /// Example:
  /// @code
  ///     const char* fields[] = {"field1", "field2"};
  ///     MxArray struct_array(fields, 2);
  ///     struct_array.set("field1", MxArray(1).getMutable());
  ///     struct_array.set("field2", MxArray("field2 value").getMutable());
  /// @endcode
  MxArray(int nfields, const char** fields, int rows = 1, int columns = 1);
  /// Create a new cell array.
  /// @param rows Number of rows.
  /// @param columns Number of cols.
  ///
  /// Example:
  /// @code
  ///     MxArray cell_array = MxArray::Cell(1, 2);
  ///     cell_array.set(0, MxArray(1).getMutable());
  ///     cell_array.set(1, MxArray("another value").getMutable());
  /// @endcode
  static MxArray Cell(int rows = 1, int columns = 1);
  /// Create a new struct array.
  /// @param fields Field names.
  /// @param nfields Number of fields.
  /// @param rows Number of rows.
  /// @param columns Number of cols.
  static MxArray Struct(int nfields = 0,
                        const char** fields = NULL,
                        int rows = 1,
                        int columns = 1);
  /// Destructor. Note that the current implementation does not free the
  /// underlying mxArray*.
  virtual ~MxArray();
  /// Reset an mxArray to a const mxArray*.
  void reset(const mxArray* array);
  /// Reset an mxArray.
  void reset(mxArray* array);
  /// Clone mxArray. This allocates new mxArray*.
  /// @return MxArray object.
  MxArray clone();
  /// Destroy allocated mxArray. Use this to destroy a temporary mxArray not
  /// to be used in matlab.
  /// @return newly allocated MxArray object.
  void destroy();
  /// Conversion to const mxArray*.
  /// @return const mxArray* pointer.
  inline const mxArray* get() const { return array_; }
  /// Conversion to mxArray*. Only non-const MxArray can be converted.
  /// @return mxArray* pointer.
  mxArray* getMutable();
  /// Convert MxArray to int.
  /// @return int value.
  int toInt() const;
  /// Convert MxArray to double.
  /// @return double value.
  double toDouble() const;
  /// Convert MxArray to bool.
  /// @return bool value.
  bool toBool() const;
  /// Convert MxArray to std::string.
  /// @return std::string value.
  std::string toString() const;
  /// Convert MxArray to std::vector<T> for a primitive type.
  /// @return std::vector<T> value.
  ///
  /// The method is intended for conversion to a raw numeric vector such
  /// as std::vector<int> or std::vector<double>. Example:
  ///
  /// @code
  ///     MxArray array(prhs[0]);
  ///     vector<double> values;
  ///     array.toVector<double>(&values);
  /// @endcode
  template <typename T> void toVector(std::vector<T>* values) const;

  /// Class ID of mxArray.
  inline mxClassID classID() const { return mxGetClassID(array_); }
  /// Class name of mxArray.
  inline const std::string className() const {
    return std::string(mxGetClassName(array_));
  }
  /// Number of elements in an array.
  inline mwSize numel() const { return mxGetNumberOfElements(array_); }
  /// Number of dimensions.
  inline mwSize ndims() const { return mxGetNumberOfDimensions(array_); }
  /// Array of each dimension.
  inline const mwSize* dims() const { return mxGetDimensions(array_); }
  /// Vector of dimensions.
  /// @param size_value vector of dimensions.
  void size(std::vector<mwSize>* size_value) const;
  /// Number of rows in an array.
  inline mwSize rows() const { return mxGetM(array_); }
  /// Number of columns in an array.
  inline mwSize cols() const { return mxGetN(array_); }
  /// Number of fields in a struct array.
  inline int nfields() const { return mxGetNumberOfFields(array_); }
  /// Get field name of a struct array.
  /// @param index index of the struct array.
  /// @return std::string.
  std::string fieldName(int index) const;
  /// Get field names of a struct array.
  /// @params field_nams std::vector<std::string> of struct field names.
  void fieldNames(std::vector<std::string>* field_names) const;
  /// Number of elements in IR, PR, and PI arrays.
  inline mwSize nzmax() const { return mxGetNzmax(array_); }
  /// Offset from first element to desired element.
  /// @param row index of the first dimension of the array.
  /// @param column index of the second dimension of the array.
  /// @return linear offset of the specified subscript index.
  mwIndex subs(mwIndex row, mwIndex column) const;
  /// Offset from first element to desired element.
  /// @param si subscript index of the array.
  /// @return linear offset of the specified subscript index.
  mwIndex subs(const std::vector<mwIndex>& subscripts) const;
  /// Determine whether input is cell array.
  inline bool isCell() const { return mxIsCell(array_); }
  /// Determine whether input is string array.
  inline bool isChar() const { return mxIsChar(array_); }
  /// Determine whether array is member of specified class.
  inline bool isClass(const std::string& s) const {
    return mxIsClass(array_, s.c_str());
  }
  /// Determine whether data is complex.
  inline bool isComplex() const { return mxIsComplex(array_); }
  /// Determine whether mxArray represents data as double-precision,
  /// floating-point numbers.
  inline bool isDouble() const { return mxIsDouble(array_); }
  /// Determine whether array is empty.
  inline bool isEmpty() const { return mxIsEmpty(array_); }
  /// Determine whether input is finite.
  static inline bool IsFinite(double value) { return mxIsFinite(value); }
  /// Determine whether array was copied from MATLAB global workspace.
  inline bool isFromGlobalWS() const { return mxIsFromGlobalWS(array_); };
  /// Determine whether input is infinite.
  static inline bool IsInf(double value) { return mxIsInf(value); }
  /// Determine whether array represents data as signed 8-bit integers.
  inline bool isInt8() const { return mxIsInt8(array_); }
  /// Determine whether array represents data as signed 16-bit integers.
  inline bool isInt16() const { return mxIsInt16(array_); }
  /// Determine whether array represents data as signed 32-bit integers.
  inline bool isInt32() const { return mxIsInt32(array_); }
  /// Determine whether array represents data as signed 64-bit integers.
  inline bool isInt64() const { return mxIsInt64(array_); }
  /// Determine whether array is of type mxLogical.
  inline bool isLogical() const { return mxIsLogical(array_); }
  /// Determine whether scalar array is of type mxLogical.
  inline bool isLogicalScalar() const { return mxIsLogicalScalar(array_); }
  /// Determine whether scalar array of type mxLogical is true.
  inline bool isLogicalScalarTrue() const {
    return mxIsLogicalScalarTrue(array_);
  }
  /// Determine whether array is numeric.
  inline bool isNumeric() const { return mxIsNumeric(array_); }
  /// Determine whether array represents data as single-precision,
  /// floating-point numbers.
  inline bool isSingle() const { return mxIsSingle(array_); }
  /// Determine whether input is sparse array.
  inline bool isSparse() const { return mxIsSparse(array_); }
  /// Determine whether input is structure array.
  inline bool isStruct() const { return mxIsStruct(array_); }
  /// Determine whether array represents data as unsigned 8-bit integers.
  inline bool isUint8() const { return mxIsUint8(array_); }
  /// Determine whether array represents data as unsigned 16-bit integers.
  inline bool isUint16() const { return mxIsUint16(array_); }
  /// Determine whether array represents data as unsigned 32-bit integers.
  inline bool isUint32() const { return mxIsUint32(array_); }
  /// Determine whether array represents data as unsigned 64-bit integers.
  inline bool isUint64() const { return mxIsUint64(array_); }
  /// Determine whether a struct array has a specified field.
  bool isField(const std::string& field_name, mwIndex index = 0) const {
    return isStruct() &&
        mxGetField(array_, index, field_name.c_str()) != NULL;
  }
  /// Determine wheter the array is const or not.
  inline bool isConst() const { return !isNull() && mutable_array_ == NULL; }
  /// Determine wheter the array is initialized or not.
  inline bool isNull() const { return array_ == NULL; }
  /// Template for element accessor.
  /// @param index index of the array element.
  /// @return value of the element at index.
  ///
  /// Example:
  /// @code
  ///     MxArray array(prhs[0]);
  ///     double value = array.at<double>(0);
  /// @endcode
  template <typename T> T at(mwIndex index) const;
  /// Template for element accessor.
  /// @param row index of the first dimension.
  /// @param column index of the second dimension.
  /// @return value of the element at (row, column).
  template <typename T> T at(mwIndex row, mwIndex column) const;
  /// Template for element accessor.
  /// @param si subscript index of the element.
  /// @return value of the element at subscript index.
  template <typename T> T at(const std::vector<mwIndex>& subscripts) const;
  /// Struct element accessor.
  /// @param field_name field name of the struct array.
  /// @param index index of the struct array.
  /// @return value of the element at the specified field.
  MxArray at(const std::string& field_name, mwIndex index = 0) const;
  /// Template for element write accessor.
  /// @param index offset of the array element.
  /// @param value value of the field.
  template <typename T> void set(mwIndex index, const T& value);
  /// Template for element write accessor.
  /// @param row index of the first dimension of the array element.
  /// @param column index of the first dimension of the array element.
  /// @param value value of the field.
  template <typename T> void set(mwIndex row, mwIndex column, const T& value);
  /// Template for element write accessor.
  /// @param subscripts subscript index of the element.
  /// @param value value of the field.
  template <typename T> void set(const std::vector<mwIndex>& subscripts,
                                 const T& value);
  /// Cell element write accessor.
  /// @param index index of the element.
  /// @param value cell element to be inserted.
  void set(mwIndex index, mxArray* value);
  /// Struct element write accessor.
  /// @param field_name field name of the struct array.
  /// @param value value of the field.
  /// @param index linear index of the struct array element.
  template <typename T> void set(const std::string& field_name,
                                 const T& value,
                                 mwIndex index = 0);
  /// Struct element write accessor.
  /// @param field_name field name of the struct array.
  /// @param value value of the field to be inserted.
  /// @param index linear index of the struct array element.
  void set(const std::string& field_name, mxArray* value, mwIndex index = 0);
  /// Determine whether input is NaN (Not-a-Number).
  static inline bool IsNaN(double value) { return mxIsNaN(value); }
  /// Value of infinity.
  static inline double Inf() { return mxGetInf(); }
  /// Value of NaN (Not-a-Number).
  static inline double NaN() { return mxGetNaN(); }
  /// Value of EPS.
  static inline double Eps() { return mxGetEps(); }

private:
  /// Const pointer to the mxArray C object.
  const mxArray* array_;
  /// Mutable pointer to the mxArray C object.
  mxArray* mutable_array_;
};

template <typename T>
MxArray::MxArray(const std::vector<T>& values) :
    mutable_array_(mxCreateDoubleMatrix(1, values.size(), mxREAL)) {
  array_ = mutable_array_;
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  std::copy(values.begin(), values.end(), mxGetPr(mutable_array_));
}

template <typename T>
void MxArray::toVector(std::vector<T>* values) const {
  if (values == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  mwSize num_elements = numel();
  switch (classID()) {
    case mxCHAR_CLASS: {
      mxChar* data = mxGetChars(array_);
      values->assign(data, data + num_elements);
    }
    case mxDOUBLE_CLASS: {
      double* data = mxGetPr(array_);
      values->assign(data, data + num_elements);
    }
    case mxINT8_CLASS: {
      int8_t* data = reinterpret_cast<int8_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxUINT8_CLASS: {
      uint8_t* data = reinterpret_cast<uint8_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxINT16_CLASS: {
      int16_t* data = reinterpret_cast<int16_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxUINT16_CLASS: {
      uint16_t* data = reinterpret_cast<uint16_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxINT32_CLASS: {
      int32_t* data = reinterpret_cast<int32_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxUINT32_CLASS: {
      uint32_t* data = reinterpret_cast<uint32_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxINT64_CLASS: {
      int64_t* data = reinterpret_cast<int64_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxUINT64_CLASS: {
      uint64_t* data = reinterpret_cast<uint64_t*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxSINGLE_CLASS: {
      float* data = reinterpret_cast<float*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    case mxLOGICAL_CLASS: {
      mxLogical* data = reinterpret_cast<mxLogical*>(mxGetData(array_));
      values->assign(data, data + num_elements);
    }
    default: {
      mexErrMsgIdAndTxt("mxarray:error",
                        "Cannot convert %s to a scalar value.",
                        className().c_str());
    }
  }
}

template <typename T>
T MxArray::at(mwIndex index) const {
  if (array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (numel() <= index)
    mexErrMsgIdAndTxt("mxarray:error",
                      "Index out of range: %d of %d.",
                      index,
                      numel());
  switch (classID()) {
    case mxCHAR_CLASS:
      return static_cast<T>(*(mxGetChars(array_)+index));
    case mxDOUBLE_CLASS:
      return static_cast<T>(*(mxGetPr(array_)+index));
    case mxINT8_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<int8_t*>(mxGetData(array_))+index));
    case mxUINT8_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<uint8_t*>(mxGetData(array_))+index));
    case mxINT16_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<int16_t*>(mxGetData(array_))+index));
    case mxUINT16_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<uint16_t*>(mxGetData(array_))+index));
    case mxINT32_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<int32_t*>(mxGetData(array_))+index));
    case mxUINT32_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<uint32_t*>(mxGetData(array_))+index));
    case mxINT64_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<int64_t*>(mxGetData(array_))+index));
    case mxUINT64_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<uint64_t*>(mxGetData(array_))+index));
    case mxSINGLE_CLASS:
      return static_cast<T>(
          *(reinterpret_cast<float*>(mxGetData(array_))+index));
    case mxLOGICAL_CLASS:
      return static_cast<T>(*(mxGetLogicals(array_)+index));
    default:
      mexErrMsgIdAndTxt("mxarray:error",
                        "Cannot convert %s to a scalar value.",
                        className().c_str());
      return static_cast<T>(0);
  }
}

template <typename T>
T MxArray::at(mwIndex row, mwIndex column) const {
  return at<T>(subs(row, column));
}

template <typename T>
T MxArray::at(const std::vector<mwIndex>& subscripts) const {
  return at<T>(subs(subscripts));
}

template <typename T>
void MxArray::set(mwIndex index, const T& value) {
  if (mutable_array_ == NULL)
    mexErrMsgIdAndTxt("mxarray:error", "Null pointer exception.");
  if (numel() <= index)
    mexErrMsgIdAndTxt("mxarray:error",
                      "Index out of range: %d of %d.",
                      index,
                      numel());
  if (isConst())
    mexErrMsgIdAndTxt("mxarray:error", "Cannot set value to a const MxArray.");
  switch (classID()) {
    case mxCHAR_CLASS:
      *(mxGetChars(mutable_array_)+index) = static_cast<mxChar>(value);
      break;
    case mxDOUBLE_CLASS:
      *(mxGetPr(mutable_array_)+index) = static_cast<double>(value);
      break;
    case mxINT8_CLASS:
      *(reinterpret_cast<int8_t*>(mxGetData(mutable_array_))+index) =
          static_cast<int8_t>(value);
      break;
    case mxUINT8_CLASS:
      *(reinterpret_cast<uint8_t*>(mxGetData(mutable_array_))+index) =
        static_cast<uint8_t>(value);
      break;
    case mxINT16_CLASS:
      *(reinterpret_cast<int16_t*>(mxGetData(mutable_array_))+index) =
        static_cast<int16_t>(value);
      break;
    case mxUINT16_CLASS:
      *(reinterpret_cast<uint16_t*>(mxGetData(mutable_array_))+index) =
        static_cast<uint16_t>(value);
      break;
    case mxINT32_CLASS:
      *(reinterpret_cast<int32_t*>(mxGetData(mutable_array_))+index) =
        static_cast<int32_t>(value);
      break;
    case mxUINT32_CLASS:
      *(reinterpret_cast<uint32_t*>(mxGetData(mutable_array_))+index) =
        static_cast<uint32_t>(value);
      break;
    case mxINT64_CLASS:
      *(reinterpret_cast<int64_t*>(mxGetData(mutable_array_))+index) =
        static_cast<int64_t>(value);
      break;
    case mxUINT64_CLASS:
      *(reinterpret_cast<uint64_t*>(mxGetData(mutable_array_))+index) =
        static_cast<uint64_t>(value);
      break;
    case mxSINGLE_CLASS:
      *(reinterpret_cast<float*>(mxGetData(mutable_array_))+index) =
        static_cast<float>(value);
      break;
    case mxLOGICAL_CLASS:
      *(mxGetLogicals(mutable_array_)+index) = static_cast<mxLogical>(value);
      break;
    default:
      mexErrMsgIdAndTxt("mxarray:error",
                        "Cannot convert %s to a scalar value.",
                        className().c_str());
  }
}

template <typename T>
void MxArray::set(mwIndex row, mwIndex column, const T& value) {
  set<T>(subs(row, column), value);
}

template <typename T>
void MxArray::set(const std::vector<mwIndex>& subscripts, const T& value) {
  set<T>(subs(subscripts), value);
}

template <typename T>
void MxArray::set(const std::string& field_name,
                  const T& value,
                  mwIndex index) {
  if (mutable_array_ == NULL)
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
  mxSetField(mutable_array_, index, field_name.c_str(),
             MxArray(value).getMutable());
}

/// Convert std::vector<char> to a char array.
/// @param values vector to be converted.
template <> MxArray::MxArray(const std::vector<char>& values);

/// Convert std::vector<bool> to a logical array.
/// @param values vector to be converted.
template <> MxArray::MxArray(const std::vector<bool>& values);

/// Convert std::vector<std::string> to a cell array.
/// @param values vector to be converted.
template <> MxArray::MxArray(const std::vector<std::string>& values);

/// Cell element accessor.
/// @param index index of the cell array.
/// @return MxArray of the element at index.
///
/// Example:
/// @code
///     MxArray cell_array(prhs[0]);
///     MxArray value = cell_array.at<MxArray>(0);
/// @endcod
template <> MxArray MxArray::at(mwIndex index) const;

/// Convert MxArray to std::vector<MxArray>.
/// @return std::vector<MxArray> value.
///
/// Example:
/// @code
///     MxArray cell_array(prhs[0]);
///     vector<MxArray> values;
///     cell_array.toVector<MxArray>(&values);
/// @endcod
template <> void MxArray::toVector(std::vector<MxArray>* values) const;

/// Convert MxArray to std::vector<std::string>.
/// @return std::vector<std::string> value.
///
/// Example:
/// @code
///     MxArray cell_array(prhs[0]);
///     vector<string> values;
///     cell_array.toVector<MxArray>(&values);
/// @endcod
template <> void MxArray::toVector(std::vector<std::string>* values) const;

} // namespace mex

#endif // __MXARRAY_H__
