function disp(q,varargin)
%DISP Display quaternion array

%   Copyright 2018 The MathWorks, Inc.    

if nargin<2
    name = inputname(1);
else
    name = varargin{1};
end
matlabshared.rotations.internal.privquatdisp(q.a,q.b,q.c,q.d,name);
end
