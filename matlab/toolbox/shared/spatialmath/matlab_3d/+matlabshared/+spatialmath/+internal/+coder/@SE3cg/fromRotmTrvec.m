function obj = fromRotmTrvec(R,t,sz)
%This method is for internal use only. It may be removed in the future.

%fromRotmTrvec Static method to create an se3 object from a numeric rotation and a translation
%   R is expected to be a 3x3xN single or double array
%   T is a 3xN matrix or 3x1xN array
%   Want to keep this way to initialize se3 objects out of the standard
%   constructor, since it is for internal use. It is also more performant
%   than the standard constructor.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    d = matlabshared.spatialmath.internal.coder.SE3cg.Dim;
    M = matlabshared.spatialmath.internal.rt2tform(R,t,d);

    indices = cast(1:prod(sz), "like", R);
    MInd = reshape(indices,sz);

    obj = matlabshared.spatialmath.internal.coder.SE3cg(M,MInd,0,0,0,0,0,0);

end
