'''
Created on May 4, 2020

@author: johann
'''
import unittest
from channels import imPad
import numpy as np

class Test(unittest.TestCase):


    def test_imPad_WrongTypeRaisesValueError(self):
        I = np.ones((2,2), dtype=np.int16)
        with self.assertRaises(ValueError):
            b = imPad.imPad(I, [2, 2], 2)
            
    def test_imPadConstant_(self):      
        I = np.ones((2, 3), dtype=np.uint8)
        pad = [1, 2] 
        type = 50
        J1 = imPad.imPad(I, pad, type)
        J2 = np.pad(I, ((1,),(2,)), constant_values=type)
        np.testing.assert_array_equal(J1, J2)
        
    def test_imPadReplicate_(self):      
        #I = np.ones((2, 2), dtype=np.uint8)
        I=np.array([[1,2],[3,4]], dtype=np.uint8)
        pad = [1, 3] 
        type = 'replicate'
        J1 = imPad.imPad(I, pad, type)
        J2 = np.pad(I, ((1,),(3,)),'edge')
        np.testing.assert_array_equal(J1, J2)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.test_chnsCellSum']
    unittest.main()
