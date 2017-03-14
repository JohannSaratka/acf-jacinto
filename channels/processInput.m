function I = processInput(I, colorSpace, adapthisteqFlag, smoothInput)
% Pre-process input
% Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/
  
if (~isempty(I)) && (~strcmp(colorSpace,'orig')) && (adapthisteqFlag||smoothInput)
  if adapthisteqFlag && ~isempty(I),
    if strcmp(colorSpace, 'yuv8')
        I(:,:,1)=adapthisteq(I(:,:,1)/255.0,'ClipLimit',2.0/255.0)*255.0;
    elseif strcmp(colorSpace, 'yuv')
        I(:,:,1)=adapthisteq(I(:,:,1),'ClipLimit',2.0/255.0);        
    else
        for c=1:size(I,3)
          I(:,:,c)=adapthisteq(I(:,:,c),'ClipLimit',2.0/255.0);   
        end
    end
  end
  
  if smoothInput,
    I=convTri(I,smoothInput);
  end
end

end

