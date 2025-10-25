function [ranges, collisionLoc] = calculateRanges(pose, angles, maxRange, ...
                                                  grid, gridSize, resolution, gridLocationInWorld)
    %This function is for internal use only. It may be removed in the future.

    %calculateRanges Calculate simulated range readings
    %   Based on the current robot position and a known map, calculate the
    %   simulated range readings (RANGES) and exact locations of where the
    %   simulated beams hit obstacles (COLLISIONLOC).
    %
    %   [RANGES, COLLISONPT] = CALCULATERANGES(POSE, ANGLES, MAXRANGE, GRID, GRIDSIZE, RES, LOC)
    %   returns a Nx1 array of ranges and Nx2 array of collision points for
    %   1x3 POSE, Nx1 ANGLES, scalar MAXRANGE, PxQ logical matrix GRID, size
    %   of the grid 1x2 GRIDSIZE, scalar resolution RES and 1x2 grid location
    %   in world LOC.

    %   Copyright 2015-2019 The MathWorks, Inc.

    %#codegen

    robotPosition = pose(1:2);
    v1 = robotPosition;

    % 10*eps('double') is used as a constant error threshold for cases where
    % the intersection point lies on a grid line
    halfEdge = 10*eps('double')+1/(2*resolution);

    % Tolerance used when determining if the calculated intersection point should be
    % considered. Originally used by intersectLinePolygon.
    tol = 1e-14;

    supportLines = [0, 0, halfEdge*2 0;
                    0, 0, 0 halfEdge*2];

    % Preallocate outputs
    ranges = nan(length(angles),1);
    collisionLoc = zeros(length(angles),2);
    for i=1:length(angles)
        pos = robotPosition + maxRange*[cos(angles(i)+pose(3)) sin(angles(i)+pose(3))];
        collisionLoc(i,:) = pos;
        [isObstacleFree,collisionPts] = nav.algs.internal.raycast(robotPosition, pos, ...
                                                          grid, resolution, gridLocationInWorld);

        if ~isObstacleFree
            % The collision location is returned as center point of
            % a grid cell
            collisionLoc(i,:) = gridToWorld(collisionPts, gridSize, resolution, gridLocationInWorld);

            v2 = pos;

            x = collisionLoc(i,1);
            y = collisionLoc(i,2);

            line = [v1(1), v1(2), v2(1)-v1(1), v2(2)-v1(2)];

            % Find distance to bottomLeft corner of the collision cell
            dBotLeftCorner = collisionLoc(i,:)-v1;

            supportLines(1) = x-halfEdge;
            supportLines(4) = y-halfEdge;

            % Use bottom left sides of cell if ray origin is bottomLeft of
            % the bottomLeft cell corner, if the ray origin is inside the
            % cell, the sides should be towards the ray's destination.
            if dBotLeftCorner(1) > halfEdge || (dBotLeftCorner(1) > -halfEdge && sign(line(3)) < 0)
                supportLines(2) = x-halfEdge;
            else
                supportLines(2) = x+halfEdge;
            end
            if dBotLeftCorner(2) > halfEdge || (dBotLeftCorner(2) > -halfEdge && sign(line(4)) < 0)
                supportLines(3) = y-halfEdge;
            else
                supportLines(3) = y+halfEdge;
            end

            % Find locations where ray intersects the line(s)
            ints = intersectLines(line, supportLines, tol);

            % find edges that are not parallel to the input line
            inds = find(isfinite(ints(:, 1)));

            % compute position of intersection points on corresponding lines
            linePos = linePosition(ints(inds, :), supportLines(inds, :), 'diag');

            % and keep only intersection points located on edges
            b = linePos > -tol & linePos < 1+tol;

            inds = inds(b);
            ints = ints(inds, :);
            norms = sqrt(sum((ints - repmat(v1,size(ints,1),1)).^2,2));

            if numel(norms) == 1
                ranges(i) = norms;
                collisionLoc(i,:) = ints(1,:);
            elseif numel(norms) > 1
                [~,idx] = min(norms);
                ranges(i) = norms(idx);
                collisionLoc(i,:) = ints(idx,:);
            else
                ranges(i) = norm([x,y] - v1);
            end
        end
    end
end

function xy = gridToWorld(ij, gridSize, resolution, gridLocationInWorld)
%gridToWorldPrivate Convert grid indices to world coordinates

% ROW-COL is YX, so convert it to XY
    ji = flip(ij, 2);

    % Cell index can only increment by 1
    halfCell = 0.5;

    % Y-axis starts at top, reverse it to start at bottom
    ji(:,2) = gridSize(1)+1 - ji(:,2);

    % Compute the transform to converts index to world coordinate
    tform = ([halfCell, halfCell])/resolution - ...
            gridLocationInWorld;

    % Apply transform
    xy = ji/resolution - tform;
    assert(all(size(xy) == [1 2]));
end
