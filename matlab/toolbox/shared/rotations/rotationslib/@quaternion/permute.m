function obj = permute(obj,order)
%PERMUTE Permute quaternion dimensions
%
% See also transpose

%   Copyright 2018 The MathWorks, Inc.    

obj.a = permute(obj.a,order);
obj.b = permute(obj.b,order);
obj.c = permute(obj.c,order);
obj.d = permute(obj.d,order);
end
