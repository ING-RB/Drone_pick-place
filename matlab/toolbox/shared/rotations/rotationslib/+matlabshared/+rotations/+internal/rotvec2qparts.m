function [a,b,c,d] = rotvec2qparts(r)
%ROTVEC2QPARTS - quaternion parts from rotation vector in radians
%   This function is for internal use only. It may be removed in the future.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

n = size(r,1);
a = ones(n,1, "like", r);
b = zeros(n,1, "like", r);
c = b;
d = b;

theta = sqrt(sum(r.^2,2));
ct = cos(theta/2);
st = sin(theta/2);

for i = 1:n
    if theta(i) ~= 0
        qimag = (r(i,:)./theta(i)).*st(i);
        a(i) = ct(i);
        b(i) = qimag(1);
        c(i) = qimag(2);
        d(i) = qimag(3);
    end
end
