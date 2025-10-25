function pgon = polyShift(pgon, shift_x, shift_y)
%MATLAB Code Generation Library Function
% Implement the translate function

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen
% Replace this with an 'all' flag
for ith = 1:pgon.numBoundaries
    pgon.boundaries = bndShift(pgon.boundaries, shift_x, shift_y, ith);
end

pgon.polyCentroid.X = pgon.polyCentroid.X + shift_x;
pgon.polyCentroid.Y = pgon.polyCentroid.Y + shift_y;
pgon.polyBbox.loX = pgon.polyBbox.loX + shift_x;
pgon.polyBbox.loY = pgon.polyBbox.loY + shift_y;
pgon.polyBbox.hiX = pgon.polyBbox.hiX + shift_x;
pgon.polyBbox.hiY = pgon.polyBbox.hiY + shift_y;
