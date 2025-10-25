function submap = createSubmap(scans, scanIndices, poses, anchorIndex, resolution, maxRange, maxLevel)
%This function is for internal use only. It may be removed in the future.

%CREATESUBMAP Create a submap from a set of scans
%   This function is MEX'ed for MATLAB execution.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen
    
if nargin > 0
    submap = nav.algs.internal.Submap(scans, scanIndices, poses, anchorIndex, resolution, maxRange, maxLevel);
else
    submap = nav.algs.internal.Submap();
end

end
