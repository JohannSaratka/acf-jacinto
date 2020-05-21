from color_space import ColorSpace

def processInput(I, colorSpace, adapthisteqFlag:bool, smoothInput:bool):
    """
     Pre-process input
     Extension to Piotr's Computer Vision Matlab Toolbox      Version 3.30
     Copyright (C) 2017 Texas Instruments Incorporated - http://www.ti.com/
    """
    if (I.size != 0) and (colorSpace is not ColorSpace.orig):
        # apply CLAHE algorithm (contrast-limited adaptive histogram equalization) 
        if adapthisteqFlag:
            if (colorSpace is ColorSpace.yuv8):
                I[:, :, 1] = adapthisteq(I[:, :, 1] / 255.0, 'ClipLimit', 2.0 / 255.0) * 255.0
            elif (colorSpace is ColorSpace.yuv):
                I[:, :, 1] = adapthisteq(I[:, :, 1], 'ClipLimit', 2.0 / 255.0)    
            else:
                for c in range(0, size(I, 3)):
                    I[:, :, c] = adapthisteq(I[:, :, c], 'ClipLimit', 2.0 / 255.0)  
            
        if smoothInput:
            I = convTri(I, smoothInput)
      
    return I

