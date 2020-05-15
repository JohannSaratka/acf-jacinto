'''
Created on May 4, 2020

@author: johann
'''
import unittest
from channels import imPad
import numpy as np


class Test(unittest.TestCase):

    def test_imPad_WrongTypeRaisesValueError(self):
        I = np.ones((2, 2), dtype=np.int16)
        with self.assertRaises(ValueError):
            b = imPad(I, [2, 2], 2)
            
    def test_imPad_Constant(self):      
        I = np.ones((2, 3), dtype=np.uint8)
        pad = [1, 2] 
        type = 50
        J1 = imPad(I, pad, type)
        J2 = np.pad(I, ((1,), (2,)), constant_values=type)
        np.testing.assert_array_equal(J1, J2)
        
    def test_imPad_Replicate(self):
        I = np.array([[1, 2], [3, 4]], dtype=np.uint8)
        pad = [0, 1, 2, 3] 
        type = 'replicate'
        J1 = imPad(I, pad, type)
        J2 = np.pad(I, ((0, 1), (2, 3)), 'edge')
        np.testing.assert_array_equal(J1, J2)
        
    def test_imPad_Circular(self):
        I = np.array([[1, 2], [3, 4]], dtype=np.uint8)
        pad = [3] 
        type = 'circular'
        J1 = imPad(I, pad, type)
        J2 = np.pad(I, ((3,), (3,)), 'wrap')
        np.testing.assert_array_equal(J1, J2)
        
    def test_imPad_Symmetric(self):
        I = np.array([[1, 2], [3, 4]], dtype=np.uint8)
        pad = [1, 3] 
        type = 'symmetric'
        J1 = imPad(I, pad, type)
        J2 = np.pad(I, ((1,), (3,)), 'symmetric')
        np.testing.assert_array_equal(J1, J2)
        
    def test_imPad_Crop(self):
        I = np.arange(32, dtype=np.double).reshape((4, 8))
        pad = [-1, -3] 
        type = 'symmetric'
        J = imPad(I, pad, type)
        self.assertEqual(J.shape, (2, 2))


if __name__ == "__main__":
    # import sys;sys.argv = ['', 'Test.test_chnsCellSum']
    unittest.main()
