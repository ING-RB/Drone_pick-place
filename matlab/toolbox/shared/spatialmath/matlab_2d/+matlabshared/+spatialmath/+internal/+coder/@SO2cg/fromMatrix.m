function obj = fromMatrix(M,sz)
%This method is for internal use only. It may be removed in the future.

%fromMatrix Static method to create an so2 object from a numeric array
%   Want to keep this way to initialize so2 objects out of the standard
%   constructor, since it is for internal use.
%   To specify the object array size of these matrices, pass the SZ input.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    indices = cast(1:prod(sz), "like", M);
    MInd = reshape(indices,sz);

    obj = matlabshared.spatialmath.internal.coder.SO2cg(M,MInd,0,0,0,0,0,0);
end
