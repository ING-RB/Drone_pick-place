function obj = fromMatrix(M,sz)
%This method is for internal use only. It may be removed in the future.

%fromMatrix Static method to create an se2 object from a numeric 4x4xN matrix
%   Want to keep this way to initialize se2 objects out of the standard
%   constructor, since it is for internal use.

%   Copyright 2022-2024 The MathWorks, Inc.

    obj = se2;
    obj.M = M;

    indices = cast(1:prod(sz), "like", M);
    obj.MInd = reshape(indices,sz);

end
