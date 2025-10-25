function tf = binaryIsEqualn(q,p)
%This function is for internal use only. It may be removed in the future. 

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

if isa(q,'matlabshared.rotations.internal.quaternionBase') && isa(p,'matlabshared.rotations.internal.quaternionBase')
    tf = isequaln(q.a,p.a) && isequaln(q.b,p.b) && isequaln(q.c,p.c) && isequaln(q.d,p.d);
elseif isa(q,'matlabshared.rotations.internal.quaternionBase') && isa(p,'numeric')
    z = zeros(size(p),"like",p);
    tf = isequaln(q.a,p) && isequaln(q.b,z) && isequaln(q.c,z) && isequaln(q.d,z);
elseif isa(p,'matlabshared.rotations.internal.quaternionBase') && isa(q,'numeric')
    z = zeros(size(q),"like",q);
    tf = isequaln(p.a,q) && isequaln(p.b,z) && isequaln(p.c,z) && isequaln(p.d,z);
elseif ~isa(q,'matlabshared.rotations.internal.quaternionBase') && ~isa(p,'matlabshared.rotations.internal.quaternionBase')
    % Neither is a quaternion
    tf = isequaln(p,q);
else
    tf = false;
end
end
