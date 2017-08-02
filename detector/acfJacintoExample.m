% Example for aggregate channel features object detector on various datasets.
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]
%
% Copyright 2017 Texas Instruments. [www.ti.com] All rights reserved.

if ~isdeployed()
    addpath(genpath(cd(cd('../')))); %cd(cd()) is a trick to get the full path from relative path
end

%% dataset
dataName='Inria';%'TIRoadDrive';
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
  objectName='Person';%'Trafficsign';%'Vehicle';
  exptName=['AcfJacinto' dataName objectName];
  extractType='annotated';
  extractFormat='jpg'; %png; %'';
  dataDir='D:\files\work\code\vision\ti\bitbucket\algoref\vision-dataset\annotatedVbb\data-TIRoadDrive2\videos';
  if strcmp(objectName, 'Person'),  
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
   elseif strcmp(objectName, 'Trafficsign'),
     vidList = { ...
                {'other/gtsdb_trafficsigns/V000.seq',...
                'other/gtsdb_trafficsigns/V001.seq',...
                'other/gtsdb_trafficsigns/V002.seq',...
                'ti/lindau/V106_2015sept_100_VIRB_VIRB0031_10m_10m.MP4', ...
                'ti/munich/V007_2015jul_VIRB0008_0m_7m.MP4'} ...
                {'ti/lindau/V105_2015sept_100_VIRB_VIRB0031_0m_10m.MP4'}
                };                       
     vbbList = { ...
                {'other/gtsdb_trafficsigns/V000.vbb',...
                'other/gtsdb_trafficsigns/V001.vbb',...
                'other/gtsdb_trafficsigns/V002.vbb',...
                'ti/lindau/V106_2015sept_100_VIRB_VIRB0031_10m_10m.vbb', ...
                'ti/munich/V007_2015jul_VIRB0008_0m_7m.vbb'} ...
                {'ti/lindau/V105_2015sept_100_VIRB_VIRB0031_0m_10m.vbb'}
                };                      
     pLoadLabel={'lbls', {'trafficsign' 'trafficsign_stop' 'trafficsign_no_entry' 'trafficsign_no_parking' 'trafficsign_no_stopping' 'trafficsign_giveway' 'trafficsign_priority_road' 'trafficsign_speed_limit_10' 'trafficsign_speed_limit_20' 'trafficsign_speed_limit_30' 'trafficsign_speed_limit_40' 'trafficsign_speed_limit_50' 'trafficsign_speed_limit_60' 'trafficsign_speed_limit_70' 'trafficsign_speed_limit_80' 'trafficsign_speed_limit_90' 'trafficsign_speed_limit_100' 'trafficsign_speed_limit_110' 'trafficsign_speed_limit_120' 'trafficsign_speed_limit_other' 'trafficsign_direction_go_right' 'trafficsign_direction_go_left' 'trafficsign_direction_go_straight' 'trafficsign_direction_go_right_or_straight' 'trafficsign_direction_go_left_or_straight' 'trafficsign_direction_keep_right' 'trafficsign_direction_keep_left' 'trafficsign_direction_round_about' 'trafficsign_direction_other' 'trafficsign_warning_redborder_triangle' 'trafficsign_regulatory_bluefilled_circle' 'trafficsign_prohibitory_redborder_circle' 'trafficsign_other'},...
          'ilbls',{'ignored' 'occluded' 'trafficsign_occluded' 'trafficsign_group' 'trafficsign_informtion_bluefilled_rectangle' 'trafficsign_informtion_yellowfilled_rectangle'}, ...
          }; 
   elseif strcmp(objectName, 'Vehicle'),
     vidList = { ...
                {'ti/munich/V007_2015jul_VIRB0008_0m_7m.MP4'} ...
                {'ti/munich/V008_2015jul_VIRB0008_7m_end.MP4'}
                };                       
     vbbList = { ...
                {'ti/munich/V007_2015jul_VIRB0008_0m_7m.vbb'} ...
                {'ti/munich/V008_2015jul_VIRB0008_7m_end_every30th.vbb'}
                };  
     pLoadLabel={'lbls', {'vehicle_medium_back' 'vehicle_medium_front' 'vehicle_medium_other' 'vehicle_medium_side' 'Car'},...
          'ilbls',{'ignored' 'occluded' 'vehicle_occluded'  'vehicle_ignored' 'vehicle_group' 'vehicle_other' 'vehicle_large_front' 'vehicle_large_back' 'vehicle_large_side' 'vehicle_large_other' 'DontCare' 'Misc' 'Truck' 'Van' 'Tram'}, ...
          };       
   end
   config=struct();
   config.nNeg=20000;
   config.nAccNeg=60000; 
   %opts.pPyramid.nApprox=-1; %TODO: just for speed. comment this out later.
   config.pLoad=['hRng',[56 inf], 'wRng',[24 inf], pLoadLabel];
end

%% extract training and testing images and ground truth
extractDb = true;  %0: disable, 1: extract the dataset into temporary folder
tempDir = [tempdir filesep 'data-acf' filesep dataName];
if extractDb,
    response = input('Extracting the dataset may take a long time. Do you wish to continue? Enter 1/0 (default: 0): ');
    if isempty(response) || response ~= 1
        extractDb = false;
    end
end
extractDir = acfJacintoExtract(extractDb, dataDir, vidList, vbbList, extractType, extractFormat, tempDir);

%% train and test
acfJacintoTrainTest(extractDir,exptName,config);

%% evaluation and comparison with other results
%expNum = 1; %19: Ht56 onwards, 1: (default) 50 onwards
%dbEval(dataDir, expNum);