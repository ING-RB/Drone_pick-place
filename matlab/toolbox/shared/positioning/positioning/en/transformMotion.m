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

