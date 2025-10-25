function [x,u,v,w,dist2] = closestPointOnTriangleToOrigin(a,b,c)
% CLOSESTPOINTONTRIANGLETOPOINT computes the closest point on a triangle
% to a given point that projects onto the face of that triangle, the
% barycentric coordinates of that point with respect to the triangle,
% and the minimum distance between that point and the triangle
%
% INPUTS
% a,b,c : coordinates of the points of the triangle [{2,3}x1],
% p     : point being evaluated [3x1] - must project ON the face of
%                                       the triangle [a,b,c]
%
% OUTPUT
% x     : coordinates of the point on the triangle closest to origin [{2,3}x1]
% u,v,w : scalar barycentric coordinates of x with respect to [a,b,c]
% dist2 : scalar squared distance between p and the triangle
%#codegen

%   Author: Carlos F. Osorio, Eri Gualter
%   Copyright 2019-2022 The MathWorks, Inc.

% define the sides of the triangle as vectors
ab = b - a;
ac = c - a;
% define the vectors from each vertex to the origin
ap = -a;
bp = -b;
cp = -c;

% compute six temporary quantities for using Lagrange identity
% (a×b)·(c×d) = (a·c)(b·d)-(a·d)(b·c) to avoid cross products
d1 = dot(ab,ap);
d2 = dot(ac,ap);
d3 = dot(ab,bp);
d4 = dot(ac,bp);
d5 = dot(ab,cp);
d6 = dot(ac,cp);

va = d3*d6 - d5*d4;
vb = d5*d2 - d1*d6;
vc = d1*d4 - d3*d2;

% compute the location of x on the face of the triangle using its
% barycentric coordinates
denom = 1/(va + vb + vc);
v = vb*denom;
w = vc*denom;

x = a + v*ab + w*ac;
u = 1 - v - w;

% distance squared
dist2 = dot(x,x);

end