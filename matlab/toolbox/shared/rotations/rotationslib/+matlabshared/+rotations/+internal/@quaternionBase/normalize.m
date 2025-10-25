function q = normalize(q)
%NORMALIZE Normalize a quaternion
%   P = NORMALIZE(Q) computes a normalized quaternion P for a quaternion Q.
%   The NORM of P is 1.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

n = sqrt(q.a .* q.a + q.b .* q.b + q.c .* q.c + q.d .* q.d);
q.a = q.a ./ n;
q.b = q.b ./ n;
q.c = q.c ./ n;
q.d = q.d ./ n;
end
