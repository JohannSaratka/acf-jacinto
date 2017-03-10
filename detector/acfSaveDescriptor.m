function [ output_args ] = acfSaveDescriptor(outFile, detector)
% Save the descriptor to file in custom format

featureTranspose=1;
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
         thrs(i,j) = thrs(i,j);
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
        th=round(thrs(iNode,j));
        fprintf(fp, '%8d ', th);
    end
    fprintf(fp, '#TH(Thresholds)\n');    
end

for i=nLastNodes:nNodes
    iNode=i;    
    for j=1:nTrees,
        hsFix = round(hs(iNode,j) * qVal);
        fprintf(fp, '%8d ', hsFix);
    end
    fprintf(fp, '#WT(Weights)\n');    
end

fclose(fp);

end

