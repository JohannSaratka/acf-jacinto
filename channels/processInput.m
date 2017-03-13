function I = processInput(I, colorSpace, adapthisteqFlag, smoothInput)
% Pre-process input
% Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/
  
if (~strcmp(colorSpace, 'orig')) && (~isempty(I))
  if adapthisteqFlag && ~isempty(I),
    if strcmp(colorSpace, 'yuv8')
        I(:,:,1)=adapthisteq(I(:,:,1)/255.0,'ClipLimit',2.0/255.0)*255.0;
    elseif strcmp(colorSpace, 'yuv')
        I(:,:,1)=adapthisteq(I(:,:,1),'ClipLimit',2.0/255.0);        
    else
        I=adapthisteq(I,'ClipLimit',2.0/255.0);                
    end
  end
  
  if smoothInput,
    I=convTri(I,smoothInput);
  end
end

end

