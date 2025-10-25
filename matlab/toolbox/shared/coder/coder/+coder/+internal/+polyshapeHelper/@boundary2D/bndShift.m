function boundaries = bndShift(boundaries, x, y, this_bd)
% Translate boundary specified by this_bd

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

[bdStPtr, bdEnPtr] = getBoundary(boundaries, this_bd);

boundaries.vertices = boundaries.vertices.ptShift(x,y,bdStPtr, bdEnPtr);

% a pretty relaxed tolerance to check validity of shifting
area0 = boundaries.getArea(this_bd);
tol = max(abs(area0 * 1.0e-6), 1.0e-6);
boundaries.clean(this_bd) = false;
boundaries = boundaries.updateArea(this_bd);

if (~boundaries.clean(this_bd) || abs(area0 - boundaries.getArea(this_bd)) > tol)
    coder.internal.error('MATLAB:polyshape:transOverflow');
end
