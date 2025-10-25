function [regionCurvature, regionSortedIdx] = localCurvature( ...
    points, startIdx, endIdx, curvatureRegionSize)
% This function is for internal use only. It may be removed in the future.
%
% localCurvature Computes the distance-weighted local curvature of a set of
% points.

% Copyright 2024 The MathWorks, Inc.

% Reference:
% J. Zhang and S. Singh. LOAM: Lidar Odometry and Mapping in Real-time.
% Robotics: Science and Systems Conference (RSS). Berkeley, CA, July 2014.

%#codegen

pointWeight = -2 * curvatureRegionSize;
diff = pointWeight .* points(startIdx:endIdx,:);

for j = 1:curvatureRegionSize
    diff = diff + points((startIdx + j):(endIdx + j),:) + ...
        points((startIdx - j):(endIdx - j),:);
end

% Compute the curvature of each point in the region.
diffSize = coder.internal.indexInt(size(diff, 1));
regionCurvature = coder.nullcopy(zeros(diffSize, 1, 'like', diff));
for i = 1:diffSize
    regionCurvature(i) = diff(i,1)*diff(i,1) + diff(i,2)*diff(i,2) + diff(i,3)*diff(i,3);
end

if nargout > 1
    % Sort curvatures from lowest to highest.
    [~, sortedIdx] = sort(regionCurvature);
    regionSortedIdx = sortedIdx + startIdx - 1;
end
end