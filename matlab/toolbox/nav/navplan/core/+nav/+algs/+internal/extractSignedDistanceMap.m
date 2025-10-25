function sdfMap = extractSignedDistanceMap(map, interpolationMethod)
% This function is for internal use only. It may be removed in the future.

% extractSignedDistanceMap Extract a signed distance map from an occupancy
% map, which is utilized in functions like optimizePath or controllerTEB
% for processing obstacle information.
%
%   INPUTS:
%       MAP                 : binaryOccupancyMap or occupancyMap input
%       INTERPOLATIONMETHOD : Interpolation method for signedDistanceMap
%   OUTPUTS:
%       SDFMAP              : Signed distance map output
%

%{
% Example:
sdfMap = nav.algs.internal.extractSignedDistanceMap(binaryOccupancyMap);
%}

% Copyright 2024 The MathWorks, Inc.

%#codegen

arguments
    map {mustBeA(map, {'occupancyMap', 'binaryOccupancyMap'})}
    interpolationMethod (1,1) string {mustBeMember(interpolationMethod, {'none', 'linear'})} = 'linear'
end

if(isa(map,'binaryOccupancyMap'))
    occMat = map.occupancyMatrix();
else % This can only be occupancyMap. If its vehicleCostmap, it must be converted to this.
    occMat = (map.occupancyMatrix() > map.OccupiedThreshold);
end

sdfMap = signedDistanceMap(occMat, map.Resolution, InterpolationMethod=interpolationMethod);
sdfMap.GridOriginInLocal = map.GridOriginInLocal;
sdfMap.GridLocationInWorld = map.GridLocationInWorld;