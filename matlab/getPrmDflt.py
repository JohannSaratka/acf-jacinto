
def getPrmDflt( prm:dict, dfs:dict, checkExtra:bool = False ):
    """
     Helper to set default values (if not already set) of parameter struct.
    
     Takes input parameters and a list of 'name'/default pairs, and for each
     'name' for which prm has no value (prm.(name) is not a field or 'name'
     does not appear in prm list), getPrmDflt assigns the given default
     value. If default value for variable 'name' is 'REQ', and value for
     'name' is not given, an error is thrown. See below for usage details.
    
     USAGE (nargout==1)
      prm = getPrmDflt( prm, dfs, [checkExtra] )
    
     USAGE (nargout>1)
      [ param1 ... paramN ] = getPrmDflt( prm, dfs, [checkExtra] )
    
     INPUTS
      prm          - param struct or cell of form {'name1' v1 'name2' v2 ...}
      dfs          - cell of form {'name1' def1 'name2' def2 ...}
      checkExtra   - [0] if 1 throw error if prm contains params not in dfs
                     if -1 if prm contains params not in dfs adds them
    
     OUTPUTS (nargout==1)
      prm    - parameter struct with fields 'name1' through 'nameN' assigned
    
     OUTPUTS (nargout>1)
      param1 - value assigned to parameter with 'name1'
       ...
      paramN - value assigned to parameter with 'nameN'
    
     EXAMPLE
      dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
      prm = getPrmDflt( struct('x',1,'y',1), dfs )
      [ x y z eps ] = getPrmDflt( {'x',2,'y',1}, dfs )
    
     See also INPUTPARSER
    
     Piotr's Computer Vision Matlab Toolbox      Version 2.60
     Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
     Licensed under the Simplified BSD License [see external/bsd.txt]
    """
    # get and update default values
    out = dfs.copy()
    for key,value in prm.items():
        if key not in out:
            if (checkExtra > 0):
                # raise error on unkown parameter
                raise KeyError("parameter '{}' is not valid".format(key))
            elif (checkExtra == 0):
                # ignore unkown parameter
                continue
                
        out[key] = value
            
    # check for missing values
    if('REQ' in out.values()):
        req_key = list(out.keys())[list(out.values()).index('REQ')] 
        raise RuntimeError("Required field {} not specified.".format(req_key))
    return dfs
