function submap = createSubmap(scans, scanIndices, poses, anchorIndex, resolution, maxRange, maxLevel)
%This function is for internal use only. It may be removed in the future.

%CREATESUBMAP Create a submap from a set of scans

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

    if coder.target('MATLAB')&&(nargin>0)
        % When running in MATLAB, use MEX file for improved performance
        submap = nav.algs.internal.mex.createSubmap(scans, scanIndices, poses, anchorIndex, resolution, maxRange, maxLevel);
    else
        if nargin > 0
            % When generating code, use MATLAB implementation
            submap = nav.algs.internal.impl.createSubmap(scans, scanIndices, poses, anchorIndex, resolution, maxRange, maxLevel);
        else
            % Create an empty submap useful for pre-allocation
            submap = nav.algs.internal.impl.createSubmap();
        end
    end

end
