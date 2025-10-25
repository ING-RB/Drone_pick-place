function x = dist(q,p)
%DIST angular distance in radians
%   D = DIST(Q,P) computes the angular distance in radians between
%   quaternions P and Q.  P and Q must have compatible sizes. In the
%   simplest cases, they can be the same size or one can be a scalar. Two
%   inputs have compatible sizes if, for every dimension, the dimension
%   sizes of the inputs are either the same or one of them is 1.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(isequal(class(q),class(p)),'shared_rotations:quaternion:QuatAllArgs');
deltaQuat = normalize(q .* conj(p));
%Make deltaQuat have a positive angle to compensate for acos
%limits
rpart = deltaQuat.a;
idx = rpart<0;
if any(idx(:))
    rpart(idx) = -rpart(idx);
end
x = 2 .* acos(rpart);
end
