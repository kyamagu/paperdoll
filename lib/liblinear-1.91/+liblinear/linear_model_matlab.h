#ifndef _LINEAR_MODEL_MATLAB_H
#define _LINEAR_MODEL_MATLAB_H

#ifdef __cplusplus
extern "C" {
#endif

const char *model_to_matlab_structure(mxArray *plhs[], struct model *model_);
const char *matlab_matrix_to_model(struct model *model_, const mxArray *matlab_struct);

#ifdef __cplusplus
}
#endif

#endif /* _LINEAR_MODEL_MATLAB_H */