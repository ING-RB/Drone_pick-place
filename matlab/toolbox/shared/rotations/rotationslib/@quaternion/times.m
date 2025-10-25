function o = times(x,y)
% .*  Quaternion multiplication of arrays
%   X.*Y denotes element-by-element quaternion multiplication of quaternion arrays.
%   Either X or Y may be a real array. In this case real x
%   quaternion multiplication is performed.
%
%   X and Y must have compatible sizes. In the simplest cases,
%   they can be the same size or one can be a scalar. Two inputs
%   have compatible sizes if, for every dimension, the dimension
%   sizes of the inputs are either the same or one of them is 1.

%   Copyright 2018 The MathWorks, Inc.    

if isa(y,'matlabshared.rotations.internal.quaternionBase') && isa(x,'matlabshared.rotations.internal.quaternionBase')
    xa = x.a;
    xb = x.b;
    xc = x.c;
    xd = x.d;
    ya = y.a;
    yb = y.b;
    yc = y.c;
    yd = y.d;
    x.a = xa .* ya - xb .* yb - xc .* yc - xd .* yd;
    x.b = xa .* yb + xb .* ya + xc .* yd - xd .* yc;
    x.c = xa .* yc - xb .* yd + xc .* ya + xd .* yb;
    x.d = xa .* yd + xb .* yc - xc .* yb + xd .* ya;
    o = x;
elseif (isa(y,'double') || isa(y,'single')) && isreal(y) && isa(x,'matlabshared.rotations.internal.quaternionBase')
    x.a = y .* x.a;
    x.b = y .* x.b;
    x.c = y .* x.c;
    x.d = y .* x.d;
    o = x;
elseif (isa(x,'double') || isa(x,'single')) && isreal(x) && isa(y,'matlabshared.rotations.internal.quaternionBase')
    y.a = x .* y.a;
    y.b = x .* y.b;
    y.c = x .* y.c;
    y.d = x .* y.d;
    o = y;
else
    coder.internal.errorIf(true,'shared_rotations:quaternion:QuatTimesReals');
end
end
