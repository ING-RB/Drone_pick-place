function boundaries = bndRotate(boundaries, theta, ox, oy, this_bd)
% Rotate boundary specified by this_bd

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

[bdStPtr, bdEnPtr] = getBoundary(boundaries, this_bd);

boundaries.vertices = boundaries.vertices.ptRotate(theta, ox, oy, bdStPtr, bdEnPtr);

%rotate centroid using Point2D

cobj = coder.internal.polyshapeHelper.Point2D(boundaries.centroid.X(this_bd), ...
                                              boundaries.centroid.Y(this_bd));

cobj = cobj.rotate(theta, ox, oy);
boundaries.centroid.X(this_bd) = cobj.X;
boundaries.centroid.Y(this_bd) = cobj.Y;

area0 = boundaries.getArea(this_bd);
tol = max(abs(area0 * 1.0e-6), 1.0e-6);
boundaries.clean(this_bd) = false;
boundaries = boundaries.updateArea(this_bd);
if (~boundaries.clean(this_bd) || abs(area0 - boundaries.getArea(this_bd)) > tol)
    coder.internal.error('MATLAB:polyshape:rotateOverflow');
end
