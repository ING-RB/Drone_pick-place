function r = rotmat(q,pf)
%ROTMAT Convert quaternion to a rotation matrix or direction cosine matrix
%   R = ROTMAT(Q, 'frame') converts the scalar quaternion Q to a 3-by-3 matrix
%   of the equivalent rotation matrix, suitable for frame rotation.
%
%   R = ROTMAT(Q, 'point') converts the scalar quaternion Q to a 3-by-3 matrix
%   of the equivalent rotation matrix, suitable for point rotation.
%
%   If Q is nonscalar, R is a 3-by-3-by-N array of rotation matrices where
%   R(:,:,I) is the rotation matrix corresponding to Q(I).
%
%   The elements of the quaternion array Q are normalized prior to conversion.

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

coder.internal.assert(any(strcmpi(pf,{'point','frame'})),'shared_rotations:quaternion:QuatPointFrame');
q = normalize(q);
the2 = cast(2,classUnderlying(q));
the1 = cast(1,classUnderlying(q));
ta = q.a(:);
tb = q.b(:);
tc = q.c(:);
td = q.d(:);
ab2 = ta .* tb .* the2;
ac2 = ta .* tc .* the2;
ad2 = ta .* td .* the2;
bc2 = tb .* tc .* the2;
bd2 = tb .* td .* the2;
cd2 = tc .* td .* the2;
aasq = ta .* ta .* the2 - the1;
bbsq = tb .* tb .* the2;
ccsq = tc .* tc .* the2;
ddsq = td .* td .* the2;
rmat = zeros(3,3,numel(ta),"like",ta);
for ii = 1:numel(ta)
    aasqi = aasq(ii);
    bc2i = bc2(ii);
    bd2i = bd2(ii);
    ac2i = ac2(ii);
    ad2i = ad2(ii);
    cd2i = cd2(ii);
    ab2i = ab2(ii);
    rmat(:,:,ii) = [ (aasqi + bbsq(ii)),(bc2i + ad2i),(bd2i - ac2i); (bc2i - ad2i),(aasqi + ccsq(ii)),(cd2i + ab2i); (bd2i + ac2i),(cd2i - ab2i),(aasqi + ddsq(ii)) ];
end
r = squeeze(rmat);
if strcmpi(pf,'point')
    r = permute(r,[ 2,1,3 ]);
end
end
