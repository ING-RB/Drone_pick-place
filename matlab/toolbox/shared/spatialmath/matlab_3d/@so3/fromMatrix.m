function obj = fromMatrix(M,sz)
%This method is for internal use only. It may be removed in the future.

%fromMatrix Static method to create an so3 object from a numeric 3x3xN matrix
%   Want to keep this way to initialize so3 objects out of the standard
%   constructor, since it is for internal use.

%   Copyright 2022-2024 The MathWorks, Inc.

    obj = so3;
    obj.M = M;

    indices = cast(1:prod(sz), "like", M);
    obj.MInd = reshape(indices,sz);

end
