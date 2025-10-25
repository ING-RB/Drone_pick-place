function [posS, orientS, velS, accS, angvelS] = transformMotion( ...
    posSFromP, orientSFromP, posP, orientP, velP, accP, angvelP)
%TRANSFORMMOTION Convert motion quantities between two frames
%   [posS,orientS,velS,accS,angvelS] = TRANSFORMMOTION(posSFromP,
%   orientSFromP, posP) converts the motion quantity in the Platform-frame,
%   posP, to the motion quantities in the Sensor-frame, posS, orientS,
%   velS, accS, and angvelS, using the translation offset, posSFromP, and
%   rotation offset, orientSFromP.
%
%   [posS,orientS,velS,accS,angvelS] = TRANSFORMMOTION(posSFromP,
%   orientSFromP, posP, orientP) converts the motion quantities in the
%   Platform-frame, posP and orientP, to the motion quantities in the
%   Sensor-frame, posS, orientS, velS, accS, and angvelS, using the
%   translation offset, posSFromP, and rotation offset, orientSFromP.
%
%   [posS,orientS, velS,accS,angvelS] = TRANSFORMMOTION(posSFromP,
%   orientSFromP, posP, orientP, velP) converts the motion quantities in
%   the Platform-frame, posP, orientP, and velP, to the motion quantities
%   in the Sensor-frame, posS, orientS, velS, accS, and angvelS, using the
%   translation offset, posSFromP, and rotation offset, orientSFromP.
%
%   [posS,orientS,velS,accS,angvelS] = TRANSFORMMOTION(posSFromP,
%   orientSFromP, posP, orientP, velP, accP) converts the motion quantities
%   in the Platform-frame, posP, orientP, velP, and accP, to the motion
%   quantities in the Sensor-frame, posS, orientS, velS, accS, and angvelS,
%   using the translation offset, posSFromP, and rotation offset,
%   orientSFromP.
%
%   [posS,orientS,velS,accS,angvelS] = TRANSFORMMOTION(posSFromP,
%   orientSFromP, posP, orientP, velP, accP, angvelP) converts the motion
%   quantities in the Platform-frame, posP, orientP, velP, accP, and
%   angvelP, to the motion quantities in the Sensor-frame, posS, orientS,
%   velS, accS, and angvelS, using the translation offset between frames,
%   posSFromP, and rotation offset between frames, orientSFromP.
%
%   Example:
%
%       % Define platform pose.
%       posPlat = [20 -1 0];
%       orientPlat = quaternion(1, 0, 0, 0);
%       velPlat = [0 0 0];
%       accPlat = [0 0 0];
%       angvelPlat = [0 0 1];
% 
%       % Define offset of IMU from platform.
%       posPlat2IMU = [1 2 3];
%       orientPlat2IMU = quaternion([45 0 0], 'eulerd', 'ZYX', 'frame');
% 
%       % Calculate IMU pose.
%       [posIMU, orientIMU, velIMU, accIMU, angvelIMU] ...
%           = transformMotion(posPlat2IMU, orientPlat2IMU, ...
%           posPlat, orientPlat, velPlat, accPlat, angvelPlat);
% 
%       fprintf('IMU position is: %.2f %.2f %.2f\n', posIMU);
%
%   See also IMUSENSOR, GPSSENSOR, WAYPOINTTRAJECTORY

%   Copyright 2019 The MathWorks, Inc.

%#codegen

validateattributes(posSFromP, {'double', 'single'}, {'row', 'numel', 3, 'real', 'finite'}, '', 'posSFromP', 1);
isQuat = isa(orientSFromP, 'quaternion');
if isQuat
    validateattributes(orientSFromP, {'quaternion'}, {'scalar', 'finite'}, '', 'orientSFromP', 2);
    orientSFromPQuat = orientSFromP;
else
    validateattributes(orientSFromP, {'double', 'single'}, {'square', '2d', 'ncols', 3, 'real', 'finite'}, '', 'orientSFromP', 2);
    orientSFromPQuat = quaternion(orientSFromP, 'rotmat', 'frame');
end

if nargin < 7
    angvelP = zeros(1, 3, 'like', posSFromP);
end
if nargin < 6
    accP = zeros(1, 3, 'like', posSFromP);
end
if nargin < 5
    velP = zeros(1, 3, 'like', posSFromP);
end
if nargin < 4
    orientP = quaternion.ones(1, 1, 'like', posSFromP);
end
if nargin < 3
    posP = zeros(1, 3, 'like', posSFromP);
end

validateattributes(posP, {'double', 'single'}, {'ncols', 3, '2d', 'real', 'finite'}, '', 'posP', 3);
N = size(posP, 1);
allOneRowInputs = (N == 1);
isOrientPQuat = isa(orientP, 'quaternion');
if isOrientPQuat
    validateattributes(orientP, {'quaternion'}, {'column', 'finite'}, '', 'orientP', 4)
    sz = size(orientP, 1);
    coder.internal.errorIf(~allOneRowInputs && ((sz ~= 1) && (sz ~= N)), 'shared_positioning:transformMotion:sizesMustMatch');
    N = max(N, sz);
    allOneRowInputs = (N == 1);
    orientPQuat = orientP;
else
    validateattributes(orientP, {'double', 'single'}, {'nrows', 3, 'ncols', 3, '3d', 'real', 'finite'}, '', 'orientP', 4);
    sz = size(orientP, 3);
    coder.internal.errorIf(~allOneRowInputs && ((sz ~= 1) && (sz ~= N)), 'shared_positioning:transformMotion:sizesMustMatch');
    N = max(N, sz);
    allOneRowInputs = (N == 1);
    orientPQuat = quaternion(orientP, 'rotmat', 'frame');
end
validateattributes(velP, {'double', 'single'}, {'ncols', 3, '2d', 'real', 'finite'}, '', 'velP', 5);
sz = size(velP, 1);
coder.internal.errorIf(~allOneRowInputs && ((sz ~= 1) && (sz ~= N)), 'shared_positioning:transformMotion:sizesMustMatch');
N = max(N, sz);
allOneRowInputs = (N == 1);
validateattributes(accP, {'double', 'single'}, {'ncols', 3, '2d', 'real', 'finite'}, '', 'accP', 6);
sz = size(accP, 1);
coder.internal.errorIf(~allOneRowInputs && ((sz ~= 1) && (sz ~= N)), 'shared_positioning:transformMotion:sizesMustMatch');
N = max(N, sz);
allOneRowInputs = (N == 1);
validateattributes(angvelP, {'double', 'single'}, {'ncols', 3, '2d', 'real', 'finite'}, '', 'angvelP', 7);
sz = size(angvelP, 1);
coder.internal.errorIf(~allOneRowInputs && ((sz ~= 1) && (sz ~= N)), 'shared_positioning:transformMotion:sizesMustMatch');
N = max(N, sz);

[posSFromP, orientSFromPQuat, posP, orientPQuat, ...
    velP, accP, angvelP] = resizeInputs(N, posSFromP, orientSFromPQuat, ...
    posP, orientPQuat, velP, accP, angvelP);

posS = posP ...
    + rotatepoint(orientPQuat, posSFromP);

orientSQuat = orientPQuat .* orientSFromPQuat;
if isOrientPQuat
    orientS = orientSQuat;
else
    orientS = rotmat(orientSQuat, 'frame');
end

velS = velP ...
    + rotatepoint(orientPQuat, crossProduct(angvelP, posSFromP));

accS = accP ...
    + rotatepoint(orientPQuat, crossProduct(angvelP, crossProduct(angvelP, posSFromP)));

angvelS = angvelP;
end

function C = crossProduct(Ain, Bin)
%CROSSPRODUCT Cross product with limited implicit expansion
%   Ain - 1-by-3 or N-by-3 matrix
%   Bin - 1-by-3 or N-by-3 matrix
%
%   C - cross product of A and B, that are the expanded versions of Ain and
%       Bin, respectively.
numA = size(Ain, 1);
numB = size(Bin, 1);
N = max(numA, numB);
expandMat = ones(N, 3);
A = bsxfun(@times, Ain, expandMat);
B = bsxfun(@times, Bin, expandMat);

C = cross(A, B);
end

function [posSFromP, orientSFromPQuat, posP, orientPQuat, ...
    velP, accP, angvelP] = resizeInputs(N, posSFromP, orientSFromPQuat, ...
    posP, orientPQuat, velP, accP, angvelP)

resize = @(x) repmat(x, N-(size(x,1)-1), 1);

posSFromP = resize(posSFromP);
orientSFromPQuat = quaternion(resize(compact(orientSFromPQuat)));
posP = resize(posP);
orientPQuat = quaternion(resize(compact(orientPQuat)));
velP = resize(velP);
accP = resize(accP);
angvelP = resize(angvelP);
end
