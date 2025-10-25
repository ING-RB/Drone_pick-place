function [x,u,v,dist2] = closestPointOnEdgeToOrigin(a,b)
%CLOSESTPOINTONEDGETOPOINT computes the closest point on an edge segment
% to origin that projects onto that edge segment, the barycentric
% coordinates of that point with respect to the edge segment, and the
% minimum distance between that point and the edge segment
%
% INPUTS
% a,b  : coordinates of the end points of the edge segment [{2,3}x1]
%
% OUTPUT
% x    : coordinates of the point on the edge segment closest to origin
% u,v  : scalar barycentric coordinates of x with respect to [a,b]
% dist2: scalar squared distance between origin and the edge
%#codegen

%   Author: Carlos F. Osorio, Eri Gualter
%   Copyright 2019-2022 The MathWorks, Inc.

% define the segment as a vector
ab = b - a;
ap =   - a;

% project the point p onto the edge segment 
v = dot(ap,ab)/dot(ab,ab);

% compute the location of x on the edge segment using its barycentric
% coordinates
x = a + v*ab;
u = 1-v;

% distance squared
dist2 = dot(x,x);

end