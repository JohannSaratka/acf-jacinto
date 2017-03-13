function [M,Gx,Gy] = gradientMag( I, varargin )
% Compute gradient magnitude and orientation at each image location.
%
% If input image has k>1 channels and channel=0, keeps gradient with
% maximum magnitude (over all channels) at each location. Otherwise if
% channel is between 1 and k computes gradient for the given channel.
% If full==1 orientation is computed in [0,2*pi) else it is in [0,pi).
%
% If normRad>0, normalization is performed by first computing S, a smoothed
% version of the gradient magnitude, then setting: M = M./(S + normConst).
% S is computed by S = convTri( M, normRad ).
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  [M,Gx,Gy] = gradientMagFast( I )
%
% INPUTS
%  I          - [hxwxk] input k channel single image
%  clipGrad   - clip the gradients larger than this value
%
% OUTPUTS
%  M          - [hxw] gradient magnitude at each location
%  Gx         - [hxw] horizontal gradient
%  Gy         - [hxw] vertical gradient
%
% EXAMPLE
%  I=rgbConvert(imread('peppers.png'),'gray');
%  [Gx,Gy]=gradient2(I); M=sqrt(Gx.^2+Gy.^2); O=atan2(Gy,Gx);
%  full=0; [M1,Gx1,Gy1]=gradientMag(I);
%  D=abs(M-M1); mean2(D), if(full), o=pi*2; else o=pi; end
%  D=abs(O-O1); D(~M)=0; D(D>o*.99)=o-D(D>o*.99); mean2(abs(D))
%
% See also gradient, gradient2, gradientHistFast, convTri
%
% Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<1 || isempty(I)), M=single([]); Gx=M; Gy=M; return; end

[M,Gx,Gy]=gradientFastMex('gradientMagFast',I,varargin{:});

