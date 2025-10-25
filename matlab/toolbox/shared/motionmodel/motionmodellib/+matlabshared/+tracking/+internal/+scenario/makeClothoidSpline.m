function [cspline,course] = makeClothoidSpline(waypoints, varargin) %#codegen
%MAKECLOTHOIDSPLINE function creates clothoid model
% arguments
%     waypoints(:,2) double;
%     course(:,1) = nan(size(waypoints,1),1);

%   Copyright 2022 The MathWorks, Inc.
if ~isempty(varargin)
    course = varargin{1};
else
    course = nan(size(waypoints,1),1);
end
n = size(waypoints,1);
course = matlabshared.tracking.internal.scenario.clothoidG2fitMissingCourse(waypoints, course, 4);
% Obtain the (horizontal) initial positions.
hip = complex(waypoints(:,1), waypoints(:,2));
% Obtain the initial curvatures, final curvatures, and (horizontal)
% lengths of each segment.
[k0, k1, hl] = matlabshared.tracking.internal.scenario.clothoidG1fit2(...
    hip(1:n-1), course(1:n-1), hip(2:n), course(2:n));

% Report cumulative horizontal distance traveled from initial point.
hcd = [0; cumsum(hl)];

cspline.k0 = k0;
cspline.k1 = k1;
cspline.hl = hl;
cspline.hip = hip;
cspline.hcd = hcd;
cspline.course = course;
end
