function r = minus(q1,q2)
% - Minus for quaternions
%   A - B subtracts quaternion B from quaternion A using quaternion subtraction.
%   Either A or B may be a real number, in which case subtraction
%   is performed with the real part of the other argument.
%
%   The two inputs A and B must have compatible sizes. In the
%   simplest cases, they can be the same size or one can be a scalar. Two
%   inputs have compatible sizes if, for every dimension, the dimension
%   sizes of the inputs are either the same or one of them is 1.

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

if isa(q1,'matlabshared.rotations.internal.quaternionBase') && isa(q2,'matlabshared.rotations.internal.quaternionBase')
    q1.a = q1.a - q2.a;
    q1.b = q1.b - q2.b;
    q1.c = q1.c - q2.c;
    q1.d = q1.d - q2.d;
    r = q1;
elseif (isa(q1,'double') || isa(q1,'single')) && isreal(q1) && isa(q2,'matlabshared.rotations.internal.quaternionBase')
    q2.a = q1 - q2.a;
    z = zeros(size(q1),"like",q1);
    q2.b = z - q2.b;
    q2.c = z - q2.c;
    q2.d = z - q2.d;
    r = q2;
elseif (isa(q2,'double') || isa(q2,'single')) && isreal(q2) && isa(q1,'matlabshared.rotations.internal.quaternionBase')
    q1.a = q1.a - q2;
    z = zeros(size(q2),"like",q2);
    q1.b = q1.b - z;
    q1.c = q1.c - z;
    q1.d = q1.d - z;
    r = q1;
else
    coder.internal.errorIf(true,'shared_rotations:quaternion:QuatSubReals');
end
end
