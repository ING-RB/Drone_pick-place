function n = norm(q)
%NORM Norm of a quaternion
%   N = NORM(Q) computes the norm of a quaternion Q. The norm is defined as
%   the square root of CONJ(Q) * Q.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

n = sqrt(q.a .* q.a + q.b .* q.b + q.c .* q.c + q.d .* q.d);
end
