function dbExtractList( datasetPath, vidList, vbbList, tDir, flatten, skip )
% Extract database to directory of images and ground truth text files.
%
% Call 'dbInfo(name)' first to specify the dataset. The format of the
% ground truth text files is the format defined and used in bbGt.m.
%
% USAGE
%  dbExtract( tDir, flatten )
%
% INPUTS
%  vidList  - list of sequences
%  vbbList  - [] list of corresponding vbb files
%  tDir     - [] target dir for image data (defaults to data dir in the current folder)
%  flatten  - [0] if true output all images to single directory
%  skip     - [1] specify frames to extract (defaults to skip in dbInfo)
%
% OUTPUTS
%
% EXAMPLE
%  dbInfo('InriaTest'); dbExtract;
%
% See also dbInfo, bbGt, vbb
%
% Caltech Pedestrian Dataset     Version 3.2.1
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<1 || isempty(datasetPath)), datasetPath=''; end
if(nargin<2 || isempty(vidList)), vidList={}; end
if(nargin<3 || isempty(vbbList)), vbbList={}; end
if(nargin<4 || isempty(tDir)), tDir='./data'; end
if(nargin<5 || isempty(flatten)), flatten=1; end
if(nargin<6 || isempty(skip)), skip=1; end

tDirImg=[tDir filesep 'images']; tDirAnno=[tDir filesep 'annotations'];
if(exist(tDirImg,'dir')), rmdir(tDirImg,'s'); end; mkdir(tDirImg);
if(exist(tDirAnno,'dir')), rmdir(tDirAnno,'s'); end; mkdir(tDirAnno);
for s=1:length(vidList)
    % load ground truth
    sname=vidList{s};
	aname=vbbList{s};
    A=vbb('vbbLoad',[datasetPath filesep aname]); n=A.nFrame;
	[fname,dname]=makeFileName(sname,flatten);
	if(flatten) seperator='_'; else seperator=filesep; end
    fs=cell(1,n); for i=1:n, fs{i}=[fname seperator 'I' int2str2(i-1,5)]; end
    % extract images
    td=[tDirImg filesep dname]; if ~exist(td), mkdir(td); end
    sr=seqIo([datasetPath filesep sname],'reader'); info=sr.getinfo();
    for i=skip-1:skip:n-1
      f=[td filesep fs{i+1} '.' info.ext]; if(exist(f,'file')), continue; end
      sr.seek(i); I=sr.getframeb(); f=fopen(f,'w'); fwrite(f,I); fclose(f);
    end; sr.close();
    % extract ground truth
    td=[tDirAnno filesep dname]; if ~exist(td), mkdir(td); end
    for i=1:n, fs{i}=[fs{i} '.txt']; end
    vbb('vbbToFiles',A,[td filesep],fs,skip,skip);
end
end


function [fname,dname]=makeFileName(sname,flatten)
    [pth,base,ext]=fileparts(sname);
    dname=[pth filesep base];
	if(flatten), fname=strrep(dname,'/','_'); fname=strrep(fname,'\','_'); end
    if flatten, dname=''; else fname=''; end
end
