function o = mtimes(x,y)
% *  Quaternion multiplication for scalars
%   X*Y implements quaternion multiplication. It requires either
%   X or Y to be a scalar. Quaternion matrix multiplication is
%   not supported.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(isscalar(x) || isscalar(y),'shared_rotations:quaternion:QuatMtimesArg');
o = x .* y;
end
