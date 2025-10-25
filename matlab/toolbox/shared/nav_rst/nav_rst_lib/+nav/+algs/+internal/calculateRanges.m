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

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

% For simulation use the mex-file
if coder.target('MATLAB')
    % Run mex
    [ranges, collisionLoc] = nav.algs.internal.mex.calculateRanges(pose, ...
                                                      angles, maxRange, grid, gridSize, resolution, gridLocationInWorld);
else
    % Run MATLAB-code
    [ranges, collisionLoc] = nav.algs.internal.impl.calculateRanges(pose, ...
                                                      angles, maxRange, grid, gridSize, resolution, gridLocationInWorld);
end
