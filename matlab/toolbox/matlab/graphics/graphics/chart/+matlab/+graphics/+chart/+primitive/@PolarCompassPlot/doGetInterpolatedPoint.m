function [index,interp] = doGetInterpolatedPoint(obj, position) 
% 

%  Copyright 2024 The MathWorks, Inc.

index = obj.doGetNearestPoint(position);
interp = 0;
end