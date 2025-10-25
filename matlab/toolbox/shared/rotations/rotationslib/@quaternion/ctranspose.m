function obj = ctranspose(obj)
% ' Quaternion conjugate transpose of a quaternion array
%
% See also transpose, permute

%   Copyright 2018 The MathWorks, Inc.    

obj.a = obj.a.';
obj.b = -obj.b.';
obj.c = -obj.c.';
obj.d = -obj.d.';
end
