function tf = isscalar(obj)
%ISSCALAR True if input is a scalar
%   ISSCALAR(S) returns logical 1 (true) if SIZE(S) returns [1 1] and 
%   logical 0 (false) otherwise.
%
%   See also ISSCALAR, ISVECTOR, ISROW, ISCOLUMN, 
%            ISEMPTY, SIZE.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 
    
    tf = isscalar(obj.a);
end
