function PG = rotate(pshape, theta, center)
%MATLAB Code Generation Library Function
% ROTATE Rotate a polyshape

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

coder.internal.assert(nargin>=2, 'MATLAB:polyshape:rotateAngleMissing')

coder.internal.polyshape.checkArray(pshape);

theta = coder.internal.polyshape.checkScalarValue(theta, 'MATLAB:polyshape:rotateAngleError');
if theta >= 360 || theta <= -360
    theta = rem(theta, 360);
end

theta = deg2rad(theta);

if nargin == 2
    center = [0 0];
else
    param.allow_inf = false;
    param.allow_nan = false;
    param.one_point_only = true;
    param.errorOneInput = 'MATLAB:polyshape:rotateCenter';
    param.errorTwoInput = 'MATLAB:polyshape:rotateCenter';
    param.errorValue = 'MATLAB:polyshape:rotateCenterValue';
    [X, Y] = coder.internal.polyshape.checkPointArray(param, center);
    center = [X Y];
end

PG = pshape;
if PG.isEmptyShape()
    return
end

PG.polyImpl = PG.polyImpl.polyRotate(theta, center);
