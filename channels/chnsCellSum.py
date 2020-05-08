from channels._channels import chnsCellSumMex
import numpy as np

def chnsCellSum(data: np.array, stepSize: int, cellSize: int, h: int, w: int):
    """ Compute cell sum
        Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
    
        Copyright 2017 Texas Instruments. [www.ti.com] All rights reserved.
    """

    if h == 0 or w == 0:
        sz = data.shape
        if len(sz) > 2:
            ch = sz[2]
        else:
            ch = 1
        return np.zeros((h, w, ch), dtype=data.dtype)
    
    return chnsCellSumMex(data, stepSize, cellSize, h, w)

