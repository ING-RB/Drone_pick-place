function sensorConfig = config(obj, hostID, mountingPosition, varargin)
%CONFIG Config method for gnssMeasurementGenerator object
%
%   This method is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

if (nargin < 3)
    mountingPosition = [0 0 0];
end
if (nargin < 2)
    hostID = 1;
end

% Cache host ID. This is used in the step method to verify that the scene
% has been initialized.
obj.pHostID = uint64(hostID);

sensorConfig = mw.scenario.proto.SensorConfiguration;

% Set host ID and mounting position.
sensorConfig.host_id = matlabshared.scenario.internal.utils.getProto( ...
    hostID, 'host_id');
sensorConfig.mounting_position ...
    = matlabshared.scenario.internal.utils.getProto( ...
    mountingPosition, 'mounting_position');

% Only target satellites with rays. 
targets = mw.scenario.proto.Uint64List;
targets.values = uint64(obj.SensorActorIDs);
sensorConfig.target_actor_ids = targets;

% Avoid collisions with host actor. 
sensorConfig.ignore_actor_occlusions = ...
    matlabshared.scenario.internal.utils.getProto( ...
    hostID, 'target_actor_ids');

% Use multipath.
mps = mw.scenario.proto.MultiPathSettings;
mps.max_num_reflections = 3;
% Includes LOS and reflected rays from same satellites.
mps.include_all_paths = true;
sensorConfig.multi_path_settings = mps;
sensorConfig.angular_separation = deg2rad(1);
end
