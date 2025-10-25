function [index,interp] = doGetInterpolatedPoint(obj, position) 
%

%  Copyright 2024 The MathWorks, Inc.

% This object represents only discrete quantities. Consequently,
% we will always return the closest point with an interpolation factor
% of 0.
index = obj.doGetNearestPoint(position);
interp = 0;
