function o = ones(varargin)
%This method is for internal use only. It may be removed in the future.

%SO2.ONES Create so2 array of identity transformations

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"),"shared_spatialmath:matobj:SingleDouble", "so2", class(x));

    % Create identity so2 transforms for each 1 in the input
    oneMat = eye(so2.Dim, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = matlabshared.spatialmath.internal.coder.SO2cg.fromMatrix(allMats,size(x));

end
