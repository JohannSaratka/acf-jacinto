function H = gradientHist( M, Gx, Gy, varargin )
% Compute oriented gradient histograms.
%
% For each binSize x binSize region in an image I, computes a histogram of
% gradients, with each gradient quantized by its angle and weighed by its
% magnitude. If I has dimensions [hxw], the size of the computed feature
% vector H is floor([h/binSize w/binSize nOrients]).
%
% This function implements the gradient histogram features described in:
%   P. Dollár, Z. Tu, P. Perona and S. Belongie
%   "Integral Channel Features", BMVC 2009.
% These features in turn generalize the HOG features introduced in:
%   N. Dalal and B. Triggs, "Histograms of Oriented
%   Gradients for Human Detection," CVPR 2005.
% Setting parameters appropriately gives almost identical features to the
% original HOG or updated FHOG features, see hog.m and fhog.m for details.
%
% The input to the function are the gradient magnitude M and orientation O
% at each image location. See gradientMag.m for computing M and O from I.
%
% The first step in computing the gradient histogram is simply quantizing
% the magnitude M into nOrients [hxw] orientation channels according to the
% gradient orientation. The magnitude at each location is placed into the
% two nearest orientation bins using linear interpolation if softBin >= 0
% or simply to the nearest orientation bin if softBin < 0. Next, spatial
% binning is performed by summing the pixels in each binSize x binSize
% region of each [hxw] orientation channel. If "softBin" is odd each pixel
% can contribute to multiple spatial bins (using bilinear interpolation),
% otherwise each pixel contributes to a single spatial bin. The result of
% these steps is a floor([h/binSize w/binSize nOrients]) feature map
% representing the gradient histograms in each image region.
%
%
% USAGE
%  H = gradientHist( M, Gx, Gy )
%
% INPUTS
%  M        - [hxw] gradient magnitude at each location (see gradientMag.m)
%  Gx       - [hxw] horizontal gradient
%  Gy       - [hxw] vertical gradient
%  nOrients - [9]   number of orientations
%  accurate - [false]   accurate or not
%
% OUTPUTS
%  H        - [w x h x nOrients] gradient histograms
%
% EXAMPLE
%  I=rgbConvert(imread('peppers.png'),'gray'); [M,Gx,Gy]=gradientMagFast(I);
%  H1=gradientHistFast(M,Gx,Gy,6); figure(1); montage2(H1);
%
% See also gradientMag, gradient2, hog, fhog
%
% Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Licensed under the Simplified BSD License [see external/bsd.txt]
%
%
% Copyright 2017 Texas Instruments. [www.ti.com] All rights reserved.

if(nargin<1 || isempty(M)), M=single([]); H=M; return; end

H = gradientFastMex('gradientHistFast',M,Gx,Gy,varargin{:});
