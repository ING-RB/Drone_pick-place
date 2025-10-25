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

%   Copyright 2021-2024 The MathWorks, Inc.    

%#codegen 
            
% Honor user request for implicit expansion
coder.internal.implicitExpansionBuiltin;

% Ensure compatible dims, else throw a proper error.
quatAssertCompatibleDims(q1,q2);

if isa(q1,'matlabshared.rotations.internal.quaternionBase') && isa(q2,'matlabshared.rotations.internal.quaternionBase')
    a = q1.a - q2.a;
    b = q1.b - q2.b;
    c = q1.c - q2.c;
    d = q1.d - q2.d;
elseif (isa(q1,'double') || isa(q1,'single')) && isreal(q1) && isa(q2,'matlabshared.rotations.internal.quaternionBase')
    a = q1 - q2.a;
    z = zeros(size(q1),"like",q1);
    b = z - q2.b;
    c = z - q2.c;
    d = z - q2.d;
elseif (isa(q2,'double') || isa(q2,'single')) && isreal(q2) && isa(q1,'matlabshared.rotations.internal.quaternionBase')
    a = q1.a - q2;
    z = zeros(size(q2),"like",q2);
    b = q1.b - z;
    c = q1.c - z;
    d = q1.d - z;
else
    coder.internal.errorIf(true,'shared_rotations:quaternion:QuatSubReals');
end

r = matlabshared.rotations.internal.coder.quaternioncg(a,b,c,d);
end
