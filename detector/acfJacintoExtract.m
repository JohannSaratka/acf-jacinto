function extractDir = acfJacintoExtract(extractDb, dataDir, vidList, vbbList, extractType, extractFormat, outputDir)
% extract training and testing images and ground truth
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2016-17 Texas Instruments.  [www.ti.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

typeList={'train', 'test'};
extractDir={{},{}};
for s=1:2, 
  targetDir = [outputDir filesep typeList{s}];     
  annoFolder = [targetDir filesep 'annotations'];
  imgFolder = [targetDir filesep 'images'];  
  if(extractDb),
    dbExtractList(dataDir,vidList{s},vbbList{s},targetDir,1,[],extractType,extractFormat);
  else
    if ~exist(annoFolder,'dir'), error(['Training data doesnt exist: ' annoFolder]); end
    if ~exist(imgFolder,'dir'), error(['Training data doesnt exist: ' imgFolder]); end       
  end
  extractDir{s}=struct('posImgDir',imgFolder,'posGtDir',annoFolder);
end

end
