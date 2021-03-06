% Train and Test for aggregate channel features object detector on various datasets.
%
% See also acfReadme.m
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]
%
% Copyright 2017 Texas Instruments. [www.ti.com] All rights reserved.

function acfJacintoTrainTest(extractDir, exptName, config)
%Run training and test

if nargin < 1, extractDir={}; end
if nargin < 2, exptName=''; end
if nargin < 3, config=[]; end

%% set up opts for training detector (see acfTrain)
opts=acfTrain(); 
opts.posGtDir=extractDir{1}.posGtDir; 
opts.posImgDir=extractDir{1}.posImgDir; 

%opts.modelDs=[100 41]; opts.modelDsPad=[128 64];
%opts.modelDs=[56 24]; opts.modelDsPad=[64 32];
opts.modelDs=[56 24]; opts.modelDsPad=[64 64];

opts.nWeak=[32 128 512 2048];
opts.pJitter=struct('flip',1);
opts.pBoost.pTree.fracFtrs=1/16;
aRatio=opts.modelDs(2)/opts.modelDs(1);opts.pLoad={'squarify',{3,aRatio}}; 

%set eval range - optional
opts.pLoad = [opts.pLoad 'hRng',[opts.modelDs(1) inf], 'wRng',[opts.modelDs(2) inf]];
opts.name=['models/' exptName];
opts.pPyramid.pChns.pFastMode.enabled=1;           %default: 0
show=2;

if opts.pPyramid.pChns.pFastMode.enabled,   
  opts.cascThr=-1;                                 %default: -1
  opts.detThr=0;                                   %default: -1
  opts.cascCal=0;                                  %default: 0.005 or 0.01(below)
  opts.detOffset=0;                                %position offset for detection. default: 0 is best for quality.
  
  %opts.adjustPyramidPad=0;                        %pyramid padding adjustment in acfTrain(). Pyramid padding is better for accuracy.
  %opts.pPyramid.pad=[0,0];                        %default: ceil((opts.modelDsPad-opts.modelDs)/shrink/2)*shrink;  
  opts.pPyramid.nApprox=0;                         %default: -1 (fastest). This parameter affects the speed (and accuracy) a lot. 
  opts.pPyramid.smooth=0;                          %default: 1   
  
  opts.pPyramid.pChns.pFastMode.cellSize=8;        %default: 8          
  opts.pPyramid.pChns.pColor.smoothInput=1;        %default: 0, 1=>[1 2 1]/s filter
  opts.pPyramid.pChns.pColor.adapthisteq=1;        %default: 0
  
  opts.pPyramid.pChns.pColor.colorSpace='yuv8';    %default: luv
  opts.pPyramid.pChns.pColor.smooth=0;             %default: 1, 0 seems much better in jacinto config
  opts.pPyramid.pChns.pGradMag.normRad=0;          %default: 5, 0 is okay
  %opts.pPyramid.pChns.pGradMag.full=0;            %default: 0, 0 is better than 1
  %opts.pPyramid.pChns.pGradHist.softBin=-2;       %default: 0(spatial soft bin), -2: no soft bin, other, trilinear soft bin (best quality: -1)
  %opts.pPyramid.pChns.pGradHist.useHog=0;         %already set
  
  opts.nWeak=[32 128 512 1280 2048 2048];         %stages in training
  opts.nNeg=10000;                                %num negatives to be collected in a stage
  opts.nAccNeg=20000;                             %num accumulated negatives to be collected
  opts.bsOlap=0.01;                               %default: 0.1, best: 0.01, booststrap overlap for hard negative selection
else
  opts.cascCal=0.01;                              %default: 0.005 or 0.01(below)    
end

%override these settings from outside.
fields=fieldnames(opts);
for i=1:numel(fields)
  if isfield(config,fields{i}), 
      opts=setfield(opts, fields{i}, getfield(config,fields{i}));
  end
end

%% optionally switch to LDCF version of detector (see acfTrain)
if( 0 )
  opts.filters=[5 4]; opts.pJitter=struct('flip',1,'nTrn',3,'mTrn',1);
  opts.pBoost.pTree.maxDepth=3; opts.pBoost.discrete=0; opts.seed=2;
  opts.pPyramid.pChns.shrink=2; opts.name=['models/' exptName];
end

%% train detector (see acfTrain)
detector = acfTrain( opts );
acfSaveDescriptor([opts.name 'DetectorCompact.descriptor'],detector,true);
acfSaveDescriptor([opts.name 'DetectorCascade.descriptor'],detector,false);

%% modify detector (see acfModify)
pModify=struct('cascThr',-1,'cascCal',opts.cascCal, 'detThr',opts.detThr);
detector=acfModify(detector,pModify);

%% run detector on a sample image (see acfDetect)
if show,
  imgNms=bbGt('getFiles',{extractDir{2}.posImgDir});
  sampleImage=imgNms{1};
  %sampleImage='D:\files\work\data\object-detect\other\eth\seq03-img-left\image_00000000_0.png';
  imgNms=bbGt('getFiles',{extractDir{2}.posImgDir});
  I=imread(sampleImage); tic, bbs=acfDetect(I,detector); toc
  figure(1); im(I); bbApply('draw',bbs); pause(.1);
end

%% test detector and plot roc (see acfTest)
[miss,~,gt,dt]=acfTest('name',opts.name,'imgDir',extractDir{2}.posImgDir,...
  'gtDir',extractDir{2}.posGtDir,'pLoad',opts.pLoad,...
  'pModify',pModify,'reapply',0,'show',show);

%% optional timing test for detector (should be ~30 fps)
if( 0 )
  detector1=acfModify(detector,'pad',[0 0]); n=60; Is=cell(1,n);
  for i=1:n, Is{i}=imResample(imread(imgNms{i}),[480 640]); end
  tic, for i=1:n, acfDetect(Is{i},detector1); end;
  fprintf('Detector runs at %.2f fps on 640x480 images.\n',n/toc);
end

%% optionally show top false positives ('type' can be 'fp','fn','tp','dt')
if( 0 ), bbGt('cropRes',gt,dt,imgNms,'type','fp','n',50,...
    'show',3,'dims',opts.modelDs([2 1])); end
	
end