function [v, spx, flag] = testSimplex1(W)
%TESTSIMPLEX1 Check if the line simplex contains the origin, else find
% which part of the shape is closest to the origin and set that as the new
% simplex, setthe new search direction to be from that part of the simplex
% towards the origin.
% 
% [v, spx] = testSimplex1(W)
% 
% Input
%   W   : Specified as a 3-by-4 matrix of coordinate points of Simplex on
%         the Configuration Space.
% Output
%   v   : New search direction vector, specified as a 3-by-1 array.
%   spx : Identifier simplex variable, specified as a scalar.
%  flag : Returns -1 if the set of simplex vertices is collinear, 1 if
%         origin lies inside the simplex, otherwise returns 0.

%   Author: Eri Gualter
%   Copyright 2022 The MathWorks, Inc.

%#codegen
ONEINT  = int32(1);
ZEROINT = int32(0);

% The line simplex is formed by the first two coordinate points of W, whose
% columns are coordinate points [a] and [b]. Then, we need to conduct a
% recursive search to find which region (Voronoi diagram regions: ab,a,b)
% of the line segment contains the origin

% A PRIORI knowledge to reduce the search: we can exclude the region
% outside point [b] because [a] was found in the direction to the origin
% starting from [b]
ab = W(:,2*ONEINT) - W(:,ONEINT);
ao =               - W(:,ONEINT);

% Initiliaze identifier simplex variable as a line
%   1: Point
%   2: Line
%   3: Triangle
spx = 2*ONEINT;

% Initialize collision status flag.
flag = ZEROINT;

%% Test which region (Voronoi diagram regions: ab,a,b) 
if dot(ao,ab) < ZEROINT
    % the origin will be somewhere in the region outside point [a] reset
    % the simplex to [a] and set the new search direction as the vector
    % from [a] to the origin. 
    % Then simplex is reduced to a 'point': spx=1.
    spx = ONEINT;
    v = ao;
else
    % the origin lies somewhere in the region between [a] and [b] and can
    % be projected onto [a,b] so the simplex is just [a,b] and the new
    % search direction is perpendicular to [a,b] in the general direction
    % of the origin
    % Then simplex turns to a 'line': spx=2.
    v = cross(cross(ab,ao),ab);
end
end