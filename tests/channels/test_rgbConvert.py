'''
Created on May 16, 2020

@author: johann
'''
import unittest
import numpy as np
import cv2

from channels.rgbConvert import rgbConvert
from channels import ColorSpace

class Test(unittest.TestCase):
    def setUp(self):
        unittest.TestCase.setUp(self)
        self.img_in = np.zeros([10,10,3], dtype=np.single)
        self.img_in[:,:,0] = np.ones([10,10])*64/255
        self.img_in[:,:,1] = np.ones([10,10])*128/255
        self.img_in[:,:,2] = np.ones([10,10])*192/255
        # cv2.imwrite('color_img.jpg', self.img_in)

    @unittest.skip
    def test_rgbConvertGrayToGray(self):
        out = rgbConvert(self.img_in, ColorSpace.gray)
    
    @unittest.skip
    def test_rgbConvertToGray(self):
        out = rgbConvert(self.img_in, ColorSpace.gray)
    
    def test_rgbConvertToOrig(self):        
        out = rgbConvert(self.img_in, ColorSpace.orig)
        np.testing.assert_array_equal(out, self.img_in)
    
    def test_rgbConvertToRGB(self):
        
        out = rgbConvert(self.img_in, ColorSpace.rgb)
        np.testing.assert_array_equal(out, self.img_in)
        
    def test_rgbConvertToRGB_SingleToDouble(self):
        
        out = rgbConvert(self.img_in, ColorSpace.rgb, useSingle=False)
        np.testing.assert_array_equal(out, self.img_in)
        
    @unittest.skip
    def test_rgbConvertToLUV(self):
        out = rgbConvert(self.img_in, ColorSpace.luv)

    
    @unittest.skip
    def test_rgbConvertToHSV(self):
        out = rgbConvert(self.img_in, ColorSpace.hsv)


    @unittest.skip
    def test_rgbConvertToYUV(self):
        out = rgbConvert(self.img_in, ColorSpace.yuv)


    @unittest.skip
    def test_rgbConvertToYUV8(self):
        out = rgbConvert(self.img_in, ColorSpace.yuv8)




if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
