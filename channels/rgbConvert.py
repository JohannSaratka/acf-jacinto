import numpy as np

from _channels import rgbConvertMex
from color_space import ColorSpace


     
def rgbConvert(I:np.array, 
               color_space: ColorSpace, 
               adapthisteqFlag: bool = False, 
               smoothInput: bool = False, 
               useSingle: bool = True
               ) -> np.array:
    """
     Convert RGB image to other color spaces (highly optimized).
    
     If colorSpace=='gray' transforms I to grayscale. The output is within
     numerical error of Matlab's rgb2gray, except ~10x faster. The output in
     this case is hxwx1, and while the input must be hxwx3 for all other
     cases, the input for this case can also be hxwx1 (normalization only).
    
     If colorSpace=='hsv' transforms I to the HSV color space. The output is
     within numerical error of Matlab's rgb2hsv, except ~15x faster.
    
     If colorSpace=='rgb' or colorSpace='orig' only normalizes I to be in the
     range [0,1]. In this case both the input and output may have an arbitrary
     number of channels (that is I may be [hxwxd] for any d).
    
     If colorSpace=='luv' transforms I to the LUV color space. The LUV color
     space is "perceptually uniform" (meaning that two colors equally distant
     in the color space according to the Euclidean metric are equally distant
     perceptually). The L,u,v channels correspond roughly to luminance,
     green-red, blue-yellow. For more information see:
       http://en.wikipedia.org/wiki/CIELUV - using this color spaces
       http://en.wikipedia.org/wiki/CIELAB - more info about color spaces
     The LUV channels are normalized to fall in ~[0,1]. Without normalization
     the ranges are L~[0,100], u~[-88,182], and v~[-134,105] (and typically
     u,v~[-100,100]). The applied transformation is L=L/270, u=(u+88)/270, and
     v=(v+134)/270. This results in ranges L~[0,.37], u~[0,1], and v~[0,.89].
     Perceptual uniformity is maintained since divisor is constant
     (normalizing each color channel independently would break uniformity).
     To undo the normalization on an LUV image J use:
       J=J*270; J(:,:,2)=J(:,:,2)-88; J(:,:,3)=J(:,:,3)-134;
     To test the range of the colorSpace use:
       R=100; I=zeros(R^3,1,3); k=1; R=linspace(0,1,R);
       for r=R, for g=R, for b=R, I(k,1,:)=[r g b]; k=k+1; end; end; end
       J=rgbConvert(I,'luv'); [min(J), max(J)]
    
     This code requires SSE2 to compile and run (most modern Intel and AMD
     processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
    
     USAGE
      J = rgbConvert( I, colorSpace, [useSingle] );
    
     INPUTS
      I          - [hxwx3] input rgb image (uint8 or single/double in [0,1])
      colorSpace - ['luv'] other choices include: 'gray', 'hsv', 'rgb', 'orig'
      useSingle  - [true] determines output type (faster if useSingle)
    
     OUTPUTS
      J          - [hxwx3] single or double output image (normalized to [0,1])
    
     EXAMPLE - luv
      I = imread('peppers.png');
      tic, J = rgbConvert( I, 'luv' ); toc
      figure(1); montage2( J );
    
     EXAMPLE - hsv
      I=imread('peppers.png');
      tic, J1=rgb2hsv( I ); toc
      tic, J2=rgbConvert( I, 'hsv' ); toc
      mean2(abs(J1-J2))
    
     EXAMPLE - gray
      I=imread('peppers.png');
      tic, J1=rgb2gray( I ); toc
      tic, J2=rgbConvert( I, 'gray' ); toc
      J1=single(J1)/255; mean2(abs(J1-J2))
    
     See also rgb2hsv, rgb2gray
    
     Piotr's Computer Vision Matlab Toolbox      Version 3.02
     Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
     Licensed under the Simplified BSD License [see external/bsd.txt]
    """
    
    if(useSingle):
        outClass = np.dtype(np.single)
    else:
        outClass = np.dtype(np.double)
        
    if((I.size == 0) and (color_space is not ColorSpace.gray) and (color_space is not ColorSpace.orig)):
        I = I[:, :, [1, 1, 1]]
        
    d = I.shape[2]
    
    if(color_space is ColorSpace.orig):
        color_space = ColorSpace.rgb 
    
    norm = (d == 1 and (color_space is ColorSpace.gray)) or (color_space is ColorSpace.rgb)
    if(norm and (I.dtype is outClass)):
      return I.copy()
    
    if(color_space is ColorSpace.yuv or color_space is ColorSpace.yuv8):
        J = rgb2yuvFunc(I); 
        if(useSingle): 
            scale = 1.0;
            if((I.dtype is np.uint8) and (color_space is ColorSpace.yuv)):
                scale = 1.0 / 256; 
            elif((I.dtype is not np.uint8)  and (color_space is ColorSpace.yuv8)):
                scale = 256.0
            J = single(J) * scale;
 
    else:
        J = rgbConvertMex(I, color_space, useSingle);
        
    J = processInput(J, color_space, adapthisteqFlag, smoothInput);
    return J


def rgb2ycbcrFunc(X):
  return rgb2ycbcr(X)


def rgb2yuvFunc(X):
    if X.size != 0:
        justABreakPoint = 1;
    
    Y = np.zeros(X.shape());
    X1 = single(X);
    Y[:, :, 1] = (0.299 * X1[:, :, 1] + 0.587 * X1[:, :, 2] + 0.114 * X1[:, :, 3]);
    Y[:, :, 2] = (-0.147108 * X1[:, :, 1] - 0.288804 * X1[:, :, 2] + 0.435915 * X1[:, :, 3]);
    Y[:, :, 3] = (0.614777 * X1[:, :, 1] - 0.514799 * X1[:, :, 2] - 0.099978 * X1[:, :, 3]);
    
    if X.dtype is np.uint8:
        offset = 128
        clip = 255
        should_round = True
    elif X.dtype is np.uint16:
        offset = 32768
        clip = 65535
        should_round = True
    elif(max(X[:] > 1)): 
        offset = 128
        clip = 255
        should_round = True
    else:
        offset = 0.5
        clip = 1.0
        should_round = False
        
    if should_round:
        Y[:, :, 1] = uint8(max(min(round(Y[:, :, 1] + 0), clip), 0));
        Y[:, :, 2] = uint8(max(min(round(Y[:, :, 2] + offset), clip), 0));
        Y[:, :, 3] = uint8(max(min(round(Y[:, :, 3] + offset), clip), 0));      
    else:
        Y[:, :, 1] = max(min(Y[:, :, 1] + 0, clip), 0);
        Y[:, :, 2] = max(min(Y[:, :, 2] + offset, clip), 0);
        Y[:, :, 3] = max(min(Y[:, :, 3] + offset, clip), 0);        
    
    if X.dtype is np.uint8:
        Y = uint8(Y)
    elif X.dtype is np.uint16:
        Y = uint16(Y)
        
    return Y
