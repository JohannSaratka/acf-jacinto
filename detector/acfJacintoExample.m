if ~isdeployed()
    addpath(genpath(cd(cd('../')))); %cd(cd()) is a trick to get the full path from relative path
end

%% dataset
dataName='TIRoadDrive';%'Inria';
if strcmp(dataName, 'Inria'),
  exptName='AcfJacintoInria';
  extractType='all';  
  extractFormat='';  
  dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-INRIA';
  vidList={ ...
          {'videos/set00/V000.seq', 'videos/set00/V001.seq'}, ...
          {'videos/set01/V000.seq'} ...
       };
  vbbList={ ...
          {'annotations/set00/V000.vbb', 'annotations/set00/V001.vbb'}, ...
          {'annotations/set01/V000.vbb'} ...
        };  
   config = [];   
elseif strcmp(dataName, 'CaltechUsa')
  error('Define the dataset paths here');
elseif strcmp(dataName, 'TIRoadDrive')
  exptName='AcfJacintoTIRoadDrivePerson';
  extractType='annotated';
  extractFormat='jpg'; %png; %'';
  dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-TIRoadDrive2\videos';
  vidList={ ...
           %train
           {'other/inria_person/V000.seq', ...
           'other/inria_person/V001.seq', ...
           'ti/lindau/V106_2015sept_100_VIRB_VIRB0031_10m_10m.MP4' ...    %V106
           'ti/munich/V007_2015jul_VIRB0008_0m_7m.MP4' ...                %V007
           'ti/lindau/V110_2015sept_103_VIRB_VIRB0001.MP4' ...            %V110 
           'ti/lindau/V111_2015sept_104_VIRB_VIRB0001.MP4' }, ...         %V111
           %test
           {'ti/lindau/V105_2015sept_100_VIRB_VIRB0031_0m_10m.MP4' }      %V105
       };
  vbbList={ ...
           %train
           {'other/inria_person/V000.vbb', ...
           'other/inria_person/V001.vbb', ...
           'ti/lindau/V106_2015sept_100_VIRB_VIRB0031_10m_10m.vbb' ...    %V106
           'ti/munich/V007_2015jul_VIRB0008_0m_7m.vbb' ...                %V007
           'ti/lindau/V110_2015sept_103_VIRB_VIRB0001.vbb' ...            %V110 
           'ti/lindau/V111_2015sept_104_VIRB_VIRB0001.vbb' }, ...         %V111
           %test
           {'ti/lindau/V105_2015sept_100_VIRB_VIRB0031_0m_10m.vbb' }      %V105
        };  
   pLoadLabel={'lbls', {'person_pedestrian', 'person_rider','person'},...
          'ilbls',{'ignored', 'occluded', 'person_occluded', 'person_other', ...
                'person_pedestrian_group' 'person_rider_group', 'person_group'}, ...
          };
   config=struct();
   config.nNeg=20000;
   config.nAccNeg=60000; 
   %opts.pPyramid.nApprox=-1; %TODO: just for speed. comment this out later.
   config.pLoad=['hRng',[56 inf], 'wRng',[24 inf], pLoadLabel];
end

%% extract training and testing images and ground truth
extractDb = 0;  %0: disable, 1: extract the dataset into temporary folder
tempDir = [tempdir filesep 'data-acf' filesep dataName];
typeList={'train', 'test'};
extractDir={{},{}};
for s=1:2, 
  targetDir = [tempDir filesep typeList{s}];     
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

%% train and test
acfJacintoTrainTest(extractDir,exptName,config);

%% evaluation and comparison with other results
%expNum = 1; %19: Ht56 onwards, 1: (default) 50 onwards
%dbEval(dataDir, expNum);