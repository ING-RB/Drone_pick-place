function actorProfiles = customSensorSimInit(obj, varargin)
%CUSTOMSENSORSIMINIT SSF initialization method for gnssMeasurementGenerator 
%   object
%
%   This method is for internal use only. It may be removed in the future.

%   Copyright 2022 The MathWorks, Inc.

% Compute and store satellite positions. 
t = obj.InitialTime;
gpsSatPos = gnssconstellation(t);
obj.SatellitePosition = gpsSatPos;
numSats = size(gpsSatPos, 1);

% Convert positions to local coordinate frame.
refloc = obj.ReferenceLocation;
gpsSatPosENU = fusion.internal.frames.ecef2enu(gpsSatPos, refloc);

% Specify satellite profiles for SSF.
satsize = gnssMeasurementGenerator.SatelliteSize;
[cubeVertices, cubeFaces] = cube(satsize);
actorProfiles(1, numSats) = mw.scenario.proto.ActorProfile;
noClassID = 0; % Set to zero since satellites do not have a specific class.
for ii=1:numSats
    % Class ID.
    actorProfiles(ii).class_id ...
        = matlabshared.scenario.internal.utils.getProto(noClassID, 'class_id');

    % Position.
    actorProfiles(ii).position ...
        = matlabshared.scenario.internal.utils.getProto( ...
        gpsSatPosENU(ii,:), 'position');

    % Orientation.
    actorProfiles(ii).orientation ...
        = matlabshared.scenario.internal.utils.getProto( ...
        [0, 0, 0], 'orientation');

    % Satellite dimensions.
    actorProfiles(ii).bounding_box_dim ...
        = matlabshared.scenario.internal.utils.getProto( ...
        [satsize, satsize, satsize], 'bounding_box_dim');

    % Satellite mesh.
    mesh.vertices = cubeVertices;
    mesh.triangles = cubeFaces;
    actorProfiles(ii).mesh_model ...
        = matlabshared.scenario.internal.utils.getProto( ...
        mesh, 'mesh_model');
end
end

function [cubeVertices, cubeFaces] = cube(satsize)
cubeVertices = 0.5 * satsize * [-1 -1 -1;
    -1 -1  1;
    -1  1 -1;
    -1  1  1;
    1 -1 -1;
    1 -1  1;
    1  1 -1;
    1  1  1];
cubeFaces = [1 2 3;
    2 3 4;
    1 2 5;
    2 5 6;
    1 5 7;
    1 3 7;
    5 6 7;
    6 7 8;
    3 4 7;
    4 7 8;
    2 4 6;
    4 6 8];
end
