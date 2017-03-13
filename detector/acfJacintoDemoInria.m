% Demo for aggregate channel features object detector on Inria dataset.
%
% See also acfReadme.m
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

function acfJacintoDemoInria(dataDir, tempDir, extractDb)


%% extract training and testing images and ground truth
cd(fileparts(which('acfJacintoDemoInria.m'))); 
if nargin == 0, dataDir='../../data/Inria/'; end
if nargin < 2, tempDir = tempdir; fprintf(1, 'tempDir=%s\n', tempDir); end
if nargin < 3, extractDb = 0; end 

if dataDir(end) ~= '/' && dataDir(end) ~= '\', dataDir = [dataDir filesep]; end
if tempDir(end) ~= '/' && tempDir(end) ~= '\', tempDir = [tempDir filesep]; end

for s=1:2, 
  if nargin ~= 0, pth=dbInfo('InriaTest', dataDir);
  else pth=dbInfo('InriaTest'); end
  if(s==1), set='00'; type='train'; else set='01'; type='test'; end
  posGtFolder = [tempDir type '/posGt'];
  posFolder = [tempDir type '/pos'];
  negFolder = [tempDir type '/neg'];  
  if(exist(posGtFolder,'dir')), 
      if extractDb,
          rmdir(posGtFolder, 's'); 
          rmdir(posFolder, 's'); 
          rmdir(negFolder, 's');  
      else continue; end
  end
  seqIo([pth '/videos/set' set '/V000'],'toImgs',posFolder);
  seqIo([pth '/videos/set' set '/V001'],'toImgs',negFolder);
  V=vbb('vbbLoad',[pth '/annotations/set' set '/V000']);
  vbb('vbbToFiles',V,[tempDir type '/posGt']);
end

%% set up opts for training detector (see acfTrain)
opts=acfTrain(); opts.modelDs=[56 24]; opts.modelDsPad=[64 64];
opts.posGtDir=[tempDir 'train/posGt']; opts.nWeak=[32 128 512 2048];
opts.posImgDir=[tempDir 'train/pos']; opts.pJitter=struct('flip',1);
opts.negImgDir=[tempDir 'train/neg']; opts.pBoost.pTree.fracFtrs=1/16;
opts.pLoad={'squarify',{3,.41}}; 
%set eval range - optional
opts.pLoad = [opts.pLoad 'hRng',[opts.modelDs(1) inf], 'wRng',[opts.modelDs(2) inf] ];
opts.name='models/AcfJacintoInria';
opts.pPyramid.pChns.pFastMode.enabled=1;           %default: 0
show=2;

if opts.pPyramid.pChns.pFastMode.enabled,      
  opts.pPyramid.smooth=0;                          %default: 1
  
  opts.pPyramid.pChns.pColor.smoothInput=0;        %default: 0
  opts.pPyramid.pChns.pColor.adapthisteq=0;        %default: 0
  
  opts.pPyramid.pChns.pColor.colorSpace='yuv8';    %default: luv
  opts.pPyramid.pChns.pColor.smooth=0;             %default: 1, 0 seems much better in jacinto config
  opts.pPyramid.pChns.pGradMag.normRad=0;          %default: 5, 0 is okay
  %opts.pPyramid.pChns.pGradMag.full=0;            %default: 0, 0 is better than 1
  opts.pPyramid.pChns.pGradHist.softBin=-2;        %default: 0(spatial soft bin), -2: no soft bin, other, trilinear soft bin (best quality: -1)
  %opts.pPyramid.pChns.pGradHist.useHog=0;         %already set
  
  show=2;%2 or 0
end

%% optionally switch to LDCF version of detector (see acfTrain)
if( 0 )
  opts.filters=[5 4]; opts.pJitter=struct('flip',1,'nTrn',3,'mTrn',1);
  opts.pBoost.pTree.maxDepth=3; opts.pBoost.discrete=0; opts.seed=2;
  opts.pPyramid.pChns.shrink=2; opts.name='models/LdcfJacintoInria';
end

%% train detector (see acfTrain)
detector = acfTrain( opts );
acfSaveDescriptor([opts.name 'Detector.descriptor'],detector);

%% modify detector (see acfModify)
pModify=struct('cascThr',-1,'cascCal',.01);
detector=acfModify(detector,pModify);

%% run detector on a sample image (see acfDetect)
if show,
  %sampleImage=imgNms{1};
  sampleImage='D:\files\work\data\object-detect\other\eth\seq03-img-left\image_00000000_0.png';
  imgNms=bbGt('getFiles',{[tempDir 'test/pos']});
  I=imread(sampleImage); tic, bbs=acfDetect(I,detector); toc
  figure(1); im(I); bbApply('draw',bbs); pause(.1);
end

%% test detector and plot roc (see acfTest)
[miss,~,gt,dt]=acfTest('name',opts.name,'imgDir',[tempDir 'test/pos'],...
  'gtDir',[tempDir 'test/posGt'],'pLoad',opts.pLoad,...
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