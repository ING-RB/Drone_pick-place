function m = compact(q)
%COMPACT Convert quaternion to a real N-by-4 matrix
%   P = COMPACT(Q) converts the quaternion array Q to an N-by-4 matrix.
%   The columns are made from the four quaternion parts. The ith row of P
%   corresponds to element Q(i).

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

m = [ q.a(:),q.b(:),q.c(:),q.d(:) ];
end
