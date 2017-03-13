/*******************************************************************************
* Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
* Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include <math.h>
#include <limits>
#include <algorithm>
#include "string.h"

#define PI 3.14159265f

void gradMagFast( float *I, float *M, float *Gx, float *Gy, int h, int w, int d, float clipGrad) {
  for( int x=0; x<w; x++ ) {
    float *Icur = &I[x*h];     
    float *Mcur = &M[x*h];       
    float *Gxcur = Gx? &Gx[x*h] : NULL;        
    float *Gycur = Gy? &Gy[x*h] : NULL;         
    for( int y=0; y<h; y++ ) {
      float gx=0, gy=0;
      if(x>0 && x<(w-1)) { 
        gx = (Icur[y+h]-Icur[y-h]);
      } else if(x==0) {
        gx = (Icur[y+h]-Icur[y+0]);              
      } else if(x==(w-1)) {
        gx = (Icur[y+0]-Icur[y-h]);               
      }
      if(y>0 && y<(h-1)) { 
        gy = (Icur[y+1]-Icur[y-1]);
      } else if(y==0) {
        gy = (Icur[y+1]-Icur[y+0]);              
      } else if(y==(w-1)) {
        gy = (Icur[y+0]-Icur[y-1]);               
      }
      float mag = std::abs(gx) + std::abs(gy);
      Mcur[y] = std::min<float>(mag, clipGrad);

      if(Gx) {
        Gxcur[y] = gx;
      }
      if(Gy) {
        Gycur[y] = gy;
      }
    }
  }
}


// compute nOrients gradient histograms per bin x bin block of pixels
void gradHistFast( float *M, float *Gx, float *Gy, float *H, int h, int w, const int nOrients, const int cellSize)
{
  const int maxOrients = 9;
  if(nOrients>maxOrients) {
    mexErrMsgTxt("Invalid number of orientations.");      
  }
  float phaseMin = 0;
  float phaseMax = PI; //full 2PI is not supported
  float delta = (phaseMax - phaseMin) / nOrients;
  float delta2 = delta / 2;
  float sineLUT[maxOrients], cosineLUT[maxOrients];
  for (int i = 0; i < nOrients; i++) {
    sineLUT[i] = std::sin(delta2 + i * delta);
    cosineLUT[i] = std::cos(delta2 + i * delta);
  }
  
  auto computeHogBin = [&](float gx, float gy) {
    int thetaIdx = 0;
    float bestErr = std::numeric_limits<float>::max();
    for (int i = 0; i < nOrients; i++) {
      float err = std::abs(gy * cosineLUT[i] - gx * sineLUT[i]);
      if (err < bestErr) {
        thetaIdx = i;
        bestErr = err;
      }
    }
    int bin = ((gy == 0) ? (gx > 0 ? 0 : (nOrients - 1)) : thetaIdx);
    return bin;
  };
    
  //main loop
  if(cellSize == 1) {
    for( int x=0; x<w; x++ ) {
      float *Gxptr = &Gx[x*h];    
      float *Gyptr = &Gy[x*h];     
      float *Mptr = &M[x*h];          
      for(int y=0; y<h; y++) {
        float gx = Gxptr[y];
        float gy = Gyptr[y];      
        int orientBin = computeHogBin(gx, gy);
        H[orientBin*w*h+x*h+y] = Mptr[y];
      }
    }
  } else {
    int hb = (int)std::floor(h/cellSize);
    int wb = (int)std::floor(w/cellSize);      
    for( int x=0; x<w; x++ ) {
      float *Gxptr = &Gx[x*h];    
      float *Gyptr = &Gy[x*h];     
      float *Mptr = &M[x*h];     
      int xb = (int)std::floor(x/cellSize);
      for(int y=0; y<h; y++) {
        float gx = Gxptr[y];
        float gy = Gyptr[y];      
        int orientBin = computeHogBin(gx, gy);
        int yb = (int)std::floor(y/cellSize);        
        H[orientBin*wb*hb+xb*hb+yb] += Mptr[y];
      }
    }      
  }
}

/******************************************************************************/
#ifdef MATLAB_MEX_FILE
// Create [hxwxd] mxArray array
mxArray* mxCreateMatrix3( int h, int w, int d, mxClassID id, void **Mptr ){
  const int dims[3]={h,w,d}, n=h*w*d; int b; 
  mxArray* M;
  
  if( id==mxINT32_CLASS ) b=sizeof(int);
  else if( id==mxDOUBLE_CLASS ) b=sizeof(double);
  else if( id==mxSINGLE_CLASS ) b=sizeof(float);
  else mexErrMsgTxt("Unknown mxClassID.");
  
  *Mptr = mxCalloc(n,b);
  M = mxCreateNumericMatrix(0,0,id,mxREAL);
  mxSetData(M,*Mptr); mxSetDimensions(M,dims,3); 
  return M;
}

// Check inputs and outputs to mex, retrieve first input I
void checkArgs( int nl, mxArray *pl[], int nr, const mxArray *pr[], int nl0,
  int nl1, int nr0, int nr1, int *h, int *w, int *d, mxClassID id, void **I )
{
  const int *dims; int nDims;
  if( nl<nl0 || nl>nl1 ) mexErrMsgTxt("Incorrect number of outputs.");
  if( nr<nr0 || nr>nr1 ) mexErrMsgTxt("Incorrect number of inputs.");
  nDims = mxGetNumberOfDimensions(pr[0]); dims = mxGetDimensions(pr[0]);
  *h=dims[0]; *w=dims[1]; *d=(nDims==2) ? 1 : dims[2]; *I = mxGetPr(pr[0]);
  if( nDims!=2 && nDims!=3 ) mexErrMsgTxt("I must be a 2D or 3D array.");
  if( mxGetClassID(pr[0])!=id ) mexErrMsgTxt("I has incorrect type.");
}

// [M, [Gx, Gy]]=gradMag(I0) - see gradientMag.m
void mGradMagFast( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d; float *I, *M=0, *Gx=0, *Gy=0;
  checkArgs(nl,pl,nr,pr,1,3,1,3,&h,&w,&d,mxSINGLE_CLASS,(void**)&I);
  if(h<2 || w<2) mexErrMsgTxt("I must be at least 2x2.");
  
  pl[0] = mxCreateMatrix3(h,w,1,mxSINGLE_CLASS,(void**)&M);
  if(nl>1) pl[1] = mxCreateMatrix3(h,w,1,mxSINGLE_CLASS,(void**)&Gx);
  if(nl>2) pl[2] = mxCreateMatrix3(h,w,1,mxSINGLE_CLASS,(void**)&Gy);  
  
  float clipGrad = std::numeric_limits<float>::max();
  if(nr>1) clipGrad = (float)mxGetScalar(pr[1]); 
  
  gradMagFast(I, M, Gx, Gy, h, w, d, clipGrad);
}

// H=gradHist(M,Gx,Gy,nOrients) - see gradientHist.m
void mGradHistFast( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d;
  float *M, *Hist;
  checkArgs(nl,pl,nr,pr,1,1,3,5,&h,&w,&d,mxSINGLE_CLASS,(void**)&M);
  float *Gx = (float*) mxGetPr(pr[1]);
  float *Gy = (float*) mxGetPr(pr[2]);  
  
  if( mxGetM(pr[1])!=h || mxGetN(pr[1])!=w || d!=1 ||
    mxGetClassID(pr[1])!=mxSINGLE_CLASS ) mexErrMsgTxt("M or Gx is bad.");
  if( mxGetM(pr[2])!=h || mxGetN(pr[2])!=w || d!=1 ||
    mxGetClassID(pr[1])!=mxSINGLE_CLASS ) mexErrMsgTxt("M or Gy is bad.");
  
  int nOrients = (nr>=4) ? (int)   mxGetScalar(pr[3])    : 9;
  int cellSize = (nr>=5) ? (int)   mxGetScalar(pr[4])    : 1;
  
  pl[0] = mxCreateMatrix3(h,w,nOrients,mxSINGLE_CLASS,(void**)&Hist);

  gradHistFast( M, Gx, Gy, Hist, h, w, nOrients, cellSize);
}

// inteface to various gradient functions (see corresponding Matlab functions)
void mexFunction( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int f; char action[1024]; f=mxGetString(pr[0],action,1024); nr--; pr++;
  if(f) mexErrMsgTxt("Failed to get action.");
  else if(!strcmp(action,"gradientMagFast")) mGradMagFast(nl,pl,nr,pr);  
  else if(!strcmp(action,"gradientHistFast")) mGradHistFast(nl,pl,nr,pr);
  else mexErrMsgTxt("Invalid action.");
}
#endif
