function PG = addboundary(pshape, varargin)
%MATLAB Code Generation Library Function

% ADDBOUNDARY Add boundaries to a polyshape

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

narginchk(2, inf);
coder.internal.polyshape.checkScalar(pshape);

[X, Y, tc, simpl, collinear] = coder.internal.polyshape.checkInput(varargin{:});

PG = pshape;
PG.polyImpl = addBoundary(PG.polyImpl, X, Y, tc, uint32(0));

% set collinear status of polyshape
if collinear == 'd'
    PG.KeepCollinearPoints = pshape.KeepCollinearPoints;
else
    PG.KeepCollinearPoints = (collinear == 't');
end

% set SimplifyState and simplify polyshape
if simpl == 't' || (simpl == 'd' && pshape.SimplifyState >= 0)
    PG = checkAndSimplify(PG, true);
else
    PG.SimplifyState = -1;
end
