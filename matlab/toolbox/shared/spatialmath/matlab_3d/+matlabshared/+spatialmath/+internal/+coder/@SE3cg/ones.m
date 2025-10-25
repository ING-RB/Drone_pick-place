function o = ones(varargin)
%This method is for internal use only. It may be removed in the future.

%SE3.ONES Create se3 array of identity transformations

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"),"shared_spatialmath:matobj:SingleDouble", "se3", class(x));

    % Create identity se3 transforms for each 1 in the input
    oneMat = eye(4, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = matlabshared.spatialmath.internal.coder.SE3cg.fromMatrix(allMats,size(x));

end
