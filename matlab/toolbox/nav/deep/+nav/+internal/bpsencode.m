function [dist, basis, obstacles] = bpsencode(map, encodingSize)
% This class is for internal use only. It may be removed in the future.

%bpsencode Encode environment using Basis Point Set encoding
%
% Inputs:
%   Map: binaryOccupancyMap or occupancyMap
%   EncodingSize: [1,2] vector containing the target encoding size
% Outputs:
%   DIST: Distance from basis points to nearest obstacles
%   BASIS: Coordinates of basis points
%   OBSTACLES: Coordinates of nearest obstacles from basis points
%
% Example:
%   map = mapMaze(5, 1, MapSize=[10,10], MapResolution=2.5);
%   encodingSize = [9, 9];
%   [dist, basis, obstacles] = nav.internal.bpsencode(map, encodingSize);
%   % Visualize
%   show(map); hold on;
%   scatter(basis(:,1), basis(:,2), 'filled', DisplayName='BPS')
%   scatter(obstacles(:,1), obstacles(:,2), 'filled', DisplayName='Obstacles')
%   quiver(basis(:,1), basis(:,2), obstacles(:,1)-basis(:,1), ...
%       obstacles(:,2)-basis(:,2), 0, Color='black', DisplayName='delta vector')

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Check occupancy
    mapMatrix = map.checkOccupancy([1,1], map.GridSize, 'grid');

    % Get signed distance field
    sdf = signedDistanceMap(mapMatrix, Resolution=map.Resolution);

    % Compute basis points in world frame
    alpha = diff(map.XWorldLimits)./map.GridSize; % exclude border cells
    xlimits = [map.XWorldLimits(1)+alpha(1), map.XWorldLimits(2)-alpha(1)];
    ylimits = [map.YWorldLimits(1)+alpha(2), map.YWorldLimits(2)-alpha(2)];
    basis = nav.algs.internal.basispoints("rectgrid", encodingSize, [xlimits; ylimits]);

    % Compute distance in world frame
    dist = sdf.distance(basis);
    dist = dist(:);

    if nargout>2
        % Compute coordinates of nearest obstacles in the world frame
        obstacles = sdf.closestBoundary(basis);
        obstacles = squeeze(obstacles);
    end
end
