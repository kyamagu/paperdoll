#ifndef _LINEAR_MODEL_MATLAB_H
#define _LINEAR_MODEL_MATLAB_H

#include <mex.h>

EXTERN_C const char *model_to_matlab_structure(mxArray *plhs[], struct model *model_);
EXTERN_C const char *matlab_matrix_to_model(struct model *model_, const mxArray *matlab_struct);

#endif /* _LINEAR_MODEL_MATLAB_H */
