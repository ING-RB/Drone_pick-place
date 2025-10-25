function pgon = polyRotate(pgon, theta, center)
%MATLAB Code Generation Library Function
% Implement the rotate function

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

ox = center(1);
oy = center(2);
% Replace this with an 'all' flag
for ith = 1:getNumBoundaries(pgon)
    pgon.boundaries = pgon.boundaries.bndRotate(theta, ox, oy, ith);
end

% Rotate centroid using Point2D

cobj = coder.internal.polyshapeHelper.Point2D(pgon.polyCentroid.X, ...
                                              pgon.polyCentroid.Y);

cobj = cobj.rotate(theta, ox, oy);
pgon.polyCentroid.X = cobj.X;
pgon.polyCentroid.Y = cobj.Y;

pgon.polyClean = false;
pgon = pgon.updateDerived();
