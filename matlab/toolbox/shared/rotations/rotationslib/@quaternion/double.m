function q = double(q)
%DOUBLE Convert quaternion parts to double precision
%
% See also single, cast

%   Copyright 2018 The MathWorks, Inc.    

q.a = double(q.a);
q.b = double(q.b);
q.c = double(q.c);
q.d = double(q.d);
end
