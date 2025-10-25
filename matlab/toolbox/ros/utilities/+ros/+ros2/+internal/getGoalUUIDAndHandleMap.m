function goalUUIDHandleMap = getGoalUUIDAndHandleMap
    %This class is for internal use only. It may be removed in the future.

    %GETGOALUUIDANDHANDLEMAP - Retrieves the map that stores the goal uuid
    %character vector as a key and its corresponding goal handle as a value

    %   Copyright 2023 The MathWorks, Inc.

    persistent goalUUIDMap;
    if isempty(goalUUIDMap)
        goalUUIDMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    goalUUIDHandleMap = goalUUIDMap;
end