classdef Introspection < ros.internal.mixin.InternalAccess & handle
% This class is for internal use only. It may be removed in the future.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (Constant, Hidden)
        NODENAMEPREFIX = '/_matlab_introspec_' %Prefix for Node name used for introspection
        AMENTINDEXPREFIX = fullfile('share','ament_index','resource_index','rosidl_interfaces') %default prefix path
        MSGPREFIX = 'share' %install directory prefix
        MSGPOSTFIX = fullfile('msg','*.msg') %install directory postfix
        SRVPOSTFIX = fullfile('srv','*.srv') %install directory postfix
        ACTIONPOSTFIX = fullfile('action','*.action') %install directory postfix
    end

    %% Helpers
    methods (Static)
        %Helper to create the node only once
        %if the domain id is different, a new node is created
        function node = getNode(domainID)
            persistent Node;
            if isempty(domainID)
                domainID = ros.internal.utilities.getDefaultDomainID;
            end
            
            rmwImpl = ros.internal.utilities.getCurrentRMWImplementation;
            if isempty(Node) || ~isValidNode(Node) || ...
              ~isequal(Node.ID, domainID) || ~isequal(Node.RMWImplementation, rmwImpl)
                nodeName = ...
                    sprintf('%s_%d_%s', ...
                            ros.ros2.internal.Introspection.NODENAMEPREFIX, ...
                            domainID, rmwImpl);

                % This persistent Node created with RMW implementation read from 
                % preferences during introspection lists the nodes created
                % on that RMW Implementation.
                Node = ros2node(nodeName, domainID);
            end
            node = Node;
            pause(0.5);
        end

        %Helper to cache the message
        %if the prefix path changes then we rescan the directory
        function msgListMap = getCachedMessageListMap(h, amentPrefixPath)
            persistent AmentPrefixPath;
            persistent MsgListMap;
            if isempty(AmentPrefixPath) || ~isequal(AmentPrefixPath, amentPrefixPath) || isempty(MsgListMap)
                MsgListMap = h.getMessageListMap(amentPrefixPath);
                AmentPrefixPath = amentPrefixPath;
            end
            msgListMap = MsgListMap;
        end

        % Helper to get the list of service types for tab completion
        % To replace with ros2('interface', 'list') with Foxy
        function svcTypes = getAllServiceTypesStatic()
            h = ros.ros2.internal.Introspection;
            svcTypes = h.getAllServiceTypes([], []);
        end

        % Helper to get the list of action types for tab completion
        % To replace with ros2('interface', 'list') with Foxy
        function actionTypes = getAllActionTypesStatic()
            h = ros.ros2.internal.Introspection;
            actionTypes = h.getAllActionTypes([], []);
        end
    end

    %% Methods
    methods
        %Nothing to do for the constructor
        function h = Introspection
        end

        %get the node list
        function result = nodelist(h, cmdoption, domainid)
            result = h.nodelistall(cmdoption, domainid);

            % Filter any hidden nodes (node names start with underscore)
            % Ignore the node namespaces while doing this filtering
            % Pattern: slash-underscore-anything_but_slash-anchored_to_end
            % which ensures it only checks the non-namespace node name
            whichNodes = cellfun(@isempty,regexp(result, '/_[^/]+$', 'once'));
            result = sort(result(whichNodes));
        end

        %get all nodes
        function result = nodelistall(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'node','list'});
            result = reshape(result,[],1);
        end

        %get the topic list
        function result = topiclist(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'topic','list'});
            result = sort(result(:,1));
        end
        
        %get endpoints given a topic
        function result = topicendpoints(~, cmdoption, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'topic','endpoints',cmdoption});
        end

        %get the topic list with types
        function result = topiclisttypes(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'topic','list'});

            % Remove "/msg/" in the middle of the message types listed
            for iTopic = 1:size(result, 1)
                for iType = 1:numel(result{iTopic, 2})

                    lMsgType = result{iTopic, 2}{iType};
                    if contains(lMsgType,'/srv/')
                        lMsgType = strrep(lMsgType, '/srv/', '/');
                        if endsWith(lMsgType,'_Response')
                            lMsgType = strrep(lMsgType, '_Response', 'Response');
                        elseif endsWith(lMsgType,'_Request')
                            lMsgType = strrep(lMsgType, '_Request', 'Request');
                        end
                    elseif contains(lMsgType,'/msg/')
                        lMsgType = strrep(lMsgType, '/msg/', '/');
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
                    end
                    result{iTopic, 2}{iType} = lMsgType;
                end
            end

            [~,ord] = sort(result(:,1));
            result = result(ord,:);
        end

        %get the list of active services
        function result = servicelist(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','list'});
            result = sort(result(:,1));
        end
		
		%get the list of active services with endpoints
        function result = serviceendpoints(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','endpoints'});
        end

        %get the list of active services with types
        function result = servicelisttypes(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','list'});
            % Filter any hidden nodes (node names start with underscore)
            % Ignore the node namespaces while doing this filtering
            % Pattern: slash-underscore-anything_but_slash-anchored_to_end
            % which ensures it only checks the non-namespace node name
            whichNodes = cellfun(@isempty,regexp(result(:,1), '/_[^/]', 'once'));
            result = result(whichNodes,:);

            % Remove "/srv/" in the middle of the service types listed
            for iTopic = 1:size(result, 1)
                for iType = 1:numel(result{iTopic, 2})
                    lSrvType = result{iTopic, 2}{iType};
                    lSrvType = strrep(lSrvType, '/srv/', '/');
                    result{iTopic, 2}{iType} = lSrvType;
                end
            end

            [~,ord] = sort(result(:,1));
            result = result(ord,:);
        end

        %get the type of a specific service
        function result = servicetype(h, serviceName, domainid)
            listTypes = servicelisttypes(h, [], domainid);
            idxService = find(strcmp(serviceName, listTypes(:, 1)), 1);
            if isempty(idxService)
                error(message('ros:mlros2:util:ServiceNameNotFound', serviceName))
            end
            result = listTypes{idxService, 2};
            result = result(:);
        end

        % get type from service name
        function existedType = getTypeFromServiceName(~,~,serviceName,domainid)
            existedType = {};
            intro = ros.ros2.internal.Introspection;
            nametypes = intro.servicelisttypes([],domainid);
            serviceNames = nametypes(:,1);
            serviceTypes = nametypes(:,2);
            whichService = strcmp(serviceName, serviceNames);
            if any(whichService)
                existedType = serviceTypes{whichService};
            end
        end

        % get the list of active actions
        function result = actionlist(~,~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','list'});
            % Extract only action related services (services used by action
            % are all under namespace of /_action)
            whichNodes = cellfun(@(x)~isempty(x), regexp(result(:,1), '/_action/', 'once'));
            result = result(whichNodes,:);
            
            % Retrieve action names and types
            for iTopic = 1:size(result,1)
                lActName = result{iTopic,1};
                lActName = extractBefore(lActName,'/_action/');
                result{iTopic,1} = lActName;
            end

            result = unique(sort(result(:,1)));
        end
		
		%get the endpoints of a specific action
        function result = actionendpoints(~, ~, domainid)
            node = ros.ros2.internal.Introspection.getNode(domainid);
            result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','endpoints'});
            % Extract only action related services (services used by action
            % are all under namespace of /_action)
            
            validIndices = ~cellfun(@isempty, regexp({result.service}, '/_action', 'once'));
            result = result(validIndices);

            % Retrieve action names and types
            for iTopic = 1:length(result)
                lActName = result(iTopic).service;
                lActName = extractBefore(lActName,'/_action/');
                result(iTopic).service = lActName;
            end

            result = struct2table(result);
            result = table2struct(unique(result));
        end
		
        % get type from action name given domainid or internal node
        % varargin can be a ros2node object or a domainid
        function existedType = getTypeFromActionName(~,~,actionName,varargin)

            existedType = {};
            if isa(varargin{1},'ros2node')
                % varargin{1} is a ros2node object
                node = varargin{1};
                % Get all services from introspection
                result = node.InternalNode.introspection(node.ServerNodeHandle,{'service','list'});
                idxGetResult = find(ismember(result(:,1),[actionName '/_action/get_result']), 1);
    
                if ~isempty(idxGetResult)
                    getResultTypeCell = result{idxGetResult,2};
                    getResultType = getResultTypeCell{1};
                    if contains(getResultType,"/action/") && ...
                       contains(getResultType,"_GetResult")
                        % Only return valid output if the following conditions
                        % applies:
                        %   1. action name matches provided input
                        %   2. service type matches action GetResult service
                        getResultType = replace(getResultType,"/action/","/");
                        existedType = replace(getResultType,"_GetResult","");
                    end
                end
            else
                % varargin{1} is a domainid
                domainid = varargin{1};
                intro = ros.ros2.internal.Introspection;
                nametypes = intro.actionlisttypes([],domainid);
                actionNames = nametypes(:,1);
                actionTypes = nametypes(:,2);
                whichAction = strcmp(actionName, actionNames);
                if any(whichAction)
                    existedType = actionTypes{whichAction};
                end
            end
            
        end

        % get the list of active actions with types
        function result = actionlisttypes(~,~,domainid)

            node = ros.ros2.internal.Introspection.getNode(domainid);
            topicResult = node.InternalNode.introspection(node.ServerNodeHandle,{'service','list'});
            
            idxAction = find(contains(topicResult(:,1), '/_action/get_result'));
            
            if ~isempty(idxAction)
                actionCell = topicResult(idxAction,:);
                result(:,1) = cellfun(@(x)strrep(x,'/_action/get_result',''),actionCell(:,1),'UniformOutput',false);
                result(:,2) = cellfun(@(x)strrep(strrep(x,'/action/','/'),'_GetResult',''),actionCell(:,2),'UniformOutput',false);
                % Sort return output and return result
                [~,ord] = sort(result(:,1));
                result = result(ord,:);
            else
                result = cell(0,2);
            end
        end

        %get the type of a specific action
        function result = actiontype(h, actionName, domainid)
            listTypes = actionlisttypes(h, [], domainid);
            idxAction = find(strcmp(actionName, listTypes(:, 1)), 1);
            if isempty(idxAction)
                error(message('ros:mlros2:util:ActionNameNotFound', actionName))
            end
            result = listTypes{idxAction, 2};
            result = result(:);
        end

        %get the message list
        function result = msglist(h, ~, ~)
            amentPrefixPath = ros.ros2.internal.getAmentPrefixPath;
            msgListMap = ros.ros2.internal.Introspection.getCachedMessageListMap(h, amentPrefixPath);
            reg = ros.internal.CustomMessageRegistry.getInstance('ros2');
            result = sort([msgListMap.keys(), reg.getMessageList()]);
            result = reshape(result,[],1);
        end

        %get inbuilt service list in ros2
        function result = supportedServicelist(h, ~, ~)
            amentPrefixPath = ros.ros2.internal.getAmentPrefixPath;
            msgListMap = ros.ros2.internal.Introspection.getCachedMessageListMap(h, amentPrefixPath);
            result = {};
            for iKey =  msgListMap.keys()
                if endsWith(iKey,'Request')
                    iVal = msgListMap(iKey{1});
                    if(endsWith(iVal.srcPath,'.srv'))
                        result{end+1} = iKey{1}(1:end-7); %#ok<AGROW>
                    end
                end
            end
            result = reshape(result,[],1);
        end

        %get all available service types including custom messages
        function result = getAllServiceTypes(h, ~, ~)
            reg = ros.internal.CustomMessageRegistry.getInstance('ros2');
            result = union(supportedServicelist(h), reg.getServiceList());
            result = reshape(result,[],1);
        end

        %get inbuilt action list in ros2
        function result = supportedActionlist(h, ~, ~)
            amentPrefixPath = ros.ros2.internal.getAmentPrefixPath;
            msgListMap = ros.ros2.internal.Introspection.getCachedMessageListMap(h, amentPrefixPath);
            result = {};
            for iKey =  msgListMap.keys()
                if endsWith(iKey,'Goal')
                    iVal = msgListMap(iKey{1});
                    if(endsWith(iVal.srcPath,'.action'))
                        result{end+1} = iKey{1}(1:end-4); %#ok<AGROW>
                    end
                end
            end
            result = reshape(result,[],1);
        end

        %get all available action types including custom messages
        function result = getAllActionTypes(h, ~, ~)
            reg = ros.internal.CustomMessageRegistry.getInstance('ros2');
            result = union(supportedActionlist(h), reg.getActionList());
            result = reshape(result,[],1);
        end

        %create a map of messages to message definition
        function msgListMap = getMessageListMap(h, amentPrefixPath)
            pkgs = dir(fullfile(amentPrefixPath,h.AMENTINDEXPREFIX,'*'));
            pkgs = pkgs(not([pkgs(:).isdir])); %skip directories
            pkgs(ismember({pkgs.name},{'libstatistics_collector','rmw_dds_common'})) = [];
            msgListMap = containers.Map;
            for i = 1:numel(pkgs)
                msgListMap = h.updateMessageMapFor(msgListMap,amentPrefixPath, pkgs(i));
            end
        end

        %for a given package, search and add all the messages
        function msgListMap = updateMessageMapFor(h, msgListMap, amentPrefixPath, pkgDirInfo)
            msgInfos = dir(fullfile(amentPrefixPath, h.MSGPREFIX, pkgDirInfo.name, h.MSGPOSTFIX));
            for i = 1:numel(msgInfos)
                [key, msgEnt] = h.getMessageMapListEntryFor(pkgDirInfo, msgInfos(i));
                msgListMap(key) = msgEnt;
            end

            msgInfos = dir(fullfile(amentPrefixPath, h.MSGPREFIX, pkgDirInfo.name, h.SRVPOSTFIX));
            for i = 1:numel(msgInfos)
                [key, msgEnt] = h.getMessageMapListEntryFor(pkgDirInfo, msgInfos(i));
                msgListMap([key 'Request']) = msgEnt;
                msgListMap([key 'Response']) = msgEnt;
            end

            msgInfos = dir(fullfile(amentPrefixPath, h.MSGPREFIX, pkgDirInfo.name, h.ACTIONPOSTFIX));
            for i = 1:numel(msgInfos)
                [key, msgEnt] = h.getMessageMapListEntryFor(pkgDirInfo, msgInfos(i));
                msgListMap([key 'Goal']) = msgEnt;
                msgListMap([key 'Result']) = msgEnt;
                msgListMap([key 'Feedback']) = msgEnt;
            end
        end

        %create an entry for a given messages
        function [key, msgEnt] = getMessageMapListEntryFor(~, pkgDirInfo, msgFileInfo)
            [~,msgName] = fileparts(msgFileInfo.name);
            key = [pkgDirInfo.name,'/', msgName];
            msgEnt = struct('srcPath',fullfile(msgFileInfo.folder,msgFileInfo.name));
        end

        %check if there is a custom message entry, if not ask cached list
        %of messages. If found, show the message content
        function result = msgshow(h, msgType, ~)
            reg = ros.internal.CustomMessageRegistry.getInstance('ros2');
            ent = reg.getMessageInfo(msgType);
            if isempty(ent)
                amentPrefixPath = ros.ros2.internal.getAmentPrefixPath;
                msgListMap = ros.ros2.internal.Introspection.getCachedMessageListMap(h, amentPrefixPath);
                if ~msgListMap.isKey(msgType)
                    error(message('ros:utilities:message:MessageNotFoundError',msgType,'ros2 msg list'));
                end
                ent = msgListMap(msgType);
            end
            result = h.msgcontent(msgType, ent.srcPath);
        end

        %read the message definition file
        function result = msgcontent(~, msgName, filepath)
            if ~isfile(filepath)
                error(message('ros:mlros2:message:MsgDefinitionMissing',msgName,strrep(filepath,'\','/')));
            end
            result = fileread(filepath);
            result = strtrim(result);

            if endsWith(filepath,'.srv')
                msgDef = strsplit(result,'---');
                [msgDefRequest,msgDefResponse] = msgDef{:};

                if isequal(endsWith(msgName,'Request'),1)
                    result = msgDefRequest;
                elseif isequal(endsWith(msgName,'Response'),1)
                    result = msgDefResponse;
                end
            end

            if endsWith(filepath,'.action')
                msgDef = strsplit(result,'---');
                [msgDefGoal,msgDefResult,msgDefFeedback] = msgDef{:};

                if isequal(endsWith(msgName,'Goal'),1)
                    result = msgDefGoal;
                elseif isequal(endsWith(msgName,'Result'),1)
                    result = msgDefResult;
                elseif isequal(endsWith(msgName,'Feedback'),1)
                    result = msgDefFeedback;
                end
            end

        end

        function result = baginfo(~, uriPath, ~)
            uriPath = convertStringsToChars(uriPath);
            if ~isempty(uriPath) && isequal(uriPath(1),'"') && isequal(uriPath(end),'"')
                uriPath = uriPath(2:end-1);
            end

            [uriPath, storageFormat] = ros2bagreader.getFileURIAndStorageFormat(uriPath);
            if endsWith(uriPath,'/.')
                uriPath = uriPath(1:end-2);
            end
            [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>
            result = rosbag2.bag2.internal.Ros2bagWrapper(uriPath, "info",storageFormat);
        end
    end

end

% LocalWords:  introspec
