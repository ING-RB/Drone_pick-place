classdef ParameterNodeManager < handle
%This class is for internal use only. It may be removed in the future.

%ParameterNodeManager Manage nodes for all ros2param objects
%   Service clients in ros2param need to be attached to a ROS 2 node.
%   Since multiple ros2param objects can share the same ROS 2 node, it
%   is more effective to always refer to the same node if certain node
%   has been created with the same domain ID.
%   ParameterNodeManager ensures there is no redundant node while
%   handling parameters and it shall clear all nodes when there is no
%   more ros2param object.

%   Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        %NodeName         - Node name of ros2node created by ParameterNodeManager
        NodeName = '/_matlab_ros2param_manager_node_'
    end

    properties (SetAccess = private)
        %Count            - Track amount of ros2param objects in workspace
        Count
        %ParameterNodeMap - Map that stores all nodes in different domain
        ParameterNodeMap
    end

    methods
        function obj = ParameterNodeManager()
        %ParameterNodeManager constructor of ParameterNodeManager

        % Initialize Count to zero. This will be called only once even
        % there are multiple ros2param objects.
            obj.Count = 0;
        end

        function addNewParamObj(obj,domainID)
        %addNewParamObj update properties when introducing new ros2param objects

            narginchk(2,2);
            validateattributes(domainID,{'numeric'},{'scalar', 'integer', 'nonnegative', '<=', 232},...
                               'addNewParamObj','domainID');
            % Increase the amount of ros2param objects by 1
            obj.Count = obj.Count + 1;

            if isempty(obj.ParameterNodeMap)
                % Filling the first key-value in the ParameterNodeMap
                obj.ParameterNodeMap = containers.Map(domainID, ros2node([obj.NodeName num2str(domainID)],domainID));
            elseif ~isKey(obj.ParameterNodeMap, domainID)
                % If we cannot find an existed ros2node in the specified
                % domain, create a new one.
                obj.ParameterNodeMap(domainID) = ros2node([obj.NodeName num2str(domainID)],domainID);
            end
        end

        function removeParamObj(obj)

        % Decrease the amount of ros2param objects by 1
            obj.Count = obj.Count - 1;

            % Clear ParameterNodeMap if there is no more ros2param object.
            if obj.Count == 0
                obj.ParameterNodeMap = [];
            end
        end

        function node = getNodeByDomainID(obj,domainID)
        %getNodeByDomainID return node from ParameterNodeMap given domainID

            narginchk(2,2);
            validateattributes(domainID,{'numeric'},{'scalar', 'integer', 'nonnegative', '<=', 232},...
                               'getNodeByDomainID','domainID');

            % Only return node if there is one in the specified domain
            if ~isempty(obj.ParameterNodeMap) && isKey(obj.ParameterNodeMap, domainID)
                node = obj.ParameterNodeMap(domainID);
            else
                error(message('ros:mlros2:parameter:NodeDoesNotExist',[obj.NodeName num2str(domainID)],domainID));
            end
        end
    end
end
