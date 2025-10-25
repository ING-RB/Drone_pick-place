function q = power(q, n)
%.^  Quaternion array power.
%   R = Q.^N denotes element-by-element powers. Q and N must have 
%   compatible sizes. In the simplest cases, they can be the same size or
%   one can be a scalar. Two inputs have compatible sizes if, for every
%   dimension, the dimension sizes of the inputs are either the same or one
%   of them is 1.
%
%   See also EXP, LOG.

%   Copyright 2018-2024 The MathWorks, Inc.    



validExponent = ( (isa(n, 'double') || isa(n, 'single')) && isreal(n) );
coder.internal.errorIf(~validExponent, ...
    'shared_rotations:quaternion:QuatPowerReal');

a = q.a;
b = q.b;
c = q.c;
d = q.d;

vnorm = sqrt(b.^2 + c.^2 + d.^2);
qnorm = sqrt(a.^2 + vnorm.^2);

ntheta = n .* acos(a ./ qnorm);
zero = zeros(1, 1, "like", ntheta);
ntheta(isnan(ntheta)) = zero;
qnormn = qnorm .^ n;

vscale = qnormn .* sin(ntheta) ./ vnorm;
vscale(isnan(vscale)) = zero;

a = qnormn .* cos(ntheta);
b = b .* vscale;
c = c .* vscale;
d = d .* vscale;

q.a = a;
q.b = b;
q.c = c;
q.d = d;
