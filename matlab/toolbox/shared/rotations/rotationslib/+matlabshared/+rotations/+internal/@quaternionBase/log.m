function q = log(q)
%LOG    Natural logarithm of quaternion
%   LOG(q) is the natural logarithm of the elements of the quaternion 
%   array q. For quaternion q = a + v where v = bi + cj + dk,
%       LOG(q) = LOG(||q||) + (v/||v||)*acos(a/||q||).
%
%   See also EXP.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

a = q.a;
b = q.b;
c = q.c;
d = q.d;

vnorm = sqrt(b.^2 + c.^2 + d.^2);
qnorm = sqrt(a.^2 + vnorm.^2);

zero = zeros(1, 1, "like", a);
nz = (vnorm ~= zero);
vnormnz = vnorm(nz);
vscale = acos(a(nz) ./ qnorm(nz)) ./ vnormnz;

a = log(qnorm);
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
