classdef VHACDConstants
% This class is for internal use only and may be removed in a future release

%VHACDConstants Constants referenced by VHACD

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        %VISUALGEOMSTRING String to indicate use of visual geometry for decomposition in rigidbodytree
        VISUALGEOMSTRING = "VisualGeometry"

        %COLLISIONGEOMSTRING String to indicate use of collision geometry for decomposition in rigidbodytree
        COLLISIONGEOMSTRING = "CollisionGeometry"
    end
end
