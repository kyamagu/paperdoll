/// MEX function helper library.
///
/// This helper contains MEX_FUNCTION() macro to help create a set of matlab
/// mex functions. Two files are required to create a new mex function. Suppose
/// you are creating a mex function `myfunc`. Then, make the following files.
/// 
/// myfunc.m
///
/// This file contains help documentation and a line to invoke the mex
/// function. The contents of the file look like the following.
///
///     function [ output_args ] = myfunc( input_args )
///     %MYFUNC Description of the function.
///     %
///     %   Details go here.
///     %
///       output_args = mex_function_(mfilename, input_args)
///     end
///
/// private/myfunc.cc
///
/// This file is the implementation of the mex function. The MEX_FUNCTION macro
/// defines an entry point of the function. The file content would look like
/// the following.
///
///     #include "mex/function.h"
///     
///     MEX_FUNCTION(myfunc) (int nlhs,
///                           mxArray* plhs[],
///                           int nrhs,
///                           const mxArray* prhs[]) {
///       if (nrhs != 1 || nlhs > 1)
///         mexErrMsgTxt("Wrong number of arguments.");
///       ...
///     }
///
/// Kota Yamaguchi 2013 <kyamagu@cs.stonybrook.edu>

#ifndef __MEX_FUNCTION_H__
#define __MEX_FUNCTION_H__

#include <map>
#include <mex.h>
#include <string>

namespace mex {

/// Abstract operation class. Child class must implement operator().
class Operation {
public:
  /// Destructor.
  virtual ~Operation() {}
  /// Execute the operation.
  virtual void operator()(int nlhs,
                          mxArray *plhs[],
                          int nrhs,
                          const mxArray *prhs[]) = 0;
};

/// Base class for operation creators.
class OperationCreator {
public:
  /// Register an operation in the constructor.
  OperationCreator(const std::string& name);
  /// Destructor.
  virtual ~OperationCreator();
  /// Implementation must return a new instance of the operation.
  virtual Operation* create() = 0;
};

/// Implementation of the operation creator to be used as composition in an
/// Operator class.
template <class OperationClass>
class OperationCreatorImpl : public OperationCreator {
public:
  OperationCreatorImpl(const std::string& name) : OperationCreator(name) {}
  virtual Operation* create() { return new OperationClass; }
};

/// Factory class for operations.
class OperationFactory {
public:
  /// Register a new creator.
  static void define(const std::string& name, OperationCreator* creator);
  /// Create a new instance of the registered operation.
  static Operation* create(const std::string& name);

private:
  /// Obtain a pointer to the registration table.
  static std::map<std::string, OperationCreator*>* registry();
};

} // namespace mex

/// Define a MEX API function. Example:
///
/// MEX_FUNCTION(myfunc) (int nlhs, mxArray *plhs[],
///                  int nrhs, const mxArray *prhs[]) {
///   if (nrhs != 1 || nlhs > 1)
///     mexErrMsgTxt("Wrong number of arguments.");
///   ...
/// }
///
#define MEX_FUNCTION(name) \
class Operation_##name : public mex::Operation { \
public: \
  virtual void operator()(int nlhs, \
                          mxArray *plhs[], \
                          int nrhs, \
                          const mxArray *prhs[]); \
private: \
  static const mex::OperationCreatorImpl<Operation_##name> creator_; \
}; \
const mex::OperationCreatorImpl<Operation_##name> \
    Operation_##name::creator_(#name); \
void Operation_##name::operator()

#endif // __MEX_FUNCTION_H__