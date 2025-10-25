function poly = polySortBoundaries(poly, direction, criterion, refPoint)
%MATLAB Code Generation Private Method

% Copyright 2023-2024 The MathWorks, Inc.
%#codegen

% Polygon should not be affected by sort
poly = poly.updateDerived();
poly.accessOrder = sortBoundaries(poly.accessOrder, poly.boundaries, direction, criterion, refPoint);
