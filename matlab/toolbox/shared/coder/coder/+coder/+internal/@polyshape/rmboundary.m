function PG = rmboundary(pshape, I, varargin)
%MATLAB Code Generation Library Function
% RMBOUNDARY Remove boundary in polyshape

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkScalar(pshape);
coder.internal.polyshape.checkEmpty(pshape);
II = coder.internal.polyshape.checkIndex(pshape, I);

simpl = 'd';
ninputs = numel(varargin);
coder.internal.assert( mod(ninputs, 2) == 0, 'MATLAB:polyshape:nameValuePairError');

coder.unroll();
for k = 1:2:ninputs
    name = char(varargin{k});
    nn = max(length(name), 1);
    coder.internal.assert(coder.internal.isConst(name), ...
                          'Coder:toolbox:ParameterNamesMustBeConstant');
    coder.internal.assert(coder.internal.isCharOrScalarString(varargin{k}), ...
                          'MATLAB:polyshape:rmBoundaryParameter');
    coder.internal.assert(strncmpi(name,'simplify',nn), ...
                          'MATLAB:polyshape:rmBoundaryParameter');

    next_arg = varargin{k+1};
    coder.internal.assert(isscalar(next_arg) && (islogical(next_arg) || isnumeric(next_arg)), ...
                          'MATLAB:polyshape:simplifyValue');
    coder.internal.assert(double(next_arg) == 1 || double(next_arg) == 0, ...
                          'MATLAB:polyshape:simplifyValue');
    if double(next_arg) == 1
        simpl = 't';
    else
        simpl = 'f';
    end
end

PG = pshape;
PG.polyImpl = removeBoundary(PG.polyImpl, II);

if simpl == 't' || (simpl == 'd' && ...
                    pshape.SimplifyState >= 0)
    PG = checkAndSimplify(PG, true);
    PG.SimplifyState = 1;
else
    PG.SimplifyState = -1;
end
