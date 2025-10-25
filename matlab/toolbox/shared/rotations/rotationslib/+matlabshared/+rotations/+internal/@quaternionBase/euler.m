function a = euler(q,seq,pf)
%EULER Convert quaternion to Euler angles in radians
%   A = EULER(Q, SEQ, 'frame') converts the scalar quaternion Q to a 1-by-3
%   matrix of the equivalent Euler angles (in radians) corresponding to
%   rotation sequence SEQ. The Euler angles are suitable for a frame
%   rotation.
%
%   A = EULER(Q, SEQ, 'point') converts the scalar quaternion Q to a 1-by-3
%   matrix of the equivalent Euler angles (in radians) corresponding to
%   rotation sequence SEQ. The Euler angles are suitable for a point
%   rotation.
%
%   If Q is nonscalar, A is an N-by-3 matrix of Euler angles where
%   A(I, :) are the Euler angles corresponding to Q(I).
%
%   The elements of the quaternion array Q are normalized prior to
%   conversion.
%
%   Valid rotation sequences SEQ are 'ZYX', 'ZYZ', 'ZXY', 'ZXZ',
%   'YXZ', 'YXY', 'YZX', 'YZY', 'XYZ', 'XYX', 'XZY', and 'XZX'.
%
%   The order of rotation for sequence 'YZX' is the first rotation about the
%   Y-axis, the second rotation about the Z-axis, the third rotation about
%   the X-axis.
%

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

q = normalize(q);
% The qparts2feul call essentially solves the equations of
% RxRyRz = Mq where Ri is a rotation matrix about axis i, and
% Mq is a rotation matrix from quaternion parts. See Kuipers
% sec 7.9. However Kuipers solves for frame rotation. In the
% 'point' branch, we conjugate the quaternion to get point
% rotation. We also negate the output because qparts2feul uses
% the Ri for frame rotation. The negation of the output angles
% converts to point rotation.
found = true;
switch lower(pf)
    case 'frame'
        a = matlabshared.rotations.internal.qparts2feul(q.a,q.b,q.c,q.d,seq);
    case 'point'
        a = -1*(matlabshared.rotations.internal.qparts2feul(q.a,-q.b,-q.c,-q.d,seq));
    otherwise
        found = false;
        a = zeros(numel(q.a),3,"like",q.a);
end
coder.internal.assert(found,'shared_rotations:quaternion:QuatPointFrame');
end
