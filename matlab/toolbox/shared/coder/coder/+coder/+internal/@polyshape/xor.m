function [PG, shapeId, vertexId] = xor(subject, clip, varargin)
%MATLAB Code Generation Library Function
% XOR Find the xor of two polyshapes

% Copyright 2024 The MathWorks, Inc.

%#codegen

narginchk(2, inf);
nargoutchk(0, 3);
coder.internal.polyshape.checkArray(subject);
coder.internal.polyshape.checkArray(clip);
[~, collinear,simplify] = polyshape.parseIntersectUnionArgs(false, varargin{:});

if nargout > 1
    coder.internal.assert(isscalar(subject) && isscalar(clip), 'MATLAB:polyshape:noVertexMapping');
end
[PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, ...
    uint8(coder.internal.polyshapeHelper.booleanOpsEnum.XOR), simplify);
