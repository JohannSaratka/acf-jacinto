function acfSaveDescriptor(outFile, detector, compact)
    if nargin < 3,
        compact = true;
    end
    
    if compact,
        acfSaveCompactDescriptor(outFile, detector);
    else
        acfSaveCascadeDescriptor(outFile, detector);
    end
end


function acfSaveCompactDescriptor(outFile, detector)
% Save the descriptor to file in custom format

featureTranspose=1;
featureScaling=1;

qBits=13;
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
nLevels=max(clf.treeDepth, opts.pBoost.pTree.maxDepth);

%Find the raster index corresponding to the vertical scan index
for i=1:nNodes,
    for j=1:nTrees,     
         f=double(clf.fids(i,j));
         chnIdx=floor(f/szChn);   
         chnOffset=double(mod(f,szChn));      
         cIdx=floor(chnOffset/mH);
         rIdx=double(mod(chnOffset,mH));
         if featureTranspose,
           fids(i,j) = chnIdx*szChn+rIdx*mW+cIdx;
         else
           fids(i,j) = chnIdx*szChn+cIdx*mH+rIdx;             
         end
         thrs(i,j) = thrs(i,j)*featureScaling;
    end
end
clf.fids=fids;


fp=fopen(outFile,'w');

fprintf(fp, '#AdaboostCompactDescriptor: %d %d %d %d\n', nTrees, nLevels, qBits, nNodes);

for i=1:(nLastNodes-1)
    iNode=i;
    for j=1:nTrees,
        fprintf(fp, '%8d ', fids(iNode,j));
    end
    fprintf(fp, '#FIDS(FeatureIds)\n');
    
    for j=1:nTrees,
        th=float2fix(thrs(iNode,j), 1);
        fprintf(fp, '%8d ', th);
    end
    fprintf(fp, '#TH(Thresholds)\n');    
end

for i=nLastNodes:nNodes
    iNode=i;    
    for j=1:nTrees,
        hsFix = float2fix(hs(iNode,j), qVal);
        fprintf(fp, '%8d ', hsFix);
    end
    fprintf(fp, '#WT(Weights)\n');    
end

fclose(fp);

end


function acfSaveCascadeDescriptor(outFile, detector)
% Save the descriptor to file in custom format

featureTranspose=1;
featureScaling=1;

qBits=13;
opts=detector.opts;
clf=detector.clf;
fids=clf.fids;
thrs=clf.thrs;
hs=clf.hs;
depth=clf.depth;
weights=clf.weights; weights(:,:) = 0;
child=clf.child;
shrink=opts.pPyramid.pChns.shrink;
mH=opts.modelDsPad(1)/shrink;
mW=opts.modelDsPad(2)/shrink;
szChn=mH*mW;
nNodes=size(fids,1);
nLastNodes=round(nNodes+1)/2;
qVal=bitshift(1,qBits);
nTrees=size(fids,2);
nLevels=max(clf.treeDepth, opts.pBoost.pTree.maxDepth);

formatStr = '%10.5f ';
if qBits ~= 0
    formatStr = '%8d ';
end


%Find the raster index corresponding to the vertical scan index
for i=1:nNodes,
    for j=1:nTrees,     
         f=double(clf.fids(i,j));
         chnIdx=floor(f/szChn);   
         chnOffset=double(mod(f,szChn));      
         cIdx=floor(chnOffset/mH);
         rIdx=double(mod(chnOffset,mH));
         if featureTranspose,
           fids(i,j) = chnIdx*szChn+rIdx*mW+cIdx;
         else
           fids(i,j) = chnIdx*szChn+cIdx*mH+rIdx;             
         end
         thrs(i,j) = thrs(i,j)*featureScaling;
    end
end
clf.fids=fids;


fp=fopen(outFile,'w');
fprintf(fp, '#FeatureScalingLambda: None\n');
fprintf(fp, '#AdaboostCascadeDescriptor: %d %d %d %d\n', nTrees, nLevels, qBits, nNodes);

for i = 1:nNodes
    %fprintf(fp, '###################### Node %d ######################\n', i);
    sep=[];sep(1:nTrees) = i-1;    
    fprintf(fp, formatStr, sep(:));
    fprintf(fp,' #Node\n'); 
    fprintf(fp, formatStr,depth(i,:));
    fprintf(fp,' #Depth\n'); 
    fprintf(fp, formatStr,fids(i,:));
    fprintf(fp,' #FIDS\n'); 
    fprintf(fp, formatStr,float2fix(thrs(i,:),1));
    fprintf(fp,' #THRS\n'); 
    fprintf(fp, formatStr,child(i,:));
    fprintf(fp,' #Child\n');
    fprintf(fp, formatStr,float2fix(hs(i,:),qVal));
    fprintf(fp,' #Weights\n');
    fprintf(fp, formatStr,float2fix(weights(i,:),1));
    fprintf(fp,' #Ignored weights\n');        
end

fclose(fp);

end


function fix=float2fix(flt, qval)
    %fix = flt * qval;
    fix=round(flt * qval);
    return;    
end




