function tf = binaryIsEqual(q,p)
%This function is for internal use only. It may be removed in the future. 

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

if isa(q,'matlabshared.rotations.internal.quaternionBase') && isa(p,'matlabshared.rotations.internal.quaternionBase')
    tf = isequal(q.a,p.a) && isequal(q.b,p.b) && isequal(q.c,p.c) && isequal(q.d,p.d);
elseif isa(q,'matlabshared.rotations.internal.quaternionBase') && isa(p,'numeric')
    z = zeros(size(p),"like",p);
    tf = isequal(q.a,p) && isequal(q.b,z) && isequal(q.c,z) && isequal(q.d,z);
elseif isa(p,'matlabshared.rotations.internal.quaternionBase') && isa(q,'numeric')
    z = zeros(size(q),"like",q);
    tf = isequal(p.a,q) && isequal(p.b,z) && isequal(p.c,z) && isequal(p.d,z);
elseif ~isa(q,'matlabshared.rotations.internal.quaternionBase') && ~isa(p,'matlabshared.rotations.internal.quaternionBase')
    % Neither is a quaternion
    tf = isequal(p,q);
else
    tf = false;
end
end
