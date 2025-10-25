function u = rotatepoint(q,v)
%ROTATEPOINT quaternion point rotation
%  U = ROTATEPOINT(Q,V) rotates the  the points in matrix V
%  using quaternion Q. U and V are N-by-3 matrices where the columns are the [X Y Z]
%  coordinates. Q can be an N-by-1 or 1-by-N vector.
%
%  The inputs Q and V must have compatible sizes. If V is N-by-3 Q can be a scalar or N-element
%  vector. If V is 1-by-3, Q can be a scalar or N-element vector.
%
%  The elements of Q are normalized prior to use in rotation.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

[qo,qv] = prepRotate(q,v,'rotatepoint');
uq = qo .* qv .* conj(qo);
up = compact(uq);
u = up(:,2:end);
end
