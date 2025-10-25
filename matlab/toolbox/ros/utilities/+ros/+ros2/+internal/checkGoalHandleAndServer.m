function [goalHandle, status, errorCode] = checkGoalHandleAndServer(goalUUIDInUint8)
    %This class is for internal use only. It may be removed in the future.

    %CHECKIFGOALHANDLEANDSERVER- Checks whether a goal handle and server are available
    %using the action client

    %   Copyright 2023-2024 The MathWorks, Inc.

    goalHandle = [];
    % Convert the UUID from uint8 (16x1) array available in
    % unique_identifier_msgs/UUID bus input to char vector.
    % It is not required to convert input bus to message here,
    % as uuid is available directly from bus structure.
    
    % Convert each byte to a two-character hexadecimal string
    hexValues = cellfun(@(x) lower(dec2hex(x, 2)), num2cell(goalUUIDInUint8), 'UniformOutput', false);

    % Concatenate all hexadecimal strings
    goalUUID = [hexValues{:}];

    % Insert dashes to format as RFC-4122 compliant UUID
    % A RFC-4122 compliant UUID looks like:
    % 00000000-0000-0000-0000-000000000000
    % That means that there is a '-' at offset 8, 13, 18, and 23
    if numel(goalUUID) == 32
        formattedUUID = [goalUUID(1:8) '-' goalUUID(9:12) '-' goalUUID(13:16) '-' goalUUID(17:20) '-' goalUUID(21:32)];
    else
        formattedUUID = goalUUID;
    end
    status = true;
    errorCode = uint8(0);

    % Fetch the goal handle from the map. The goal handle was stored in the map when
    % sending a goal for the UUID.
    goalUUIDAndHandleMap = ros.ros2.internal.getGoalUUIDAndHandleMap;
    if isKey(goalUUIDAndHandleMap, formattedUUID)
        goalHandle = goalUUIDAndHandleMap(formattedUUID);
    end

    %If there is no UUID does not exist in the map, goal handle is empty
    if isempty(goalHandle)
        % Show error code 2 for empty goal handle
        % Feedback and result outputs will be default messages
        errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalInvalidUUID);
        status = false;
        return
    end

    if ~goalHandle.ActionClientHandle.get.IsServerConnected
        % Show error code 3 when server becomes unavailable
        % after sending a goal. Here, Feedback and result outputs will be default messages
        errorCode = uint8(ros.slros.internal.block.MonitorGoalErrorCode.SLMonitorGoalServerUnavailable);
        status = false;
        return
    end
end
