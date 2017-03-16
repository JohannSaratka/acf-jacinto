if ~isdeployed()
    addpath(genpath(cd(cd('../')))); %cd(cd()) is a trick to get the full path from relative path
end

dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-INRIA';
tempDir = [tempdir filesep 'data'];
extractDb = 1;
vidList={ ...
          {'videos/set00/V000.seq', 'videos/set00/V001.seq'}, ...
          {'videos/set01/V000.seq'} ...
       };
vbbList={ ...
          {'annotations/set00/V000.vbb', 'annotations/set00/V001.vbb'}, ...
          {'annotations/set01/V000.vbb'} ...
        };  
       
acfJacintoDemoInria(dataDir, tempDir, extractDb, vidList, vbbList);

%expNum = 1; %19: Ht56 onwards, 1: (default) 50 onwards
%dbEval(dataDir, expNum);