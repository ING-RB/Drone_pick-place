function [Idx, boundaryId, index] = nearestvertex(pshape, varargin)
%MATLAB Code Generation Library Function

% Copyright 2023 The MathWorks, Inc.
%#codegen

narginchk(2, 3);
coder.internal.polyshape.checkScalar(pshape);

param.allow_inf = false;
param.allow_nan = false;
param.one_point_only = false;
param.errorOneInput = 'MATLAB:polyshape:queryPoint1';
param.errorTwoInput = 'MATLAB:polyshape:queryPoint2';
param.errorValue = 'MATLAB:polyshape:queryPointFiniteValue';
[X, Y] = coder.internal.polyshape.checkPointArray(param, varargin{:});

if isEmptyShape(pshape)
    n = numel(X);
    Idx = zeros(n, 0);
    boundaryId = zeros(n, 0);
    index = zeros(n, 0);
    return;
end

V = [X Y];
[Idx, boundaryId, index] = nearestVertex(pshape.polyImpl, V);
end
