function o = mldivide(x,y)
% \  Quaternion left division for scalars
%   X\Y implements quaternion left division. It requires either
%   X or Y to be a scalar. Quaternion matrix left division is
%   not supported.
  
%   Copyright 2023 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(isscalar(x) || isscalar(y),'shared_rotations:quaternion:QuatMldivideArg');
o = x .\ y;
end
