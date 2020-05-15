import numpy as np

from matlab import getPrmDflt

def chnsCompute( I:np.array = None, pChns:dict = dict() ):
    """
     Compute channel features at a single scale given an input image.
    
     Compute the channel features as described in:
      P. Doll�r, Z. Tu, P. Perona and S. Belongie
      "Integral Channel Features", BMVC 2009.
     Channel features have proven very effective in sliding window object
     detection, both in terms of *accuracy* and *speed*. Numerous feature
     types including histogram of gradients (hog) can be converted into
     channel features, and overall, channels are general and powerful.
    
     Given an input image I, a corresponding channel is a registered map of I,
     where the output pixels are computed from corresponding patches of input
     pixels (thus preserving overall image layout). A trivial channel is
     simply the input grayscale image, likewise for a color image each color
     channel can serve as a channel. Other channels can be computed using
     linear or non-linear transformations of I, various choices implemented
     here are described below. The only constraint is that channels must be
     translationally invariant (i.e. translating the input image or the
     resulting channels gives the same result). This allows for fast object
     detection, as the channels can be computed once on the entire image
     rather than separately for each overlapping detection window.
    
     Currently, three channel types are available by default (to date, these
     have proven the most effective for sliding window object detection):
      (1) color channels (computed using rgbConvert.m)
      (2) gradient magnitude (computed using gradientMag.m)
      (3) quantized gradient channels (computed using gradientHist.m)
     For more information about each channel type, including the exact input
     parameters and their meanings, see the respective m-files which perform
     the actual computatons (chnsCompute is essentially a wrapper function).
     The converted color channels serve as input to gradientMag/gradientHist.
    
     Additionally, custom channels can be specified via an optional struct
     array "pCustom" which may have 0 or more custom channel definitions. Each
     custom channel is generated via a call to "chns=feval(hFunc,I,pFunc{:})".
     The color space of I is determined by pColor.colorSpace, use the setting
     colorSpace='orig' if the input image is not an 'rgb' image and should be
     left unchanged (e.g. if I has multiple channels). The input I will have
     type single and the output of hFunc should also have type single.
    
     "shrink" (which should be an integer) determines the amount to subsample
     the computed channels (in applications such as detection subsamping does
     not affect performance). The params for each channel type are described
     in detail in the respective function. In addition, each channel type has
     a param "enabled" that determines if the channel is computed. If
     chnsCompute() is called with no inputs, the output is the complete
     default params (pChns). Otherwise the outputs are the computed channels
     and additional meta-data (see below). The channels are computed at a
     single scale, for (fast) multi-scale channel computation see chnsPyramid.
    
     An emphasis has been placed on speed, with the code undergoing heavy
     optimization. Computing the full set of channels used in the BMVC09 paper
     referenced above on a 480x640 image runs over *100 fps* on a single core
     of a machine from 2011 (although runtime depends on input parameters).
    
     USAGE
      pChns = chnsCompute()
      chns = chnsCompute( I, pChns )
    
     INPUTS
      I           - [hxwx3] input image (uint8 or single/double in [0,1])
      pChns       - parameters (struct or name/value pairs)
       .shrink       - [4] integer downsampling amount for channels
       .pColor       - parameters for color space:
         .enabled      - [1] if true enable color channels
         .smooth       - [1] radius for image smoothing (using convTri)
         .colorSpace   - ['luv'] choices are: 'gray', 'rgb', 'hsv', 'orig'
       .pGradMag     - parameters for gradient magnitude:
         .enabled      - [1] if true enable gradient magnitude channel
         .colorChn     - [0] if>0 color channel to use for grad computation
         .normRad      - [5] normalization radius for gradient
         .normConst    - [.005] normalization constant for gradient
         .full         - [0] if true compute angles in [0,2*pi) else in [0,pi)
       .pGradHist    - parameters for gradient histograms:
         .enabled      - [1] if true enable gradient histogram channels
         .binSize      - [shrink] spatial bin size (defaults to shrink)
         .nOrients     - [6] number of orientation channels
         .softBin      - [0] if true use "soft" bilinear spatial binning
         .useHog       - [0] if true perform 4-way hog normalization/clipping
         .clipHog      - [.2] value at which to clip hog histogram bins
       .pCustom      - parameters for custom channels (optional struct array):
         .enabled      - [1] if true enable custom channel type
         .name         - ['REQ'] custom channel type name
         .hFunc        - ['REQ'] function handle for computing custom channels
         .pFunc        - [{}] additional params for chns=hFunc(I,pFunc{:})
         .padWith      - [0] how channel should be padded (e.g. 0,'replicate')
       .complete     - [] if true does not check/set default vals in pChns
    
     OUTPUTS
      chns       - output struct
       .pChns      - exact input parameters used
       .nTypes     - number of channel types
       .data       - [nTypes x 1] cell [h/shrink x w/shrink x nChns] channels
       .info       - [nTypes x 1] struct array
         .name       - channel type name
         .pChn       - exact input parameters for given channel type
         .nChns      - number of channels for given channel type
         .padWith    - how channel should be padded (0,'replicate')
    
     EXAMPLE - default channels
      I=imResample(imread('peppers.png'),[480 640]); pChns=chnsCompute();
      tic, for i=1:100, chns=chnsCompute(I,pChns); end; toc
      figure(1); montage2(cat(3,chns.data{:}));
    
     EXAMPLE - default + custom channels
      I=imResample(imread('peppers.png'),[480 640]); pChns=chnsCompute();
      hFunc=@(I) 5*sqrt(max(0,max(convBox(I.^2,2)-convBox(I,2).^2,[],3)));
      pChns.pCustom=struct('name','Std02','hFunc',hFunc); pChns.complete=0;
      tic, chns=chnsCompute(I,pChns); toc
      figure(1); im(chns.data{4});
    
     See also rgbConvert, gradientMag, gradientHist, chnsPyramid
    
     Piotr's Computer Vision Matlab Toolbox      Version 3.23
     Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
     Licensed under the Simplified BSD License [see external/bsd.txt]
    """
    if(('complete' not in pChns) or (pChns['complete'] != 1) or (I.size == 0)):
        pCstm={'enabled':{},
               'name':{},
               'hFunc':{},
               'pFunc':{},
               'padWith':{}}
        channel_dfs = {'shrink':4, 
                       'pColor':{}, 
                       'pGradMag':{}, 
                       'pGradHist':{}, 
                       'pCustom':[pCstm], 
                       'complete':1, 
                       'pFastMode':{}}
        pChns = getPrmDflt(pChns, channel_dfs, 1)
        
        color_dfs={'enabled':1,
                   'smooth':1,
                   'colorSpace':'luv',
                   'adapthisteq':0, 
                   'smoothInput':0 }
        pChns['pColor'] = getPrmDflt( pChns['pColor'], color_dfs, 1 )
        
        grad_mag_dfs = {'enabled':1,
                        'colorChn':0,
                        'normRad':5,
                        'normConst':.005,
                        'full':0}
        pChns['pGradMag'] = getPrmDflt( pChns['pGradMag'], grad_mag_dfs, 1 )
        
        grad_hist_dfs = {'enabled':1,
                         'binSize':[],
                         'nOrients':6,
                         'softBin':0,
                         'useHog':0,
                         'clipHog':.2}
        pChns['pGradHist'] = getPrmDflt( pChns['pGradHist'], grad_hist_dfs, 1 )
        
        fast_mode_dfs = {'enabled':0, 
                         'cellSize':8}
        pChns['pFastMode'] = getPrmDflt( pChns['pFastMode'], fast_mode_dfs, 1 )
        
        nc = len(pChns['pCustom']); 
        pc = [None] * nc
        cstm_chns_dfs = {'enabled':1,
                         'name':'REQ',
                         'hFunc':'REQ',
                         'pFunc':{},
                         'padWith':0}
        cstm_chnls = pChns['pCustom']
        for i in range(nc):            
            pc[i] = getPrmDflt(cstm_chnls[i] , cstm_chns_dfs, 1)
        if(nc > 0):
            pChns['pCustom'] = [pc[:]]
    
    if(I.size == 0):
        return pChns
    
    # create output struct
    info = {'name':{}, 'pChn':{}, 'nChns':{}, 'padWith':{}}
    chns = {'pChns':pChns, 'nTypes':0, 'data':{{}}, 'info':info}
    
    # crop I so divisible by shrink and get target dimensions
    shrink = pChns.shrink 
    h, w, _ = size(I)
    cr = mod([h, w], shrink)
    if(any(cr)):
        h = h - cr(1) 
        w = w - cr(2)
        I = I[1:h, 1:w, :]
    h = h / shrink
    w = w / shrink
    
    if not pChns.pFastMode.enabled:
        # compute color channels
        p = pChns.pColor
        nm = 'color channels'
        I = rgbConvert(I, p.colorSpace, p.adapthisteq, p.smoothInput)
        I = convTri(I, p.smooth)
        if(p.enabled):
            chns = addChn(chns, I, nm, p, 'replicate', h, w)
        
        # compute gradient magnitude channel
        p = pChns.pGradMag
        nm = 'gradient magnitude'
        full = 0; 
        if(isfield(p, 'full')):
            full = p.full
        if(pChns.pGradHist.enabled):
            [M, O] = gradientMag(I, p.colorChn, p.normRad, p.normConst, full)
        elif(p.enabled):
            M = gradientMag(I, p.colorChn, p.normRad, p.normConst, full);
        
        if(p.enabled):
            chns = addChn(chns, M, nm, p, 0, h, w)
        
        # compute gradient histgoram channels
        p = pChns.pGradHist
        nm = 'gradient histogram'
        if(p.enabled):
            binSize = p.binSize
            if(isempty(binSize)):
                binSize = shrink
            H = gradientHist(M, O, binSize, p.nOrients, p.softBin, p.useHog, p.clipHog, full);
            chns = addChn(chns, H, nm, pChns.pGradHist, 0, h, w)
        
    else:
        if ~isempty(I):
            justABreakPoint = 1
          
        cellSize = pChns.pFastMode.cellSize
        clipMag = 255
        accurate = false
        
        # leave out some pixels from graidient channels
        startOffset = [1, 1, 0]
        endOffset = [1, 1, 2]
        
        # compute color channels
        p = pChns.pColor;
        nm1 = 'color channels'
        I = rgbConvert(I, p.colorSpace, p.adapthisteq, p.smoothInput)
        I = convTri(I, p.smooth)
        if ~isempty(I):
            I0 = I[:, :, 1]
        else:
            I0 = I
        
        # compute gradient magnitude channel
        p = pChns.pGradMag; nm2 = 'gradient magnitude'
        [M, Gx, Gy] = gradientMagFast(I0, clipMag, accurate)
        
        # compute gradient histgoram channels
        p = pChns.pGradHist; nm3 = 'gradient histogram';
        if(pChns.pGradHist.enabled):
            binSize = p.binSize
            if(isempty(binSize)):
                binSize = shrink
            H = gradientHistFast(M, Gx, Gy, p.nOrients, accurate)
            if ~isempty(H):
                H = H[1 + startOffset(1):end - endOffset(1),
                    1 + startOffset(1):end - endOffset(1),
                    :]
            
            cellSumH = chnsCellSum(H, binSize, cellSize, h, w);
            chns = addChn(chns, cellSumH, nm3, pChns.pGradHist, 0, h, w);
        
        if(pChns.pGradMag.enabled):
            if ~isempty(M):  
                M = M[1 + startOffset(2):end - endOffset(2),
                    1 + startOffset(2):end - endOffset(2),
                    :]     
            
            cellSumM = chnsCellSum(M, binSize, cellSize, h, w);      
            chns = addChn(chns, cellSumM, nm2, pChns.pGradMag, 0, h, w)
          
        if(pChns.pColor.enabled):
            if ~isempty(I):
                I = I[1 + startOffset(3):end - endOffset(3),
                    1 + startOffset(3):end - endOffset(3),
                    :]        
            end
            cellSumI = chnsCellSum(I, binSize, cellSize, h, w)
            chns = addChn(chns, cellSumI, nm1, pChns.pColor, 'replicate', h, w)
    
    # compute custom channels
    p = pChns.pCustom;
    for i in find([p.enabled]):
        C = feval(p(i).hFunc, I, p(i).pFunc[:])
        chns = addChn(chns, C, p(i).name, p(i), p(i).padWith, h, w)
    

def addChn(chns, data, name, pChn, padWith, h, w):
    """ Helper function to add a channel to chns."""
    h1, w1, _ = size(data)
    if(h1 != h or w1 != w):
        data = imResampleMex(data, h, w, 1)
        # assert(all(mod([h1, w1]./[h, w],1)==0))
        assert(all(mod([h1, w1] / [h, w], 1) == 0))
    chns.data[end + 1] = data
    chns.nTypes = chns.nTypes + 1
    chns.info[end + 1] = {'name':name,
                      'pChn':pChn,
                      'nChns':size(data, 3),
                      'padWith':padWith}

