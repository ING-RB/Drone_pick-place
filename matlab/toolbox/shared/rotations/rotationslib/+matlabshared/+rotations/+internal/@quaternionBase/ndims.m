function n = ndims(obj)
%NDIMS Number of dimensions in a quaternion array

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

n = ndims(obj.a);
end
