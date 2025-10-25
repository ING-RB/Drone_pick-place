classdef NetworkIntrospection < ros.internal.mixin.InternalAccess & handle
%This class is for internal use only. It may be removed in the future.

%NetworkIntrospection Simulink ROS 2 network introspection
%   Gives access to commonly used functions for
%   introspecting into the ROS 2 network.
%   All methods on this object are defined as static.
%
%   Since the ROS 2 network state might be changing continuously, it
%   does not make sense to store any data.

%   Copyright 2019-2023 The MathWorks, Inc.

% Simulink-focused functionality
    methods (Static, Hidden)
        function ret = getDomainIDForSimulink()
        %getDomainIDForSimulink Return the Simulink ROS 2 domain
        %   Saved within the network address profile, which is set from
        %   network address specifier dialog
            netAddrStore = ros.slros.internal.sim.NetworkAddrStore;
            netAddrProf = netAddrStore.getProfile;
            if isempty(netAddrProf.DomainID)
                ret = netAddrProf.getDefaultDomainID;
            else
                ret = netAddrProf.DomainID;
            end
        end

        function ret = getRMWImplementationForSimulink()
        %getRMWImplementationForSimulink Return the Simulink ROS Middleware
        %   Implementation (ROS 2) saved within the network address profile,
        %   which is set in the preferences
            netAddrStore = ros.slros.internal.sim.NetworkAddrStore;
            netAddrProf = netAddrStore.getProfile;
            ret = netAddrProf.getCurrentRMWImplementation;
        end

        function ret = getNodeNames()
        %getNodeNames Returns the names of all nodes
        %   Data is returned as cell array of strings. Note that the nodes
        %   need to have active publishers and subscribers to be included
        %   in this list.
        %
        %   NODENAMES = ros.internal.ROSNetworkIntrospection.getNodeNames;
        %   returns a cell array of strings and each string represents one
        %   node name.
            h = ros.ros2.internal.Introspection;
            ret = h.nodelist([], ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink);
        end

        function [topicNames, topicMsgType] = getTopicNamesTypes()
        %getTopicNamesTypes Get topic names and messages for ROS2 topics
        %   This method is used by the message selector dialog of Simulink
        %   ROS2 blocks (ros2lib)
            h = ros.ros2.internal.Introspection;
            ret = h.topiclisttypes([], ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink);
            topicNames = ret(:,1);
            topicMsgType = cellfun(@(x)x{1}, ret(:,2), 'UniformOutput', false);
        end

        function [svcNames, svcTypes] = getServiceNamesTypes()
        %getServiceNamesTypes Get service names and types for ROS2 services
        %   This method is used by the service selector dialog of Simulink
        %   ROS2 blocks (ros2lib)
            h = ros.ros2.internal.Introspection;
            ret = h.servicelisttypes([], ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink);
            svcNames = ret(:,1);
            svcTypes = cellfun(@(x)x{1}, ret(:,2), 'UniformOutput', false);
        end

        function existedType = getTypeFromActionName(actionName, domainid)
        %getTypeFromActionName Get existed action type from given name
        %   This method is used by ros2actionclient to handle action name
        %   and type conflicts with existed action in network.
            h = ros.ros2.internal.Introspection;
            % Add '/' to actionName if it does not start with
            if ~startsWith(actionName,'/')
                actionName = ['/' actionName];
            end
            existedType = h.getTypeFromActionName([], actionName, domainid);
        end

        function [actNames, actTypes] = getActionNamesTypes()
        %getActionNamesTypes Get action names and types for ROS2 actions
        %   This methods is used by the action selector dialog of Simulink
        %   ROS2 blocks (ros2lib)
            h = ros.ros2.internal.Introspection;
            ret = h.actionlisttypes([], ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink);
            actNames = ret(:,1);
            actTypes = cellfun(@(x)x{1}, ret(:,2), 'UniformOutput', false);
        end
    end

    % MATLAB-focused functionality
    methods (Static, Hidden)
        function [topics, types] = getTopicsTypesWithNode(node)
        %getTopicsTypesWithNode Get topic names and types using ROS 2 node
        %   TOPICS is a cell array specifying topics on the node's network.
        %   TYPES is a cell array of cell arrays containing the
        %   corresponding types for each topic. Each topic may have
        %   more than one message type (bug in ROS 2).

            allTopicsAndTypes = ...
                introspection(node.InternalNode, ...
                              node.ServerNodeHandle, ...
                              {'topic', 'list'});

            % Remove "/msg/" in the middle of the message types listed
            % This is a temporary shim, and will be removed in the future
            rmwImpl = ros.internal.utilities.getCurrentRMWImplementation;
            for iTopic = 1:size(allTopicsAndTypes, 1)
                for iType = 1:size(allTopicsAndTypes{iTopic, 2}, 1)
                    lMsgType = allTopicsAndTypes{iTopic, 2}{iType};
                    % In case of rmw_ecal_proto_cpp, the message type is
                    % prepended by the "proto:", this string needs to be
                    % removed.
                    if isequal(rmwImpl, 'rmw_ecal_proto_cpp') && string(lMsgType).startsWith('proto:')
                        firstColonIndex = strfind(lMsgType,':');
                        lMsgType = lMsgType(firstColonIndex+1:end);
                    end
                    if contains(lMsgType,'/srv/')
                        lMsgType = strrep(lMsgType, '/srv/', '/');
                        if endsWith(lMsgType,'_Response')
                            lMsgType = strrep(lMsgType, '_Response', 'Response');
                        elseif endsWith(lMsgType,'_Request')
                            lMsgType = strrep(lMsgType, '_Request', 'Request');
                        end
                    elseif contains(lMsgType,'/action/')
                        lMsgType = strrep(lMsgType, '/action/', '/');
                        % Action messages ends with _GoalMessage,
                        % _ResultMessage, and _FeedbackMessage, whereas
                        % general message from ros2message ends with _Goal,
                        % _Result, and _Feedback.
                        if endsWith(lMsgType,'_GoalMessage')
                            lMsgType = strrep(lMsgType, '_GoalMessage', 'Goal');
                        elseif endsWith(lMsgType,'_ResultMessage')
                            lMsgType = strrep(lMsgType, '_ResultMessage', 'Result');
                        elseif endsWith(lMsgType,'_FeedbackMessage')
                            lMsgType = strrep(lMsgType, '_FeedbackMessage', 'Feedback');
                        elseif endsWith(lMsgType,'_Goal')
                            lMsgType = strrep(lMsgType, '_Goal', 'Goal');
                        elseif endsWith(lMsgType,'_Result')
                            lMsgType = strrep(lMsgType, '_Result', 'Result');
                        elseif endsWith(lMsgType,'_Feedback')
                            lMsgType = strrep(lMsgType, '_Feedback', 'Feedback');
                        end
                    elseif contains(lMsgType,'/msg/')
                        lMsgType = strrep(lMsgType, '/msg/', '/');
                    end
                    allTopicsAndTypes{iTopic, 2}{iType} = lMsgType;
                end
            end

            topics = allTopicsAndTypes(:, 1);
            types = allTopicsAndTypes(:, 2);
        end

        function type = getTypeFromTopicWithNode(node, topic)
        %getTypeFromTopicWithNode Get type for topic using ROS 2 node
        %   TYPE is a cell array containing the message type(s) used on
        %   the specified TOPIC. There may be more than one message type
        %   per topic (bug in ROS 2).

            type = {};
            [topics, types] = ...
                ros.ros2.internal.NetworkIntrospection.getTopicsTypesWithNode(node);
            whichTopic = strcmp(topic, topics);
            if any(whichTopic)
                % In the unlikely event of multiple matching topics on the
                % list, this syntax will use the first
                type = types{whichTopic};
            end
        end

        function [svcNames, svcTypes] = getServiceTypesWithNode(node)
        %getServiceTypesWithNode Get Service names and types using ROS2 node
        %   SVCNAMES is a cell array specifying services on the node's
        %   network. SVCTYPES is a cell array of cell arrays containing the
        %   corresponding types for each service.

            allServices = ...
                introspection(node.InternalNode, ...
                              node.ServerNodeHandle, ...
                              {'service','list'});
            svcNames = allServices(:,1);
            svcTypes = allServices(:,2);
        end

        function type = getTypeFromServiceName(serviceName, domainid)
        %getTypeFromServiceName Get existed service type from given name
        %   This method is used by ROS 2 service server and client to
        %   handle service name and type conflicts with existed service in
        %   network.

            h = ros.ros2.internal.Introspection;
            % Add '/' to serviceName if it does not start with
            if ~startsWith(serviceName, '/')
                serviceName = ['/' serviceName];
            end
            type = h.getTypeFromServiceName([], serviceName, domainid);
        end
    end
end
