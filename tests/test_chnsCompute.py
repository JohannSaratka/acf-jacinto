'''
Created on May 11, 2020

@author: johann
'''
import unittest
from channels import chnsCompute

class Test(unittest.TestCase):


    def test_chnsCompute_default(self):
        chns = chnsCompute([], {})


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.test_chnsCompute_default']
    unittest.main()