if ~isdeployed()
    addpath(genpath(cd(cd('../')))); %cd(cd()) is a trick to get the full path from relative path
end

%% dataset
dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-INRIA';
tempDir = [tempdir filesep 'data'];
extractDb = 0;
vidList={ ...
          {'videos/set00/V000.seq', 'videos/set00/V001.seq'}, ...
          {'videos/set01/V000.seq'} ...
       };
vbbList={ ...
          {'annotations/set00/V000.vbb', 'annotations/set00/V001.vbb'}, ...
          {'annotations/set01/V000.vbb'} ...
        };  
       
%% extract training and testing images and ground truth
typeList={'train', 'test'};
extractDir={{},{}};
for s=1:2, 
  targetDir = [tempDir filesep typeList{s}];     
  annoFolder = [targetDir filesep 'annotations'];
  imgFolder = [targetDir filesep 'images'];  
  if(extractDb),
    dbExtractList(dataDir,vidList{s},vbbList{s},targetDir);
  else
    if ~exist(annoFolder,'dir'), error(['Training data doesnt exist: ' annoFolder]); end
    if ~exist(imgFolder,'dir'), error(['Training data doesnt exist: ' imgFolder]); end       
  end
  extractDir{s}=struct('posImgDir',imgFolder,'posGtDir',annoFolder);
end

%% train and test
acfJacintoTrainTest(extractDir);

%% evaluation and comparison with other results
%expNum = 1; %19: Ht56 onwards, 1: (default) 50 onwards
%dbEval(dataDir, expNum);