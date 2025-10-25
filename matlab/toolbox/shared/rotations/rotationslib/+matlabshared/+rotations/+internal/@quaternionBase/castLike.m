function x = castLike(obj,a)
%This function is for internal use only. It may be removed in the future. 

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(isa(a,'matlabshared.rotations.internal.quaternionBase'),'shared_rotations:quaternion:QuatExpected');
x = cast(a,classUnderlying(obj));
end
