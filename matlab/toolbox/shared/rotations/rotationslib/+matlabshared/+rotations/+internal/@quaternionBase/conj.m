function q = conj(q)
%CONJ   Quaternion conjugate
% CONJ(X) is the quaternion conjugate of X.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

q.b = -q.b;
q.c = -q.c;
q.d = -q.d;
end
