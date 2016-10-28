/**
 * @file pfsegment.cpp
 * @brief mex interface for Pedro Felzenszwalb's segmentation
 *
 * Usage:
 *   [segmentation, num_segments] = pfsegment(img, sigma, k, min_size);
 * Input:
 *           img: uint8 type H-by-W-by-3 RGB array
 *         sigma: scalar param used to smooth the input image before segmenting it
 *             k: scalar param for the threshold function
 *      min_size: param for minimum component size enforced by post-processing
 * Output:
 *  segmentation: double H-by-W-by-3 index array
 *  num_segments: number of segments in double scalar
 *
 * Kota Yamaguchi 2011
 */
#include <cstdio>
#include <cstdlib>
#include <memory>
#include "image.h"
#include "misc.h"
#include "pnmfile.h"
#include "segment-image.h"
#include "mex.h"

using namespace std;

namespace {

/**
 * Converts mxArray to image<rgb>
 * @param arr mxArray object
 * @return image<rgb> pointer
 */
image<rgb> *mxArrayToRGB(const mxArray *arr) {
	/* Be careful that image is transposed in mxArray */
	const mwSize *d = mxGetDimensions(arr);
	int width  = d[1];
	int height = d[0];
	int stride = width * height;
	image<rgb> *im = new image<rgb>(width, height);
	uchar *ptr = (uchar*)mxGetData(arr);
	for (int i = 0; i < width; i++)
		for (int j = 0; j < height; j++) {
			rgb pix;
			int loc = j + i*height;
			pix.r = ptr[loc           ];
			pix.g = ptr[loc +   stride];
			pix.b = ptr[loc + 2*stride];
			imRef(im,i,j) = pix;
		}
	return im;
}

/**
 * Converts image<rgb> to mxArray
 * @param arr mxArray object
 * @return image<rgb> pointer
 */
mxArray *RGBToMxArray(const image<rgb> *im) {
	/* Be careful that image is transposed in mxArray */
	int width = im->width();
	int height = im->height();
	int stride = width * height;
	mwSize d[3] = {0,0,3};
	d[0] = height;
	d[1] = width;
	mxArray* arr = mxCreateNumericArray(3, d, mxUINT8_CLASS, mxREAL);
	uchar *ptr = (uchar*)mxGetData(arr);
	for (int i = 0; i < width; i++)
		for (int j = 0; j < height; j++) {
			rgb pix = imRef(im,i,j);
			int loc = j + i*height;
			ptr[loc           ] = pix.r;
			ptr[loc +   stride] = pix.g;
			ptr[loc + 2*stride] = pix.b;
		}
	return arr;
}

/**
 * Converts image<int> to mxArray
 * @param arr mxArray object
 * @return mxArray pointer
 */
mxArray *ImageToMxArray(const image<int> *im) {
	/* Be careful that image is transposed in mxArray */
	int width = im->width();
	int height = im->height();
	mxArray* arr = mxCreateDoubleMatrix(height, width, mxREAL);
	double *ptr = (double*)mxGetPr(arr);
	for (int i = 0; i < width; i++)
		for (int j = 0; j < height; j++) {
			int pix = imRef(im,i,j);
			int loc = j + i*height;
			ptr[loc] = pix;
		}
	return arr;
}

} // namespace

/**
 * Main entry called from Matlab
 * @param nlhs number of left-hand-side arguments
 * @param plhs pointers to mxArrays in the left-hand-side
 * @param nrhs number of right-hand-side arguments
 * @param prhs pointers to mxArrays in the right-hand-side
 *
 * This is the entry point of the function
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	/* Check the input format */
	if(nrhs!=4 || nlhs!=1)
        	mexErrMsgIdAndTxt("mexsegment:invalidArgs","Wrong number of arguments");
	if (mxGetClassID(prhs[0])!=mxUINT8_CLASS)
        	mexErrMsgIdAndTxt("mexsegment:invalidArgs","Only UINT8 type is supported");
	if (mxGetNumberOfDimensions(prhs[0])!=3)
		mexErrMsgIdAndTxt("mexsegment:invalidArgs","Only RGB format is supported");
	
	/* Get options */
	float sigma = (float)mxGetScalar(prhs[1]);
	float k = (float)mxGetScalar(prhs[2]);
	int min_size = (int)mxGetScalar(prhs[3]);
    
	/* Convert mxArray to image */
	auto_ptr<image<rgb> > im = auto_ptr<image<rgb> >(mxArrayToRGB(prhs[0]));
	
	/* Compute segmentation */
	int num_ccs;
	auto_ptr<image<int> > seg = auto_ptr<image<int> >(
            segment_image_int(im.get(), sigma, k, min_size, &num_ccs));
	
	/* Convert image to mxArray */
	plhs[0] = ImageToMxArray(seg.get());
  if (nlhs > 1)
    plhs[1] = mxCreateDoubleScalar(num_ccs);
}
