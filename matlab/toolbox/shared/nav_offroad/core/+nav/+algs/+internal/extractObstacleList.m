function obstacleList = extractObstacleList(map)
% This function is for internal use only. It may be removed in the future.

% extractObstacleList Extract a XY positions of obstacles from an
% occupancy map, which is utilized in functions like optimizePath or
% controllerTEB for processing obstacle information.
%
%   INPUTS:
%       MAP           : binaryOccupancyMap or occupancyMap input
%   OUTPUTS:
%       obstacleList  : [N x 2] array containing obstacle coordinates
%

%{
% Example:
load("exampleMaps.mat", "complexMap");
map = binaryOccupancyMap(complexMap, 10);
obstacleList = nav.algs.internal.extractObstacleList(map);
%}

% Copyright 2024 The MathWorks, Inc.

%#codegen

% Default value of output parameters
obstacleList = zeros(0,2);

if(isa(map,'binaryOccupancyMap'))
    occMat = map.occupancyMatrix();
else % This can only be occupancyMap
    occMat = (map.occupancyMatrix() > map.OccupiedThreshold);
end

% Extracting obstacle list
[I, J] = find(occMat);
if(~isempty(I))
    obstacleList = map.grid2world([I, J]);
end
end