function pgon = polyScale(pgon, ds, center)
%MATLAB Code Generation Library Function
% Implement the scale function

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

scale_x = ds(1);
scale_y = ds(2);
origin_x = center(1);
origin_y = center(2);

% Replace this with an 'all' flag
for ib = 1:pgon.numBoundaries
    pgon.boundaries = bndScale(pgon.boundaries, scale_x, scale_y, ...
                               origin_x, origin_y, ib);
end

% scaling changes geometry, recomputing the properties
pgon.polyClean = false;
pgon = pgon.updateDerived();
