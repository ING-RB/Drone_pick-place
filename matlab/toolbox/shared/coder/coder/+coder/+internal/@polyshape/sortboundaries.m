function PG = sortboundaries(pshape, varargin)

%#codegen

% Copyright 2023-2024 The MathWorks, Inc.

coder.internal.polyshape.checkScalar(pshape); % Change to array check when arrays of objects is supported
[direction, criterion, refPoint] = coder.internal.polyshape.checkSortInput(varargin{:});

PG = pshape;
if pshape.isEmptyShape()
    return
end

PG.polyImpl = PG.polyImpl.polySortBoundaries(direction, criterion, refPoint);
