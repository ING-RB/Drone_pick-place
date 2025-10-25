function tf = ismethod(obj,name)
%ISMETHOD  True if method of object.
%   ISMETHOD(OBJ,NAME) returns logical 1 (true) if the character vector or 
%   string scalar NAME is a method of input OBJ, and logical 0 (false) otherwise.
%
%   Example:
%     Hd = dfilt.df2;
%     f = ismethod(Hd, 'order')
%
%   See also METHODS, ISPROP, ISSTRUCT.  
  
%   Copyright 1999-2019 The MathWorks, Inc.

    narginchk(2,2)    
    tf = any(strcmp(name,methods(obj)));
end