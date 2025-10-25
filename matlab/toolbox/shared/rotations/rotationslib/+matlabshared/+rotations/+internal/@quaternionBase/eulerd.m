function a = eulerd(q,seq,pf)
%EULERD Convert quaternion to Euler angles in degrees
%   A = EULERD(Q, SEQ, 'frame') converts the scalar quaternion Q to a 1-by-3
%   matrix of the equivalent Euler angles (in degrees) corresponding to
%   rotation sequence SEQ. The Euler angles are suitable for a frame
%   rotation.
%
%   A = EULERD(Q, SEQ, 'point') converts the scalar quaternion Q to a 1-by-3
%   matrix of the equivalent Euler angles (in degrees) corresponding to
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

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

a = rad2deg(euler(q,seq,pf));
end
