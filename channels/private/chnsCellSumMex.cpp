/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.00
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include "string.h"
#include <math.h>
#include <typeinfo>
#include <algorithm>
#include "sse.hpp"
typedef unsigned char uchar;


// resample A using bilinear interpolation and and store result in B
template<class T>
void cellsum( T *A, T *B, int ha, int hb, int wa, int wb, int d, int stepSize, int cellSize) {
  //mexPrintf("ha=%, hb=%d, wa=%d, wb=%d, d=%d, stepSize=%d, cellSize=%d\n",ha, hb, wa, wb, d, stepSize, cellSize);
  for( int z=0; z<d; z++ ) {
    T *aChan=&A[z*wa*ha];
    T *bChan=&B[z*wb*hb];    
    for( int x=0; x<wb; x++ ) {
	  for( int y=0; y<hb; y++ ) {
	    int xStart= std::min<int>(x*stepSize,wa);
	    int xEnd=std::min<int>(xStart+cellSize,wa);
	    int yStart= std::min<int>(y*stepSize,ha);
	    int yEnd=std::min<int>(yStart+cellSize,ha);
	    T bVal = 0;
	    for(int col=xStart; col<xEnd; col++) {
          for(int row=yStart; row<yEnd; row++) {
		    bVal += aChan[col*ha+row];
          }
	    }
	    bChan[x*hb+y] = bVal;
      }
	}
  }
}

// B = imResampleMex(A,hb,wb,nrm); see imResample.m for usage details
#ifdef MATLAB_MEX_FILE
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int *ns, ms[3], n, m, nCh, nDims;
  void *A, *B; mxClassID id;

  // Error checking on arguments
  if( nrhs!=5) mexErrMsgTxt("Five inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  
  nDims=mxGetNumberOfDimensions(prhs[0]); 
  id=mxGetClassID(prhs[0]);
  ns = (int*) mxGetDimensions(prhs[0]); 
  nCh=(nDims==2) ? 1 : ns[2];
  if( (nDims!=2 && nDims!=3) ||
    (id!=mxSINGLE_CLASS && id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D single, double or uint8 array.");
	
  int stepSize =(int)mxGetScalar(prhs[1]); //stepSize
  int cellSize =(int)mxGetScalar(prhs[2]); //cellSize
  int oh =(int)mxGetScalar(prhs[3]); //oh
  int ow =(int)mxGetScalar(prhs[4]); //ow  
  
  ms[0]=oh;
  ms[1]=ow;
  ms[2]=nCh;  
  // create output array
  plhs[0] = mxCreateNumericArray(3, (const mwSize*) ms, id, mxREAL);
  n=ns[0]*ns[1]*nCh; m=ms[0]*ms[1]*nCh;

  //mexPrintf("ns[0]=%, ms[0]=%d, ns[1]=%d, ms[1]=%d, nCh=%d, stepSize=%d, cellSize=%d\n",ns[0], ms[0], ns[1], ms[1], nCh, stepSize, cellSize);
  
  // perform resampling (w appropriate type)
  A=mxGetData(prhs[0]); B=mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) {
    cellsum((double*)A, (double*)B, ns[0], ms[0], ns[1], ms[1], nCh, stepSize, cellSize);
  } else if( id==mxSINGLE_CLASS ) {
    cellsum((float*)A, (float*)B, ns[0], ms[0], ns[1], ms[1], nCh, stepSize, cellSize);
  } else if( id==mxUINT8_CLASS ) {
    float *A1 = (float*) mxMalloc(n*sizeof(float));
    float *B1 = (float*) mxCalloc(m,sizeof(float));
    for(int i=0; i<n; i++) A1[i]=(float) ((uchar*)A)[i];
    cellsum(A1, B1, ns[0], ms[0], ns[1], ms[1], nCh, stepSize, cellSize);
    for(int i=0; i<m; i++) ((uchar*)B)[i]=(uchar) (B1[i]+.5);
	mxFree(A1);	mxFree(B1);
  } else {
    mexErrMsgTxt("Unsupported type.");
  }
}
#endif
