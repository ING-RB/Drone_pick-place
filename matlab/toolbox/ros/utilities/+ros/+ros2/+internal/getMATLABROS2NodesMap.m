function matlabNodesDict = getMATLABROS2NodesMap(action, key, value)
    %This class is for internal use only. It may be removed in the future.

    %getMATLABROS2NodesMap - Retrieves the dictionary that stores the ros2node
    % name in the form of name_domainID_rmwImplementation as a key and its
    % corresponding node name as a value

    %   Copyright 2024 The MathWorks, Inc.

    persistent ros2NodesDict;
    if isempty(ros2NodesDict)
        ros2NodesDict = dictionary;
    end

    % Check if there is an action to perform
    if nargin > 0
        switch action
            case 'add'
                % Add or update the key-value pair
                if ~isConfigured(ros2NodesDict) || ~isKey(ros2NodesDict,key)
                    ros2NodesDict(key) = value;
                end
            case 'remove'
                % Remove the key-value pair
                if isConfigured(ros2NodesDict)
                    ros2NodesDict(key) = [];
                end
        end
    end

    % Return the current state of the dictionary
    matlabNodesDict = ros2NodesDict;
end