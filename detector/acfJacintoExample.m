if ~isdeployed()
    addpath(genpath(cd(cd('../')))); %cd(cd()) is a trick to get the full path from relative path
end

dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-INRIA';
tempDir = [tempdir filesep 'data'];
extractDb = 0;

acfJacintoDemoInria(dataDir, tempDir, extractDb);

%expNum = 1; %19: Ht56 onwards, 1: (default) 50 onwards
%dbEval(dataDir, expNum);