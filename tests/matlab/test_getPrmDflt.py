'''
Created on May 12, 2020

@author: johann
'''
import unittest
from matlab import getPrmDflt

class Test(unittest.TestCase):
    
    def setUp(self):
        unittest.TestCase.setUp(self)
        self.defaults = { 'x':'REQ', 'y':0, 'z':[], 'eps':1e-3 }
    
    def test_getPrmDflt_ReturnsDict(self):
        param_in = {'x':1,'y':2}
        prm = getPrmDflt(param_in, self.defaults)
        expected = self.defaults
        expected['x'] = 1
        expected['y'] = 2
        
        self.assertDictEqual(prm, expected)        
        
    def test_getPrmDflt_CheckExtraRaise(self):
        param_in = {'a':1,'y':2}
        with self.assertRaises(KeyError):
            prm = getPrmDflt( param_in, self.defaults, 1)
        
        
    def test_getPrmDflt_CheckExtraIgnore(self):
        param_in = {'x':1,'a':2}
        prm = getPrmDflt( param_in, self.defaults, 0)
        expected = self.defaults
        expected['x'] = 1
        self.assertDictEqual(prm, expected)
        
    def test_getPrmDflt_CheckExtraAdd(self):
        param_in = {'x':1,'a':2}
        prm = getPrmDflt( param_in, self.defaults, -1)
        expected = self.defaults
        expected['x'] = 1
        expected['a'] = 2
        self.assertDictEqual(prm, expected)
        
    def test_getPrmDflt_MissingRequired(self):
        param_in = {'a':1,'y':2}
        with self.assertRaises(RuntimeError):
            prm = getPrmDflt( param_in, self.defaults)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()