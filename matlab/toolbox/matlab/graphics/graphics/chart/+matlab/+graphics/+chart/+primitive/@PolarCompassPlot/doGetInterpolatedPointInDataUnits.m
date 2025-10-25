function [index,interp] = doGetInterpolatedPointInDataUnits(obj, position)
% 

%  Copyright 2024 The MathWorks, Inc.

index = doGetNearestPoint(obj, position);
interp = 0;
end