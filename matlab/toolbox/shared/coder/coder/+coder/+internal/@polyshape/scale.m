function PG = scale(pshape, s, center)
%MATLAB Code Generation Library Function
% SCALE Scale the polyshape by factor

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

coder.internal.assert(nargin >= 2, 'MATLAB:polyshape:scaleFactorMissing');

coder.internal.polyshape.checkArray(pshape);

if nargin == 2
    center = [0 0];
else
    param.allow_inf = false;
    param.allow_nan = false;
    param.one_point_only = true;
    param.errorOneInput = 'MATLAB:polyshape:scaleCenter';
    param.errorTwoInput = 'MATLAB:polyshape:scaleCenter';
    param.errorValue = 'MATLAB:polyshape:scaleCenterValue';
    [X, Y] = coder.internal.polyshape.checkPointArray(param, center);
    center = [X Y];
end

coder.internal.assert(isnumeric(s) && isreal(s) && allfinite(s), ...
                      'MATLAB:polyshape:scaleFactorValue');
coder.internal.errorIf(issparse(s), 'MATLAB:polyshape:sparseError');
coder.internal.errorIf(numel(s) == 0 || numel(s) > 2 || (iscolumn(s) && numel(s) == 2), ...
                       'MATLAB:polyshape:scaleInputsError');
coder.internal.assert(coder.internal.scalarizedAll(@(x)(x > 0),s), ...
                      'MATLAB:polyshape:scaleFactorValue');

if isscalar(s)
    ds = [double(s) double(s)];
else
    ds = double(s);
end

PG = pshape;
if PG.isEmptyShape()
    return
end

PG.polyImpl = PG.polyImpl.polyScale(ds, center);
