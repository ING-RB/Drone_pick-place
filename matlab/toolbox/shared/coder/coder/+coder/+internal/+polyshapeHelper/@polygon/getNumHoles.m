function nh = getNumHoles(pgon)
%MATLAB Code Generation Library Function
% Get number of holes in polyshape object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

nb = pgon.numBoundaries;
nh = 0;
for i = 1:nb
    if (pgon.boundaries.isHoleIdx(i))
        nh = nh + 1;
    end
end