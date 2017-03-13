function cellSum = chnsCellSum(data, stepSize, cellSize, h, w)
% Compute cell sum
% Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/

  if h==0 ||  w==0,
      sz=size(data);
      if length(sz)>2, ch=sz(3); else ch=1;end
      cellSum=zeros(h,w,ch);
      return;
  end
  cellSum = chnsCellSumMex(data, stepSize, cellSize, h, w);
end
