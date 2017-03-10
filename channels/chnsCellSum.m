function cellSum = chnsCellSum(data, stepSize, cellSize, h, w)
  if h==0 ||  w==0,
      sz=size(data);
      if length(sz)>2, ch=sz(3); else ch=1;end
      cellSum=zeros(h,w,ch);
      return;
  end
  cellSum = chnsCellSumMex(data, stepSize, cellSize, h, w);
end

%function dataCellSum = chnsCellSum(data,stepSize,cellSize,h,w)
%szData=size(data);
%szCells=szData; szCells(1)=h;  szCells(2)=w;      
%dataCellSum = zeros(szCells);
%numC=1;if length(szData)>2,numC=szData(3);end
%for c=1:numC,for i = 1:szCells(1),
%  iStart=((i-1)*stepSize)+1; iEnd=min(iStart+cellSize,szData(1));
%  for j=1:szCells(2),
%    jStart=((j-1)*stepSize)+1; jEnd=min(jStart+cellSize,szData(2));
%    blk=data(iStart:iEnd,jStart:jEnd,c);
%    dataCellSum(i,j,c) = sum(blk(:)); 
%  end
%end;end 
%end