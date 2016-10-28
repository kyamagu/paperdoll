#include <stdlib.h>
#include <string.h>
#include "../linear.h"
#include "linear_model_matlab.h"

#include "mex.h"

#ifdef MX_API_VER
#if MX_API_VER < 0x07030000
typedef int mwIndex;
#endif
#endif

#define Malloc(type,n) (type *)malloc((n)*sizeof(type))

#define NUM_OF_RETURN_FIELD 6

static const char *field_names[] = {
	"Parameters",
	"nr_class",
	"nr_feature",
	"bias",
	"Label",
	"w",
};

const char *model_to_matlab_structure(mxArray *plhs[], struct model *model_)
{
	int i;
	int nr_w;
	double *ptr;
	mxArray *return_model, **rhs = NULL;
	mxArray *model_field = NULL;
	int out_id = 0;
	int n, w_size;

	rhs = (mxArray **)mxMalloc(sizeof(mxArray *)*NUM_OF_RETURN_FIELD);
	if(!rhs)
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	for (i = 0; i < NUM_OF_RETURN_FIELD; i++)
		rhs[i] = NULL;

	// Parameters
	// for now, only solver_type is needed
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	if(!rhs[out_id])
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model_->param.solver_type;
	out_id++;

	// nr_class
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	if(!rhs[out_id])
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model_->nr_class;
	out_id++;

	if(model_->nr_class==2 && model_->param.solver_type != MCSVM_CS)
		nr_w=1;
	else
		nr_w=model_->nr_class;

	// nr_feature
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	if(!rhs[out_id])
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model_->nr_feature;
	out_id++;

	// bias
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	if(!rhs[out_id])
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model_->bias;
	out_id++;

	if(model_->bias>=0)
		n=model_->nr_feature+1;
	else
		n=model_->nr_feature;

	w_size = n;
	// Label
	if(model_->label)
	{
		rhs[out_id] = mxCreateDoubleMatrix(model_->nr_class, 1, mxREAL);
		if(!rhs[out_id])
			mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < model_->nr_class; i++)
			ptr[i] = model_->label[i];
	}
	else
	{
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
		if (!rhs[out_id])
			mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	}
	out_id++;

	// w
	rhs[out_id] = mxCreateDoubleMatrix(nr_w, w_size, mxREAL);
	if(!rhs[out_id])
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
	ptr = mxGetPr(rhs[out_id]);
	for(i = 0; i < w_size*nr_w; i++)
		ptr[i]=model_->w[i];
	out_id++;

	/* Create a struct matrix contains NUM_OF_RETURN_FIELD fields */
	return_model = mxCreateStructMatrix(1, 1, NUM_OF_RETURN_FIELD, field_names);
	if(!return_model)
		mexErrMsgIdAndTxt("liblinear:error","malloc failed.");

	/* Fill struct matrix with input arguments */
	for(i = 0; i < NUM_OF_RETURN_FIELD; i++)
	{
		model_field = mxDuplicateArray(rhs[i]);
		if(!model_field)
			mexErrMsgIdAndTxt("liblinear:error","malloc failed.");
		mxSetField(return_model,0,field_names[i],model_field);
	}
	/* return */
	plhs[0] = return_model;
	for(i = 0; i < NUM_OF_RETURN_FIELD; i++)
		mxDestroyArray(rhs[i]);
	mxFree(rhs);

	return NULL;
}

const char *matlab_matrix_to_model(struct model *model_, const mxArray *matlab_struct)
{
	int i, num_of_fields;
	int nr_w;
	double *ptr;
	int id = 0;
	int n, w_size;
	mxArray **rhs;

	num_of_fields = mxGetNumberOfFields(matlab_struct);
	rhs = (mxArray **) mxMalloc(sizeof(mxArray *)*num_of_fields);

	for(i=0;i<num_of_fields;i++)
		rhs[i] = mxGetFieldByNumber(matlab_struct, 0, i);

	model_->nr_class=0;
	nr_w=0;
	model_->nr_feature=0;
	model_->w=NULL;
	model_->label=NULL;

	// Parameters
	ptr = mxGetPr(rhs[id]);
	model_->param.solver_type = (int)ptr[0];
	id++;

	// nr_class
	ptr = mxGetPr(rhs[id]);
	model_->nr_class = (int)ptr[0];
	id++;

	if(model_->nr_class==2 && model_->param.solver_type != MCSVM_CS)
		nr_w=1;
	else
		nr_w=model_->nr_class;

	// nr_feature
	ptr = mxGetPr(rhs[id]);
	model_->nr_feature = (int)ptr[0];
	id++;

	// bias
	ptr = mxGetPr(rhs[id]);
	model_->bias = (int)ptr[0];
	id++;

	if(model_->bias>=0)
		n=model_->nr_feature+1;
	else
		n=model_->nr_feature;
	w_size = n;

	// Label
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model_->label = Malloc(int, model_->nr_class);
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<model_->nr_class;i++)
			model_->label[i] = (int)ptr[i];
	}
	id++;

	ptr = mxGetPr(rhs[id]);
	model_->w=Malloc(double, w_size*nr_w);
	for(i = 0; i < w_size*nr_w; i++)
		model_->w[i]=ptr[i];
	id++;
	mxFree(rhs);

	return NULL;
}

