function b = isEqual(pg, other)
%MATLAB Code Generation Library Function
% used to test equality of 2 polyshape objects

%   Copyright 2023 The MathWorks, Inc.

%#codegen

if (pg.polyNumPoints ~= other.polyNumPoints)
    b = false;
    return;
elseif (pg.polyNumPoints == 0)
    b = true;
    return;
end

if (~(pg.nestingResolved == other.nestingResolved && ...
        pg.numBoundaries() == other.numBoundaries()))
    b = false;
    return;
end

if ~isEqual(pg.boundaries, other.boundaries)
    b = false;
    return;
end

if ~isequal(pg.accessOrder, other.accessOrder)
    b = false;
    return;
end

b = true;
