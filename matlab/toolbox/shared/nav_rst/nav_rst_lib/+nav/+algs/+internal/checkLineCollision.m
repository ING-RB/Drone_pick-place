function status = checkLineCollision(start, goal, map)
%This function is for internal use only. It may be removed in the future.

%checkLineCollision Inflate binary occupancy grid
%   IM = checkLineCollision(START, GOAL, MAP) returns a logical true indicating
%   that the line between start and goal point only touches obstacle-free cells.
%   Returns false if the line touches any occupied or unknown cells.

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

% Extract occupancy grid data
    if isa(map, 'binaryOccupancyMap')
        grid = map.occupancyMatrix;
    else
        % Unknown cells are treated as occupied
        grid = logical(map.occupancyMatrix('ternary'));
    end

    status = nav.algs.internal.raycast(start, goal, ...
                                       grid, map.Resolution, map.GridLocationInWorld);

end
