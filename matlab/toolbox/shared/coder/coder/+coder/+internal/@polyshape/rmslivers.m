function PG = rmslivers(pshape, din)
%MATLAB Code Generation Library Function

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkScalar(pshape); % Convert to array check for array of objects support

d = coder.internal.polyshape.checkScalarValue(din, 'MATLAB:polyshape:sliverTolError');

coder.internal.errorIf(d<=0, 'MATLAB:polyshape:sliverTolError');

PG = pshape;
if pshape.isEmptyShape()
    return
end

PG.polyImpl = cleanup(PG, d);
PG.SimplifyState = -1;
