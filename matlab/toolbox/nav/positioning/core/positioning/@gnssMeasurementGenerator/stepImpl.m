function [p, satPos, status] = stepImpl(obj)
%STEPIMPL Step method for gnssMeasurementGenerator object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Check that scenario has been initialized and that host actor has been
% added to SSF.
isSceneInitialized = ~isempty(obj.SensorSim);
if isSceneInitialized
    ssfPoses = actorPoses(obj.SensorSim);
    isSceneInitialized = false;
    hostID = obj.pHostID;
    for ii = 1:numel(ssfPoses)
        if (hostID == ssfPoses(ii).actor_id.value)
            isSceneInitialized = true;
            hostPos = ssfPoses(ii).position;
            recPosENU = [hostPos.x, hostPos.y, hostPos.z];
        end
    end
end
coder.internal.errorIf(~isSceneInitialized, ...
    "nav_positioning:gnssMeasurementGenerator:EmptyScenario", ...
    "gnssMeasurementGenerator");

% Get ranges from satellites to receiver. 
satPaths = getPaths(obj.SensorSim.getSSF, getSensorIndex(obj));
numPaths = numel(satPaths);
satRanges = zeros(numPaths,1);
for ii = 1:numPaths
    satRanges(ii) = matlabshared.scenario.internal.SSF.getPathLength(satPaths(ii));
end

% Get satellite ID of each range. Determine if a range has multipath.
currSatIDs = zeros(numPaths, 1);
hasMultipath = false(numPaths, 1);
raySatPos = zeros(numPaths, 3);
for idx = 1:numPaths
    path = satPaths(idx);
    interactions = path.interactions;
    numIsects = numel(interactions);
    for isectIdx = 1:numIsects
        intersection = interactions(isectIdx).intersection;
        if (isectIdx == numIsects)
            % Tie pseudoranges to satellites. Last intersection should
            % be satellite.
            currSatIDs(idx) = intersection.target_id.value;
            raySatPos(idx,:) = [intersection.position.x, intersection.position.y, intersection.position.z];
        end
    end
    hasMultipath(idx) = (numIsects > 1);
end

% Match current ranges with the satellites based on the intersection IDs.
gpsSatPos = obj.SatellitePosition;
satIDs = obj.SensorActorIDs;
currSatPos = zeros(numel(satRanges), 3);
for ii = 1:size(gpsSatPos,1)
    satToPseudorangeIdx = currSatIDs == satIDs(ii);

    currSatPos(currSatIDs == satIDs(ii),:) = repmat(gpsSatPos(ii,:), nnz(satToPseudorangeIdx), 1);
end

% Extend range from ray intersection to central satellite position.
currSatPosENU = fusion.internal.frames.ecef2enu(currSatPos, obj.ReferenceLocation);
rayToSatDist = vecnorm(currSatPosENU - raySatPos, 2, 2);
satRanges = satRanges + rayToSatDist;

% Remove measurements that are below the mask angle. 
recPos = fusion.internal.frames.enu2lla(recPosENU, obj.ReferenceLocation);
[~, ~, vis] = lookangles(recPos, currSatPos, obj.MaskAngle);
p = satRanges(vis);
satPos = currSatPos(vis,:);
status = struct("LOS", ~hasMultipath(vis));

% Advance current time and satellite positions.
currTime = obj.pCurrTime;
dt = 1 ./ obj.SampleRate;
currTime = currTime + dt;
t = obj.InitialTime + seconds(obj.pCurrTime - obj.pTimeOfWeek);
obj.SatellitePosition = gnssconstellation(t);
obj.pCurrTime = currTime;
end
