function [qo,qv] = prepRotate(q,v,str)
%This function is for internal use only. It may be removed in the future. 
%PREPROTATE Validate and prepare quaternion and value for rotation


%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

%Prep for either frame rotation or point rotation
%Check q
coder.internal.assert(isvector(q),'shared_rotations:quaternion:ExpectedQuat');
%Check v
coder.internal.assert(isa(v,'numeric'),'shared_rotations:quaternion:RotArg2');
validateattributes(v,{'double','single'},{'real','2d','ncols',3},str);
%Check sizes
nq = numel(q);
nv = size(v,1);
coder.internal.assert(nv==nq || nv==1 || nq==1,'shared_rotations:quaternion:RotArgs');
qo = reshape(q,[  ],1);
qo = normalize(qo);
%Make v a quaternion
z = zeros(nv,1,"like",v);
qv = quaternion([ z,v ]);

end
