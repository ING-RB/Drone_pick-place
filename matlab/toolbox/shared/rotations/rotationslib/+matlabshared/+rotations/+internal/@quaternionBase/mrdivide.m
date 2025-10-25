function o = mrdivide(x,y)
% /  Quaternion right division for scalars
%   X/Y implements quaternion right division. It requires either
%   X or Y to be a scalar. Quaternion matrix right division is
%   not supported.
  
%   Copyright 2023 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(isscalar(x) || isscalar(y),'shared_rotations:quaternion:QuatMrdivideArg');
o = x ./ y;
end
