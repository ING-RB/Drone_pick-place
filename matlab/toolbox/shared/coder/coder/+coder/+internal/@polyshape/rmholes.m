function PG = rmholes(pshape)
%MATLAB Code Generation Library Function

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

PG = pshape;
if PG.isEmptyShape()
    return
end
if PG.NumHoles > 0
    PG.polyImpl = PG.polyImpl.polyRemoveHoles();
    PG.SimplifyState = -1;
end
