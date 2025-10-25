function q = exp(q)
%EXP    Exponential of quaternion
%   EXP(q) is the exponential of the elements of the quaternion array q.
%   For quaternion q = a + v where v = bi + cj + dk,
%       EXP(q) = EXP(a)*( cos(||v||) + (v/||v||)*sin(||v||) ).
%
%   See also LOG.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

a = q.a;
b = q.b;
c = q.c;
d = q.d;

expa = exp(a);
vnorm = sqrt(b.^2 + c.^2 + d.^2);

zero = zeros(1, 1, "like", a);
nz = (vnorm ~= zero);
vnormnz = vnorm(nz);
vscale = expa(nz) .* (sin(vnormnz) ./ vnormnz);

a = expa .* cos(vnorm);
b(nz) = b(nz) .* vscale;
b(~nz) = zero;
c(nz) = c(nz) .* vscale;
c(~nz) = zero;
d(nz) = d(nz) .* vscale;
d(~nz) = zero;

q.a = a;
q.b = b;
q.c = c;
q.d = d;
end
