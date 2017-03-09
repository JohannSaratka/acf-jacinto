function [ output_args ] = acfSaveDescriptor(outFile, detector)
% Save the descriptor to file in custom format

%PIOTR: YUVGHHHHHH -> TICVD: HHHHHHGYUV
%outChnMapping=[7,8,9,6,0,1,2,3,4,5]+1;
%outChnMapping=[4,5,6,7,8,9,3,0,1,2]+1; %wrong
outChnMapping=[0,1,2,3,4,5,6,7,8,9]+1;

%TICVD:Level-First -> PIOTR:Level-First
inNodeMapping=[0,1,2,3,4,5,6]+1;

hScale=1;   %256: for input sample, 8*8: for accum, 4*4: compensate for scale down inside gradHist
gScale=1;   %256: for input sample, 8*8: for accum
cScale=1;   %256: for input sample, 8*8: for accum
chnScale=[hScale,hScale,hScale,hScale,hScale,hScale,gScale,cScale,cScale,cScale]; %scale is not correct!
%chnScale=[cScale,cScale,cScale,gScale,hScale,hScale,hScale,hScale,hScale,hScale]; %scale is not correct!
qBits=13;
transpose=1;

opts=detector.opts;
clf=detector.clf;
fids=clf.fids;
thrs=clf.thrs;
hs=clf.hs;
shrink=opts.pPyramid.pChns.shrink;
mH=opts.modelDsPad(1)/shrink;
mW=opts.modelDsPad(2)/shrink;
szChn=mH*mW;
nNodes=size(fids,1);
nLastNodes=round(nNodes+1)/2;
qVal=bitshift(1,qBits);
nTrees=size(fids,2);
nChns=length(outChnMapping);
nLevels=max(clf.treeDepth, opts.pBoost.pTree.maxDepth);
nFtrs = mH*mW*nChns;

%Find the raster index corresponding to the vertical scan index
for i=1:nNodes,
    for j=1:nTrees,     
         f=double(clf.fids(i,j));
         chnIdx=floor(f/szChn);   
         chnOffset=double(mod(f,szChn));
         
         outChn=outChnMapping(chnIdx+1)-1;        
         cIdx=floor(chnOffset/mH);
         rIdx=double(mod(chnOffset,mH));
         if transpose,
           fids(i,j) = outChn*szChn+rIdx*mW+cIdx;
         else
           fids(i,j) = outChn*szChn+cIdx*mH+rIdx;             
         end
         thrs(i,j) = thrs(i,j)*chnScale(outChn+1);
    end
end
clf.fids=fids;


fp=fopen(outFile,'w');

fprintf(fp, '#AdaboostCompactDescriptor: %d %d %d %d\n', nTrees, nLevels, qBits, nNodes);

for i=1:(nLastNodes-1)
    iNode=inNodeMapping(i);
    for j=1:nTrees,
        fprintf(fp, '%8d ', fids(iNode,j));
    end
    fprintf(fp, '#FIDS(FeatureIds)\n');
    
    for j=1:nTrees,
        th=round(thrs(iNode,j));
        fprintf(fp, '%8d ', th);
    end
    fprintf(fp, '#TH(Thresholds)\n');    
end

for i=nLastNodes:nNodes
    iNode=inNodeMapping(i);    
    for j=1:nTrees,
        hsFix = round(hs(iNode,j) * qVal);
        fprintf(fp, '%8d ', hsFix);
    end
    fprintf(fp, '#WT(Weights)\n');    
end

fclose(fp);

end


function cfSaveDescriptorOldMethod(modelfile, model, nLevels, qPoint, lambdas, compactDescriptor)

if nargin < 3,
  nLevels = 2;
end
if nargin < 4
  qPoint = 13;
end
if nargin <5,
  lambdas=[];
end
if nargin < 6
  compactDescriptor = 1;
end

QBITS = qPoint;
QMAX = Inf; %(2^(QBITS+2))-1; %+2 to facilitate SIMD 4point add

sz = size(model.fids);
nWeak = sz(2);
nNodes = (2^(nLevels+1))-1;
fp = fopen(modelfile, 'w');
if(~isempty(lambdas))
    fprintf(fp, '#FeatureScalingLambda: ');
    fprintf(fp, '%f ', lambdas);  
    fprintf(fp, '\n');
end

fixmodel = model;
formatStr = '%10.5f ';
if QBITS ~= 0
    formatStr = '%8d ';
    fixmodel.thrs = float2fix(fixmodel.thrs, 8, QMAX);
    fixmodel.hs = float2fix(fixmodel.hs, QBITS, QMAX);
    fixmodel.weights = float2fix(fixmodel.weights, QBITS, QMAX);
end

if(compactDescriptor)
    fprintf(fp, '#AdaboostCompactDescriptor: %d %d %d %d\n', nWeak, nLevels, qPoint, nNodes);
else
    fprintf(fp, '#AdaboostCascadeDescriptor: %d %d %d %d\n', nWeak, nLevels, qPoint, nNodes);    
end

%Fix early terminations in the trees
for i = 1:sz(1)  
    mxChild = max(fixmodel.child(i,:));  
    for j = 1 :  sz(2)  
        if mxChild ~= fixmodel.child(i,j)
            fixmodel.child(i,j) = mxChild;
            hs = fixmodel.hs(i,j);
            if mxChild ~= 0
                fixmodel.child(mxChild,j) = 0;
                fixmodel.hs(mxChild,j) = hs;
                fixmodel.hs(mxChild+1,j) = hs;
            end
        end
    end
end

for i = 1:sz(1)
    if(compactDescriptor)    
        fprintf(fp, '###################### ');
        fprintf(fp, 'Depth = %d ', max(fixmodel.depth(i,:)));
        fprintf(fp, 'Node = %d ', i-1);    
        fprintf(fp, '######################\n');
    end
    
    if(compactDescriptor)
        mxDepth = max(fixmodel.depth(i,:));
        if mxDepth < nLevels
            fprintf(fp, formatStr,fixmodel.fids(i,:));
            fprintf(fp,' #FIDS(FeatureIds)\n');
            fprintf(fp, formatStr,fixmodel.thrs(i,:));
            fprintf(fp,' #TH(Thresholds)\n');
        else
            fprintf(fp, formatStr,fixmodel.hs(i,:));
            fprintf(fp,' #WT(Weights)\n');
        end    
    else
        sep=[];sep(1:sz(2)) = i-1;    
        fprintf(fp, formatStr, sep(:));
        fprintf(fp,' #Node\n'); 
        fprintf(fp, formatStr,fixmodel.depth(i,:));
        fprintf(fp,' #Depth\n'); 
        fprintf(fp, formatStr,fixmodel.fids(i,:));
        fprintf(fp,' #FIDS\n'); 
        fprintf(fp, formatStr,fixmodel.thrs(i,:));
        fprintf(fp,' #THRS\n'); 
        fprintf(fp, formatStr,fixmodel.child(i,:));
        fprintf(fp,' #Child\n');
        fprintf(fp, formatStr,fixmodel.hs(i,:));
        fprintf(fp,' #Weights\n');
        fprintf(fp, formatStr,fixmodel.weights(i,:));
        fprintf(fp,' #Prob\n');        
    end
end

fclose(fp);

end


function fix = float2fix(flt, qbits, qmax)
qfact = 2^qbits;
fix = min(round(flt * qfact), qmax);
end

function flt = fix2float(flt, qbits)
qfact = 2^qbits;
flt = fix / qfact;
end

