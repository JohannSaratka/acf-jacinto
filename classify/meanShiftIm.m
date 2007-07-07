% Applies the meanShift algorithm to a joint spatial/range image.
%
% See "Mean Shift Analysis and Applications" by Comaniciu & Meer for info.
%
% Assumes X is an MxNxP array, where an X(i,j,:) represents the range data
% at locations (i,j).  This function runs meanShift on each of the MxN data
% points.  It takes advantage of the lattice structure of an image for
% efficiency (it only needs to calculate full distance between two points
% if they are near each other spatially).
%
% In the original formulation of the algorithm, after normalization of the
% data, the search window around each point x has radius 1 (ie
% corresponding to 1 std of the data). That is the search window only
% encloses 2*s+1 pixels, and of those, all which fall within 1 unit from x
% are used to calcluate the new mean.  If softFlag==0 the original
% formulation is used.  If softFlag==1, instead of using a fixed radius,
% each point p is used in the calulation of the mean with points close to x
% given significantly more weight.  Specifically, each point p is given
% weight exp(-dist(x,p)).  So instead of having a fixed cutoff at r, the
% cutoff is 'soft' (same idea as in softmax), and occurs at approximately
% r.  The implementation remains efficient by actually using a hard cutoff
% at points further then 2r spatially from x.
%
% The resulting matrix M is of size MxNx(P+2).  M(i,j,1) represents the
% convergent row location of X(i,j,:) - (which had initial row location i)
% and M(i,j,2) represents the final column location.  M(i,j,p+2) represents
% the convergent value for X(i,j,p).  The optionaly outputs Vr and Vc are
% 2D arrays where Vr(i,j)=M(i,j,1)-i and Vc(i,j)=M(i,j,2)-j.  That is they
% represent the spatial offset between the original location of a point and
% its convergent location.  Display using quiver(Vc,Vr,0).
%
% USAGE
%  [M,Vr,Vc] = meanShiftIm( X,sigSpt,sigRng,[softFlag],[maxIter],[minDel] )
%
% INPUTS
%  X        - MxNxP data array, P may be 1
%  sigSpt   - integer specifying spatial standard deviation
%  sigRng   - value specifying the standard deviation of the range data
%  softFlag - [0]- see above
%  maxIter  - [100] maximum number of iterations per data point
%  minDel   - [.001] minimum amount of spatial change defining convergence
%
% OUTPUTS
%  M        - array of convergent locations [see above]
%  Vr       - spatial motion in row direction
%  Vc       - spatial motion in col direction
%
% EXAMPLE
%  I=double(imread('cameraman.tif'))/255;
%  [M,Vr,Vc] = meanShiftIm( I,5,.2 );
%  figure(1); im(I); figure(2); im( M(:,:,3) );
%  % color image:
%  I=double(imread('hestain.png'))/255;
%  [M,Vr,Vc] = meanShiftIm( I,5,.2 );
%  figure(1); im(I); figure(2); im( M(:,:,3:end) );
%
% See also MEANSHIFT, MEANSHIFTIM_EXPLORE

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [M,Vr,Vc] = meanShiftIm( X,sigSpt,sigRng,softFlag,maxIter,minDel )

[sigSpt,er] = checknumericargs( sigSpt, 1, 0, 1 ); error(er);
if( nargin<4 || isempty(softFlag)); softFlag = 0; end
if( nargin<5 || isempty(maxIter) ); maxIter = 100; end
if( nargin<6 || isempty(minDel)); minDel = .001; end

[mrows, ncols, p] = size(X); p = p+2;
[grid_rs grid_cs] = ndgrid( 1:mrows, 1:ncols );
data = cat( 3, cat( 3, grid_rs/sigSpt, grid_cs/sigSpt), X/sigRng );

%%% MAIN LOOP
M = data;
ticstatusid = ticstatus('meanShiftIm');  %t0 = clock;  tlast = t0;
if( softFlag ); radius = sigSpt*2; else radius = sigSpt; end
for i=1:mrows; for j=1:ncols; %#ok<ALIGN>
    Mij = data(i,j,:); Mij = Mij(:)';
    itercount = 0; diff = 1;
    while( itercount < maxIter && diff>minDel )

      % get data which is possibly relevant (within spatial range)
      r = round( Mij(1)*sigSpt );  c = round( Mij(2)*sigSpt );
      boundsr = max(1,r-radius):min(mrows,r+radius);
      boundsc = max(1,c-radius):min(ncols,c+radius);
      data_window = data( boundsr, boundsc, : );
      data_windowf = reshape( data_window, [], p );

      % get next mean
      Mij_old = Mij;
      n = size( data_windowf, 1);
      D = sum( (data_windowf - ones(n,1)*Mij).^2, 2 );
      if( softFlag )
        S = exp( -D ); sumS = sum(S); Srep = S(:,ones(1,p));
        Mij = sum( data_windowf .* Srep, 1 ) / sumS;
      else
        data_windowf = data_windowf( D < 1, : );
        Mij = sum( data_windowf, 1 ) / size( data_windowf,1 );
      end

      % check if Mij changed [only on basis of x,y location]
      diff = sum( (Mij_old(1:2)-Mij(1:2)).^2 );
      itercount = itercount+1;

    end
    M(i,j,:) = Mij(:);
    fracdone = ((i-1)*ncols+j) / (mrows*ncols);
    tocstatus( ticstatusid, fracdone );
  end
end
M = cat(3, M(:,:,1:2)*sigSpt, M(:,:,3:end)*sigRng );

%%% Output spatial difference
if( nargout>1 )
  Vr = M(:,:,1)-grid_rs;  Vc = M(:,:,2)-grid_cs;
end