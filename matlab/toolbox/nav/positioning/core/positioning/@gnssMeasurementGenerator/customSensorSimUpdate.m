function newPoses = customSensorSimUpdate(obj, varargin)
%CUSTOMSENSORSIMUPDATE SSF update method for gnssMeasurementGenerator 
%   object
%
%   This method is for internal use only. It may be removed in the future.

%   Copyright 2022 The MathWorks, Inc.

refloc = obj.ReferenceLocation;
satIDs = obj.SensorActorIDs;

% Get current satellite positions.
gpsSatPos = obj.SatellitePosition;
gpsSatPosENU = fusion.internal.frames.ecef2enu(gpsSatPos, refloc);

% Convert satellite positions into format accepted by internal SSF.
numSats = numel(satIDs);
pose(numSats,:) = struct("Position", [0 0 0], "Orientation", [0 0 0]);
for ii = 1:numSats
    pose(ii).Position = gpsSatPosENU(ii,:);
    pose(ii).Orientation = [0 0 0];
end
newPoses(numSats,:) = matlabshared.scenario.internal.utils.initializeActorPoseStruct();
eulAngs = [0 0 0];
for ii = 1:numel(pose)
    newPoses(ii).ActorID = uint64([satIDs(ii)]); 
    newPoses(ii).Position = gpsSatPosENU(ii,:);
    newPoses(ii,:).Orientation = eulAngs;
end
end