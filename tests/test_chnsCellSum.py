'''
Created on May 4, 2020

@author: johann
'''
import unittest
from channels import chnsCellSum
import numpy as np

class Test(unittest.TestCase):


    def test_chnsCellSum_WrongTypeRaisesValueError(self):
        a = np.ones((8,8,5), dtype=np.int16)
        with self.assertRaises(ValueError):
            b = chnsCellSum.chnsCellSum(a, 2, 2, 8, 8)
            
    def test_chnsCellSum(self):      
        a = np.ones((4,4,2), dtype=np.double)
        a[:,:,1] = 2
        b = chnsCellSum.chnsCellSum(a, 1, 2, 4, 4)
        self.assertEqual(b.shape, (4,4,2))
        self.assertEqual(b.dtype, np.double)
        expected = np.array([[4.,4.,4.,2.],[4.,4.,4.,2.],[4.,4.,4.,2.],[2.,2.,2.,1.]])
        np.testing.assert_array_equal(b[:,:,0], expected)
        np.testing.assert_array_equal(b[:,:,1], np.array([[4.,4.,4.,2.],[4.,4.,4.,2.],[4.,4.,4.,2.],[2.,2.,2.,1.]])*2)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.test_chnsCellSum']
    unittest.main()