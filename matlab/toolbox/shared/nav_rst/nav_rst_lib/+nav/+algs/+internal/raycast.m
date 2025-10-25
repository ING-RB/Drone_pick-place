function [p,collisionGridPts] = raycast(p1, p2, map, resolution, gridLocation)
%This function is for internal use only. It may be removed in the future.

%RAYCAST Test a line for collision
%
%   P = RAYCAST(P1, P2, MAP, RES, LOC) returns a logical representing
%   non-collision with occupied cells (true cells) for a line segment
%   P1=[X1,Y1] to P2=[X2,Y2]. P is true if there is no collision with
%   obstacles and false otherwise. Endpoints are in world coordinate system and
%   can be floating point values. MAP is an N-by-M matrix of logicals, RES
%   is the resolution of the grid cells in cells per meter and LOC is the
%   location of the lower left corner of the grid in the world frame.
%   Inputs P1 and P2 are 1x2 or 2x1 vectors representing points on the grid.
%   X is Column index and Y is row index. This algorithm is known as Digital
%   Differential Analyzer (or DDA).
%
%   [P, COLLISIONGRIDPTS] = RAYCAST(P1, P2, MAP, RES, LOC) also returns in
%   COLLISIONPTS the first grid cell location [X,Y], where the ray
%   intersects an occupied map cell.

%   Copyright 2014-2019 The MathWorks, Inc.
%
%   Reference:
%   [1] "ARTS: Accelerated Ray-Tracing System,", Fujimoto, A.; Tanaka, T.;
%       Iwata, K., Computer Graphics and Applications, IEEE , vol.6, no.4,
%       pp.16,26, April 1986

%#codegen

% For simulation use the mex-file
if coder.target('MATLAB')
    % Run mex
    [p,collisionGridPts] = nav.algs.internal.mex.raycast(p1, p2, map, resolution, gridLocation);
else
    % Run MATLAB-code
    [p,collisionGridPts] = nav.algs.internal.impl.raycastInternal(p1, p2, map, resolution, gridLocation);
end
