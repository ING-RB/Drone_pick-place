function q = single(q)
%SINGLE Convert quaternion parts to single precision
%
% See also double, cast

%   Copyright 2018 The MathWorks, Inc.    

q.a = single(q.a);
q.b = single(q.b);
q.c = single(q.c);
q.d = single(q.d);
end
