function PG = translate(pshape, varargin)
%MATLAB Code Generation Library Function
% TRANSLATE Translate a polyshape

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

narginchk(2, 3);

coder.internal.polyshape.checkArray(pshape);

param.allow_inf = false;
param.allow_nan = false;
param.one_point_only = true;
param.errorOneInput = 'MATLAB:polyshape:transVector1';
param.errorTwoInput = 'MATLAB:polyshape:transVector2';
param.errorValue = 'MATLAB:polyshape:transVectorValue';
[X, Y] = coder.internal.polyshape.checkPointArray(param, varargin{:});

PG = pshape;
if PG.isEmptyShape()
    return
end

PG.polyImpl = PG.polyImpl.polyShift(X, Y);
