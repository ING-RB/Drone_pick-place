function [index,interp] = doGetInterpolatedPointInDataUnits(obj, position)
%doGetInterpolatedPoint Find the index and interpolation from a target point
%
% This object has only discrete data tips. Consequently, we will
% always return the closest point with an interpolation factor of 0.

%  Copyright 2024 The MathWorks, Inc.

% Get the index from the nearest-point function and return with
% interpolation factor 0
index = doGetNearestPoint(obj, position);
interp = 0;
end