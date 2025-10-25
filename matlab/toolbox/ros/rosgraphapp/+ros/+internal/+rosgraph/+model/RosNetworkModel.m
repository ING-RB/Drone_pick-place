classdef RosNetworkModel < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.
    
    properties 
        DomainId
        
        Nodes
        % NodeEndPoints stores the connections of a node with topics,
        % services and actions.
        NodeEndPoints

        Topics
        TopicEndPoints

        Services
        ServiceEndPoints
        % ServiceEndPointMap stores service end points as map
        ServiceEndPointMap

        Actions
        ActionEndPoints
        % ActionEndPointMap stores action end points as map
        ActionEndPointMap

        QueriedNodes
        QueriedTopics
        QueriedServices
        QueriedActions
        
        % Negative Filters stores the negative filters
        NegativeFilters

        % Positive Filters stores the negative filters
        PositiveFilters

        NetworkDetails = struct
        
        % TypeToTopics stores topics with their type as key of map
        TypeToTopics

        % TypeToServices stores services with their type as key of map
        TypeToServices

        % TypeToActions stores action with their type as key of map
        TypeToActions

        % TopicsToType maps topics to their types.
        TopicsToType

        % ServicesToType maps services to their types.
        ServicesToType

        % ActionsToType maps actions to their types.
        ActionsToType
        
        % QueriedTopicsByType stores topics filtered by their types
        QueriedTopicsByType

        % QueriedServicesByType stores services filtered by their types
        QueriedServicesByType

        % QueriedActionsByType stores actions filtered by their types
        QueriedActionsByType
        
        % QueriedDepth stores depth of the graph for filtering
        QueriedDepth = 1
        
        % MLGraph stores ROS 2 Network as graph
        MLGraph
        
        % GraphUpdated informs if we have freshly updated graph details
        GraphUpdated = false
        
        % ValidEntities stores all the valid entities required to be shown to the users 
        ValidEntities

        % ros2ParamObjMapForNodeName - Map that stores all ros2param
        % objects for different node names
        ros2ParamObjMapForNodeName
        
        % PreviousAdvancedQuery stores the previous applied query
        PreviousAdvancedQuery

        NodesId = 'Nodes'

        TopicsId = 'Topics'

        ServicesId = 'Services'

        ActionsId = 'Actions'

        DataTypesId = 'DataTypes'

        DefaultTopicsKeywords = {'/parameter_events', '/rosout'};

        DefaultServicesKeywords = {'/describe_parameters', '/get_parameter_types', '/get_parameters', ...
                   '/list_parameters', '/set_parameters', '/set_parameters_atomically', ...
                   '/get_type_description'};

        DefaultActionsKeywords = {'/_action/'}
        
    end

    methods
        
        function updateDomainId(obj,domainId)
            obj.DomainId = domainId;
            obj.ros2ParamObjMapForNodeName = containers.Map;
            fetchLatestNetworkInfo(obj)
        end

        function fetchLatestNetworkInfo(obj)

            obj.Nodes = struct('name', []);
            obj.Topics = struct('name', []);
            obj.Services = struct('name', []);
            obj.Actions = struct('name', []);
            obj.QueriedNodes = struct('name', []);
            obj.QueriedTopics = struct('name', []);
            obj.QueriedServices = struct('name', []);
            obj.QueriedActions = struct('name', []);

            obj.QueriedTopicsByType = struct('name', []);
            obj.QueriedServicesByType = struct('name', []);
            obj.QueriedActionsByType = struct('name', []);

            obj.Nodes.name = unique(ros2('node','list', 'DomainID', obj.DomainId));
            obj.Topics.name = unique(ros2('topic','list', 'DomainID', obj.DomainId));
            tservices = ros2('service', 'list', 'DomainID', obj.DomainId);
            obj.Services.name = tservices(:, 1);
            obj.Actions.name = ros2('action', 'list', 'DomainID', obj.DomainId);

            obj.Nodes.name = obj.Nodes.name(~contains(obj.Nodes.name, '_matlab_introspec'));
            obj.Topics.name = obj.Topics.name(~contains(obj.Topics.name, '_matlab_introspec'));
            obj.Services.name = obj.Services.name(~contains(obj.Services.name, '_matlab_introspec'));
            obj.Actions.name = obj.Actions.name(~contains(obj.Actions.name, '_matlab_introspec'));

            obj.NetworkDetails.Nodes = obj.Nodes.name;
            obj.NetworkDetails.Topics = obj.Topics.name;
            obj.NetworkDetails.Services = obj.Services.name;
            obj.NetworkDetails.Actions = obj.Actions.name;

            obj.TopicEndPoints = containers.Map;
            
            % Creating introspec object to fetch network information
            introspec = ros.ros2.internal.Introspection();

            % Getting topic types
            topicInfo = ...
                    introspec.topiclisttypes([], str2double(obj.DomainId));

            obj.TypeToTopics = mapTypesWithNames(topicInfo(:,1), topicInfo(:,2));

            obj.TopicsToType = mapNamesWithType(topicInfo(:,1), topicInfo(:,2));
            
            % Getting service types
            serviceInfo = ...
                    introspec.servicelisttypes([], str2double(obj.DomainId));

            obj.TypeToServices = mapTypesWithNames(serviceInfo(:,1), serviceInfo(:,2));

            obj.ServicesToType = mapNamesWithType(serviceInfo(:,1), serviceInfo(:,2));
            
            % Getting action types
            actionInfo = ...
                    introspec.actionlisttypes([], str2double(obj.DomainId));

            obj.TypeToActions = mapTypesWithNames(actionInfo(:,1), actionInfo(:,2));

            obj.ActionsToType = mapNamesWithType(actionInfo(:,1), actionInfo(:,2));
            
            res = ros2('topic', 'endpoints', 'alltopics', 'DomainID', obj.DomainId);
            for idx = 1:numel(res)
                endpoint = res{idx};
                topic = endpoint(1).topicname;
                obj.TopicEndPoints(topic) = endpoint;
            end

            obj.ServiceEndPoints = ros2('service', 'endpoints', 'DomainID', obj.DomainId);

            % Create service end point map
            obj.ServiceEndPointMap = createEndPointMap(obj.ServiceEndPoints);

            obj.ActionEndPoints = ros2('action', 'endpoints', 'DomainID', obj.DomainId);

            % Create action end point map
            obj.ActionEndPointMap = createEndPointMap(obj.ActionEndPoints);

            obj.createGraph();

            obj.createNodeEndPoints();
            
            obj.GraphUpdated = true;

            % Initialize attributes associated with advanced filtering upon
            % refresh
            obj.PositiveFilters = [];
            obj.NegativeFilters = [];
            obj.PreviousAdvancedQuery = [];
            obj.QueriedDepth = 1;
        end

        function initializeNodeEndPoints(obj)
            % initializeNodeEndPoints initialize the node end points

            obj.NodeEndPoints.PublishesTo = containers.Map;
            obj.NodeEndPoints.SubscribesTo = containers.Map;
            obj.NodeEndPoints.ServiceClientTo = containers.Map;
            obj.NodeEndPoints.ServiceServerTo = containers.Map;
            obj.NodeEndPoints.ActionClientTo = containers.Map;
            obj.NodeEndPoints.ActionServerTo = containers.Map;
        end

        function addInfo(obj, endPoints, mapOutgoing, mapIncoming, typeCheck)
            % addInfo adds information in node end points

            % Get all the keys from the map
            allKeys = keys(endPoints);
            
            % Iterate over each key in the map
            for k = 1:numel(allKeys)
                currentKey = allKeys{k};
                
                % Get the array of structs associated with the current key
                endPointArray = endPoints(currentKey);
                
                % Check if endPointArray is a single struct or an array
                if ~isstruct(endPointArray)
                    endPointArray = {endPointArray}; % Convert to cell array if it's a single struct
                end
                
                % Iterate over each struct in the array
                for j = 1:numel(endPointArray)
                    currentEndPoint = endPointArray(j);
                    nodeName = validator(currentEndPoint.nodename, currentEndPoint.nodenamespace);
                    nodeName = nodeName{1};
                    
                    % Determine the map to update based on endpointtype
                    if strcmp(currentEndPoint.endpointtype, typeCheck)
                        % Add to the specified map
                        if isKey(obj.NodeEndPoints.(mapOutgoing), nodeName)
                            obj.NodeEndPoints.(mapOutgoing)(nodeName) = ...
                                [obj.NodeEndPoints.(mapOutgoing)(nodeName), {currentKey}];
                        else
                            obj.NodeEndPoints.(mapOutgoing)(nodeName) = {currentKey};
                        end
                    else
                        % Add to the other specified map
                        if isKey(obj.NodeEndPoints.(mapIncoming), nodeName)
                            obj.NodeEndPoints.(mapIncoming)(nodeName) = ...
                                [obj.NodeEndPoints.(mapIncoming)(nodeName), {currentKey}];
                        else
                            obj.NodeEndPoints.(mapIncoming)(nodeName) = {currentKey};
                        end
                    end
                end
            end
        end

        function addTopicInfo(obj, endPoints)
            % addTopicInfo adds topics in the node end points

            obj.addInfo(endPoints, 'PublishesTo', 'SubscribesTo', 'Publisher');
        end

        function addServiceInfo(obj, endPoints)
            % addServiceInfo adds services in the node end points

            obj.addInfo(endPoints, 'ServiceServerTo', 'ServiceClientTo', 'Server');
        end

        function addActionInfo(obj, endPoints)
            % addActionInfo adds actions in the node end points

            obj.addInfo(endPoints, 'ActionServerTo', 'ActionClientTo', 'Server');
        end

        function createNodeEndPoints(obj)
            % createNodeEndPoints creates the node end points

            obj.initializeNodeEndPoints();
            obj.addTopicInfo(obj.TopicEndPoints);
            obj.addServiceInfo(obj.ServiceEndPointMap);
            obj.addActionInfo(obj.ActionEndPointMap);
        end

        function nodeNeighbors = getNodeNeighborsInfo(obj, nodeName, ...
                showDefaultTopics, showDefaultServices, showActionTopicsAndServices)
            % getNodeNeighborsInfo fetches information related to neighbors
            % of provided node

            publishers = {};
            subscribers = {};
            svcClients = {};
            svcServers = {};
            actClients = {};
            actServers = {};

            if isKey(obj.NodeEndPoints.PublishesTo, nodeName)
                publishers = obj.NodeEndPoints.PublishesTo(nodeName); 
            end

            if isKey(obj.NodeEndPoints.SubscribesTo, nodeName)
                subscribers = obj.NodeEndPoints.SubscribesTo(nodeName);
            end

            if isKey(obj.NodeEndPoints.ServiceServerTo, nodeName)
                svcServers = obj.NodeEndPoints.ServiceServerTo(nodeName);
            end

            if isKey(obj.NodeEndPoints.ServiceClientTo, nodeName)
                svcClients = obj.NodeEndPoints.ServiceClientTo(nodeName);
            end

            if isKey(obj.NodeEndPoints.ActionServerTo, nodeName)
                actServers = obj.NodeEndPoints.ActionServerTo(nodeName);
            end

            if isKey(obj.NodeEndPoints.ActionClientTo, nodeName)
                actClients = obj.NodeEndPoints.ActionClientTo(nodeName);
            end

            if ~showDefaultTopics
                publishers = filterStrings(publishers, obj.DefaultTopicsKeywords);
                subscribers = filterStrings(subscribers, obj.DefaultTopicsKeywords);
            end

            if ~showDefaultServices
                svcServers = filterStrings(svcServers, obj.DefaultServicesKeywords);
                svcClients = filterStrings(svcClients, obj.DefaultServicesKeywords);
            end

            if ~showActionTopicsAndServices
                publishers = filterStrings(publishers, obj.DefaultActionsKeywords);
                subscribers = filterStrings(subscribers, obj.DefaultActionsKeywords);
                svcServers = filterStrings(svcServers, obj.DefaultActionsKeywords);
                svcClients = filterStrings(svcClients, obj.DefaultActionsKeywords);
            end

            % Convert to comma separated string
            nodeNeighbors.publishersText = strjoin(publishers, ', ');
            nodeNeighbors.subscribersText = strjoin(subscribers, ', ');
            nodeNeighbors.svcClientsText = strjoin(svcClients, ', ');
            nodeNeighbors.svcServersText = strjoin(svcServers, ', ');
            nodeNeighbors.actClientsText = strjoin(actClients, ', ');
            nodeNeighbors.actServersText = strjoin(actServers, ', ');
        end
        
        function topicNeighbors = getTopicNeighborsInfo(obj, topicName)
            % getTopicNeighborsInfo fetches information related to neighbors
            % of provided topic

            % Get the array of structs associated with the current key
            endPointArray = obj.TopicEndPoints(topicName);
            
            topicNeighbors = getNeighborsInfo(endPointArray, 'Publisher', 'pubTopicsText', 'subTopicsText');
        end

        function serviceNeighbors = getServiceNeighborsInfo(obj, svcName)
            % getServiceNeighborsInfo fetches information related to neighbors
            % of provided service

            % Get the array of structs associated with the current key
            endPointArray = obj.ServiceEndPointMap(svcName);
            
            serviceNeighbors = getNeighborsInfo(endPointArray, 'Server', 'servers', 'clients');
        end

        function actionNeighbors = getActionNeighborsInfo(obj, svcName)
            % getActionNeighborsInfo fetches information related to neighbors
            % of provided action

            % Get the array of structs associated with the current key
            endPointArray = obj.ActionEndPointMap(svcName);
            
            actionNeighbors = getNeighborsInfo(endPointArray, 'Server', 'servers', 'clients'); 
        end


        % createGraph creates the graph which helps us in finding neighbors
        % for advanced filtering
        function createGraph(obj)
            % Preparing graph
            obj.MLGraph = graph;

            obj.MLGraph = addnode(obj.MLGraph, [obj.Nodes.name; obj.Topics.name; obj.Services.name; obj.Actions.name]);

            obj.addEdgesToGraph(obj.TopicEndPoints, 'topicname');

            obj.addEdgesToGraph(obj.ServiceEndPointMap, 'service');

            obj.addEdgesToGraph(obj.ActionEndPointMap, 'service');
        end

        function addEdgesToGraph(obj, endPoints, field)
            % Get all the keys from the map
            allKeys = keys(endPoints);
            
            % Adding edge in MLGraph
            for k = 1:numel(allKeys)
                currentKey = allKeys{k};
                
                % Get the array of structs associated with the current key
                endPointArray = endPoints(currentKey);
                
                % Check if endPointArray is a single struct or an array
                 if ~isstruct(endPointArray)
                    endPointArray = {endPointArray}; % Convert to cell array if it's a single struct
                end
                
                % Iterate over each struct in the array
                for j = 1:numel(endPointArray)
                    currentEndPoint = endPointArray(j);
                    nodeName = validator(currentEndPoint.nodename, currentEndPoint.nodenamespace);
                    if ismember(currentEndPoint.(field), obj.MLGraph.Nodes.Name) && ismember(nodeName, obj.MLGraph.Nodes.Name)
                        obj.MLGraph = addedge(obj.MLGraph, currentEndPoint.(field), nodeName, 1);
                    end
                end
            end
        end
        
        function validEntities = findValidEntities(obj, currentMLGraph, queries)
            dist = obj.QueriedDepth;
            % Initialize an empty array to store valid entities
            validEntities = {};
            
            % Iterate over each string in the queries cell array
            for idx = 1:numel(queries)
                % Get the current query string
                query = queries{idx};

                if findnode(currentMLGraph, query) == 0
                    continue;
                end
                
                % Add queried term to valid entities only if it is present
                % in graph, otherwise not.
                validEntities = [validEntities; query]; %#ok<AGROW>
                
                % Use the nearest function to find neighbors at the specified distance
                % Assuming the nearest function is applicable to the graph object
                neighbors = nearest(currentMLGraph, query, dist);
                
                % Concatenate the results to the validEntities array
                validEntities = [validEntities; neighbors]; %#ok<AGROW>
            end
            
            % Ensure validEntities contains only unique values
            validEntities = unique(validEntities);
        end

        function applyFilter(obj, showDefaultTopics, showDefaultServices, showActionTopicsAndServices,advancedQuery)
            
            obj.Nodes.name = obj.NetworkDetails.Nodes;
            obj.Topics.name = obj.NetworkDetails.Topics;
            obj.Services.name = obj.NetworkDetails.Services;
            obj.Actions.name = obj.NetworkDetails.Actions;
            
            % Defining graph to be used
            currentMLGraph = obj.MLGraph;
            
            % If there are no nodes present in the ROS network, even if the option to
            % show default topics is checked, eliminate the default topics. Topics
            % without nodes do not make sense.
            if isempty(obj.Nodes.name) || ~showDefaultTopics
                currentMLGraph = updateMLGraph(currentMLGraph, obj.DefaultTopicsKeywords, obj.Topics.name);
                obj.Topics.name = filterStrings(obj.Topics.name, obj.DefaultTopicsKeywords);
            end

            if ~showDefaultServices
                currentMLGraph = updateMLGraph(currentMLGraph, obj.DefaultServicesKeywords, obj.Services.name);
                obj.Services.name = filterStrings(obj.Services.name, obj.DefaultServicesKeywords);
            end

            if ~showActionTopicsAndServices
                currentMLGraph = updateMLGraph(currentMLGraph, obj.DefaultActionsKeywords, obj.Topics.name);
                obj.Topics.name = filterStrings(obj.Topics.name, obj.DefaultActionsKeywords);
                currentMLGraph = updateMLGraph(currentMLGraph, obj.DefaultActionsKeywords, obj.Services.name);
                obj.Services.name = filterStrings(obj.Services.name, obj.DefaultActionsKeywords);
            end

            % Add the checkboxes to the advancedQuery
            advancedQuery.showDefaultTopics = showDefaultTopics;
            advancedQuery.showDefaultServices = showDefaultServices;
            advancedQuery.showActionTopicsAndServices = showActionTopicsAndServices;
            
            % If Query is not validated, the complete graph will be shown.
            if validateAdvancedQuery(advancedQuery)

                obj.QueriedDepth = str2double(advancedQuery.depth);

                if ~onlyDepthChanged(advancedQuery, obj.PreviousAdvancedQuery)
                    obj.processAdvancedQuery(advancedQuery);
                end

                finalQueries = [obj.QueriedNodes.name; obj.QueriedTopics.name; ...
                    obj.QueriedServices.name; obj.QueriedActions.name ; ...
                    obj.QueriedTopicsByType.name; obj.QueriedServicesByType.name; ...
                    obj.QueriedActionsByType.name];

                obj.ValidEntities = obj.findValidEntities(currentMLGraph,finalQueries);
            else
                obj.QueriedNodes.name = obj.Nodes.name;
                obj.QueriedTopics.name = obj.Topics.name;
                obj.QueriedServices.name = obj.Services.name;
                obj.QueriedActions.name = obj.Actions.name;
                obj.ValidEntities = [obj.QueriedNodes.name; obj.QueriedTopics.name; ...
                    obj.Services.name; obj.Actions.name];
                obj.NegativeFilters = [];
            end

            % Apply Negative Filter on filter box entities
            obj.ValidEntities = applyNegativeFilter(obj.NegativeFilters, obj.ValidEntities);

            % Apply Negative Filter on queried nodes as queried nodes is
            % used in RosGraphViewer app to add unconnected nodes in the
            % graph
            obj.QueriedNodes.name = applyNegativeFilter(obj.NegativeFilters, obj.QueriedNodes.name);

            obj.PreviousAdvancedQuery = advancedQuery;
        end

        function processAdvancedQuery(obj, advancedQuery)
             obj.QueriedNodes.name = {};
             obj.QueriedTopics.name = {};
             obj.QueriedServices.name = {};
             obj.QueriedActions.name = {};
             obj.QueriedServicesByType.name = {};
             obj.QueriedTopicsByType.name = {};
             obj.PositiveFilters = [];
             obj.NegativeFilters = [];
                 

             % Filtering graph based upon message types
             obj.applyMesssageTypeFilters(advancedQuery);

             % Extracting negative filters and positive filters
             obj.separateKeywordFilters(advancedQuery);
             
             % Applying positive filters
             obj.applyPositiveFilters(advancedQuery);
        end

        function applyMesssageTypeFilters(obj, advancedQuery)
            if any(ismember(advancedQuery.selected, {obj.DataTypesId}))
                query = advancedQuery.text;
                query = strrep(query," ", "");
                splitStrArr = strsplit(query,",");
                % Remove empty strings from the cell array
                messageTypes = splitStrArr(~cellfun('isempty', splitStrArr));
                for idx = 1:numel(messageTypes)
                    currentType = messageTypes(idx);
                    if isKey(obj.TypeToTopics, currentType)
                        obj.QueriedTopicsByType.name = [obj.QueriedTopicsByType.name ; obj.TypeToTopics(currentType)];
                    end
                    if isKey(obj.TypeToServices, currentType)
                        obj.QueriedServicesByType.name = [obj.QueriedServicesByType.name ; obj.TypeToServices(currentType)];
                    end
                    if isKey(obj.TypeToActions, currentType)
                        obj.QueriedActionsByType.name = [obj.QueriedActionsByType.name ; obj.TypeToActions(currentType)];
                    end
                end
             end
        end

        function separateKeywordFilters(obj, advancedQuery)
            if any(ismember(advancedQuery.selected, {obj.NodesId, obj.TopicsId, obj.ServicesId, obj.ActionsId}))
                query = advancedQuery.text;
                query = strrep(query," ", "");
                splitStrArr = strsplit(query,",");
                % Remove empty strings from the cell array
                splitStrArr = splitStrArr(~cellfun('isempty', splitStrArr));
                % Finding indexes of negative arrays
                negativeFiltersIndex = startsWith(splitStrArr, "~");
                % Storing Negative Filters
                obj.NegativeFilters = splitStrArr(negativeFiltersIndex);
                % Removing negative filters from positive filter array
                obj.PositiveFilters = splitStrArr(~negativeFiltersIndex);
                
                % Processing negative filter strings
                for idx = 1:numel(obj.NegativeFilters)
                    % Remove the first character of each string
                    obj.NegativeFilters(idx) = extractAfter(obj.NegativeFilters(idx), 1);
                end
             end
        end

        function applyPositiveFilters(obj, advancedQuery)
            if ~isempty(obj.PositiveFilters)
                for ii=1:numel(obj.PositiveFilters)
                    subQuery = char(obj.PositiveFilters(ii));
                    % Applying settings of advanced filtering only when there
                    % is some query
                    if ismember(obj.NodesId, advancedQuery.selected)
                         obj.QueriedNodes.name = [obj.QueriedNodes.name ; applyRegex(obj.Nodes.name, subQuery)];
                     end
    
                     if ismember(obj.TopicsId, advancedQuery.selected)
                         obj.QueriedTopics.name =[obj.QueriedTopics.name ; applyRegex(obj.Topics.name, subQuery)];
                     end
    
                     if ismember(obj.ServicesId, advancedQuery.selected)
                         obj.QueriedServices.name =[obj.QueriedServices.name ; applyRegex(obj.Services.name, subQuery)];
                     end
    
                     if ismember(obj.ActionsId, advancedQuery.selected)
                         obj.QueriedActions.name = [obj.QueriedActions.name ; applyRegex(obj.Actions.name, subQuery)];
                     end
                end
                
                obj.QueriedNodes.name = unique(obj.QueriedNodes.name);
                obj.QueriedTopics.name = unique(obj.QueriedTopics.name);
                obj.QueriedServices.name = unique(obj.QueriedServices.name);
                obj.QueriedActions.name = unique(obj.QueriedActions.name);
            % For the case when only negative filter is applied and no
            % positive filter is applied
            elseif any(ismember(advancedQuery.selected, {obj.NodesId, obj.TopicsId, obj.ServicesId, obj.ActionsId}))
                obj.QueriedNodes.name = obj.Nodes.name;
                obj.QueriedTopics.name = obj.Topics.name;
                obj.QueriedServices.name = obj.Services.name;
                obj.QueriedActions.name = obj.Actions.name;
            end
        end

        function domainId = getDomainId(obj)
            domainId = obj.DomainId;
        end

        function list = getNetworkElementList(obj)
            list = [obj.QueriedNodes.name(:).', obj.QueriedTopics.name(:).', ...
                obj.QueriedServices.name(:).', obj.QueriedActions.name(:).'];
        end

        function list = getAllNetworkElementList(obj)
            list = [obj.Nodes.name(:).', obj.Topics.name(:).', ...
                obj.Services.name(:).', obj.Actions.name(:).'];
        end

        function outputStr = processParam(~, paramValue)
             % Get the size of paramValue
            dims = size(paramValue);
            
            % Check if paramValue is a 1x1 element
            if isequal(dims, [1, 1])
                % Return the value as a string
                outputStr = string(paramValue);
            else
                % Check if paramValue is a 1-dimensional vector
                if isvector(paramValue)
                    % If it's a column vector, convert it to a row vector
                    if dims(1) > 1
                        paramValue = paramValue';
                    end
                    
                    % Convert each element to a string and concatenate with commas
                    outputStr = strjoin(string(paramValue), ', ');
                else
                    % If paramValue is unexpected, ignore it and display
                    % empty.
                    outputStr = "";
                end
            end
        end

        function paramsWithVal = getParameterWithvalue(obj,nodeName)

            % getting the node parameters
            paramsWithVal = "";
            try
                if ~isKey(obj.ros2ParamObjMapForNodeName, nodeName)
                    obj.ros2ParamObjMapForNodeName(nodeName) = ros2param(nodeName,"DomainID",str2double(obj.DomainId));
                end
                paramObj = obj.ros2ParamObjMapForNodeName(nodeName);
                pList = list(paramObj);
                dim = size(pList);
                for idx = 1:dim(1)
                    if(~contains(pList(idx),{'qos_overrides','start_type_description_service'}))
                        paramsWithVal = paramsWithVal + pList{idx}+": "+obj.processParam(paramObj.get(pList{idx}));
                        if(idx ~= dim(1))
                            paramsWithVal = paramsWithVal + newline;
                        end
                    end
                end
            catch ex
                % If something goes wrong while fetching the params, ignore
                % it and display empty
                paramsWithVal = "";
            end
        end

        function svcType = getServiceType(obj,svcName)
            % Get service type for a service

            svcType = obj.ServicesToType(svcName);
        end

        function actType = getActionType(obj,actName)
            % Get action type for an action

            actType = obj.ActionsToType(actName);
        end
        
        function topicType = getTopicType(obj,topicName)
            % Get action type for an action

            topicType = obj.TopicsToType(topicName);
        end
        
        function endpointDetails = getTopicEndPoint(obj, topicName, endPointType,index)
            % Returns the end point details for a topic. Here connectionType is 
            % Publisher / Subscriber.
           
            topicEndPoints = obj.TopicEndPoints(topicName);
            % Filtering topicEndPoints wrt endPointType
            endpointDetails = topicEndPoints( ...
                arrayfun(@(x) strcmp(x.endpointtype, endPointType), topicEndPoints));
            endpointDetails = endpointDetails(index);
        end
    end
end

function filteredStrings = applyRegex(stringArray, regex)
    filteredStrings = [];
    regexResult = regexp(stringArray, regex, 'match');

    for idx = 1:numel(regexResult)
        if ~isempty(regexResult{idx})
            filteredStrings = [filteredStrings ; stringArray(idx)]; %#ok<AGROW>
        end
    end
end

function map = mapTypesWithNames(names, types)    
    % Initialize the map
    map = containers.Map;

    % Loop through each element
    for idx = 1:numel(types)
        type = types{idx}{1};
        name = names{idx};

        if isKey(map, type)
            % If the key already exists, append the new topic name to the existing array
            map(type) = [map(type); {name}];
        else
            % If the key does not exist, create a new entry
            map(type) = {name};
        end
    end
end

function map = mapNamesWithType(names, types)
    % Initialize the map
    map = containers.Map;

    % Loop through each element
    for idx = 1:numel(types)
        type = types{idx}{1};
        name = names{idx};

        map(name) = type;
    end
end

function name = validator(name, namespace)
    if (name(1) ~= '/') && not(strcmp(namespace, "/"))
        name = strcat('/', name);
    end
    name = cellstr(strcat(namespace, name));
end

% Remove not required nodes from the graph
function newMLGraph = updateMLGraph(currentMLGraph, keywordsList, termsList)
    % Initialize the list of removable nodes
    removableNodes = {};

    % Iterate over each keyword in the keywords list
    for i = 1:length(keywordsList)
        % Get the current keyword
        keyword = keywordsList{i};

        % Find nodes containing the current keyword
        nodesToRemove = termsList(contains(termsList, keyword));

        % Append the found nodes to the removableNodes list
        removableNodes = [removableNodes; nodesToRemove]; %#ok<AGROW>
    end

    % Remove duplicate nodes, if any
    removableNodes = unique(removableNodes);

    % Remove the nodes from the graph
    newMLGraph = rmnode(currentMLGraph, removableNodes);
end

function endPointMap = createEndPointMap(endPoints)
    
    endPointMap = containers.Map();

    % Iterate over each end point
    for idx = 1:numel(endPoints)
        % Extract the current service and the end point
        currentService = endPoints(idx).service;
        currentEndPoint = endPoints(idx);
        
        % Check if the service already exists in the map
        if isKey(endPointMap, currentService)
            % Append the current end point to the existing array
            endPointMap(currentService) = [endPointMap(currentService), currentEndPoint];
        else
            % Create a new entry in the map with the current end point
            endPointMap(currentService) = currentEndPoint;
        end
    end
end

function target = applyNegativeFilter(negativeFilters, target)
    for idx = 1:numel(negativeFilters)
        negativeFilter = negativeFilters{idx};
        
        % Find indices of target that contain the negative filter as a substring
        matches = cellfun(@(x) contains(x, negativeFilter), target);
        
        % Remove those entries from target
        target(matches) = [];
    end
end

% validateAdvancedQuery checks the presence of all the expected fields in
% the advanced query
function result = validateAdvancedQuery(advancedQuery)
    result = ~isempty(advancedQuery) && ...
        isfield(advancedQuery, 'text') && ...
        strlength(advancedQuery.text) && ...
        isfield(advancedQuery, 'selected') && ...
        ~isempty(advancedQuery.selected) && ...
        isfield(advancedQuery, 'depth') && ...
        str2double(advancedQuery.depth) >= 1;
end

% onlyDepthChanged function checks if only the depth is changed or entire
% query to improve the performance.
function result = onlyDepthChanged(currentQuery, previousQuery)
    % Initialize result to true
    result = true;
    
    % If previousQuery is not valid, then we should apply filter
    if ~validateAdvancedQuery(previousQuery)
        result = false;
        return;
    end
    
    % Get field names for both structs
    currentFields = fieldnames(currentQuery);
    previousFields = fieldnames(previousQuery);
    
    % Check if both structs have the same fields
    if ~isequal(sort(currentFields), sort(previousFields))
        result = false;
        return;
    end
    
    % Iterate over each field
    for i = 1:length(currentFields)
        fieldName = currentFields{i};
        
        % Skip the 'depth' field
        if strcmp(fieldName, 'depth')
            continue;
        end
        
        % Check if the field values are the same
        if ~isequal(currentQuery.(fieldName), previousQuery.(fieldName))
            result = false;
            return;
        end
    end
end

function neighbors = getNeighborsInfo(endPointArray, typeCheck, outgoingField, incomingField)
    % getNeighborsInfo fetches information related to neighbors
    % based on endpoint type

    % Check if endPointArray is a single struct or an array
    if ~isstruct(endPointArray)
        endPointArray = {endPointArray}; % Convert to cell array if it's a single struct
    end
    
    outgoing = {};
    incoming = {};
    % Iterate over each struct in the array
    for j = 1:numel(endPointArray)
        currentEndPoint = endPointArray(j);
        nodeName = validator(currentEndPoint.nodename, currentEndPoint.nodenamespace);
        if strcmp(currentEndPoint.endpointtype, typeCheck)
            outgoing = [outgoing, nodeName]; %#ok<AGROW>
        else
            incoming = [incoming, nodeName]; %#ok<AGROW>
        end
    end

    neighbors.(outgoingField) = strjoin(outgoing, ', '); 
    neighbors.(incomingField) = strjoin(incoming, ', '); 
end

function filteredList = filterStrings(originalList, stringsToFilter)
    filteredList = originalList;

    % Iterate over each string to filter
    for i = 1:length(stringsToFilter)
        % Get the current string to filter
        filterString = stringsToFilter{i};

        % Remove entries containing the current filter string
        filteredList = filteredList(~contains(filteredList, filterString));
    end
end

% LocalWords:  introspec alltopics rosout qos