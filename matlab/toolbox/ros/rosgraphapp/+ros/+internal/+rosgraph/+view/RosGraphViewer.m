classdef RosGraphViewer < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties(Access = {?matlab.unittest.TestCase, ?ros.internal.rosgraph.view.AppView})
        Graph

        GraphData = struct;
        GraphNodes;

        VisualizerDocGroup
        Document
        HtmlGrid
        UIHTMLNetworkView

        JSToMatlabCallback = function_handle.empty
        
        % Initializing MaxNameSpace with -1 as we will calculate it addNodesIntoCYGraph
        MaxNamespace = -1
    end
    
    properties (Constant, Access = ?matlab.unittest.TestCase)
        %% Tags
        TagDocumentGroup = "NetworkGraphDocGroup"
        TagDocument = "ROS2NetworkGraphViewer"
        TagUiHtmlGrid = "UiHtmlViewGrid"
        TagUiHtmlView = "UIHtmlView"

        %% Catalogs
        TitleDocGroup = getString(message("ros:rosgraphapp:view:TitleDocGroup"))
        TitleDoc = getString(message("ros:rosgraphapp:view:TitleDoc"))

        %% Events
        EventShowHideDeadSinkEvent = "ShowHideDeadSinkEvent"
        EventShowHideLeafTopicEvent = "ShowHideLeafTopicEvent"
        EventShowHideUnreachableEvent = "ShowHideUnreachableEvent"
        EventSaveAsImageEvent = "SaveAsImageEvent"
        EventAutoArrangeEvent = "AutoArrangeEvent"
        EventShowElementEvent = "ShowElementEvent"
        EventHideElementEvent = "HideElementEvent"
        EventFindConnectionEvent = "FindConnectionEvent"
        EventSetupMATLABThemeEvent = "SetupMATLABThemeEvent"
        EventToggleAdvancedFiltersEvent = "ToggleAdvancedFiltersEvent"
    end

    methods
        function obj = RosGraphViewer(appContainer)
            
           createDocument(obj,appContainer)
        end

        function createDocument(obj,appContainer)
            
            groupOptions.Tag = obj.TagDocumentGroup;
            groupOptions.Title = obj.TitleDocGroup;
            obj.VisualizerDocGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(appContainer, obj.VisualizerDocGroup);

            %figOptions.Title = obj.InitialTitle;
            figOptions.DocumentGroupTag = obj.VisualizerDocGroup.Tag;
            obj.Document = matlab.ui.internal.FigureDocument(figOptions);
            % setting tag for UI testing purpose
            obj.Document.Tag = obj.TagDocument;
            obj.Document.Title = obj.TitleDoc;
            obj.Document.Closable = false;
            add(appContainer, obj.Document);
            obj.HtmlGrid = uigridlayout(obj.Document.Figure, [1 1], ...
                                "Tag",obj.TagUiHtmlGrid,"Padding", [0 0 0 0]);

            % obj.UIHTMLNetworkView = uihtml(obj.HtmlGrid,"DataChangedFcn",@(src,event) sendEventToHTMLSource(obj.UIHTMLNetworkView,"MyMATLABEvent",[src.Data '- Event sent to JS']), ...
            %     "HTMLEventReceivedFcn",@(src,event) disp(event));

            obj.UIHTMLNetworkView = uihtml(obj.HtmlGrid, "HTMLEventReceivedFcn",@(src, event) htmlEventCallback(src, event,matlab.internal.WeakHandle(obj)));
            matlab.ui.internal.HTMLUtils.enableTheme(obj.UIHTMLNetworkView); % Enabling theming for web widgets used
            obj.UIHTMLNetworkView.Layout.Row = 1;
            obj.UIHTMLNetworkView.Layout.Column = 1;
            obj.UIHTMLNetworkView.Tag = obj.TagUiHtmlView;
            obj.UIHTMLNetworkView.HTMLSource = fullfile(matlabroot,'toolbox','ros','rosgraphapp','network.html');
            
            function htmlEventCallback(src, event ,whObj)
                hRosGraphViewer = whObj.get;

                if isstruct(event.HTMLEventData) && ... 
                        isfield(event.HTMLEventData,'event') && ...
                        strcmp(event.HTMLEventData.event,'HTMLPageLoaded')
                    hRosGraphViewer.setMATLABTheme;
                else
                    makeCallback(hRosGraphViewer.JSToMatlabCallback, src, event);
                end
            end
            
        end
        
        function setMATLABTheme(obj)

            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventSetupMATLABThemeEvent,obj.getTheme);
        end

        function addNodesIntoCYGraph(obj,nodes,type,nameSpaceLevel)
            
            num_nodes = length(nodes);
            for idx = 1:num_nodes

                strCellarr = split(nodes{idx},'/');
                % Calculating MaxNameSpace
                obj.MaxNamespace = max(obj.MaxNamespace, numel(strCellarr) - 2);
                if nameSpaceLevel > 0 && numel(strCellarr) > 2
                    nItr = numel(strCellarr) - 2;
                    if nItr > nameSpaceLevel
                        nItr = nameSpaceLevel;
                    end
                    if nItr > 0
                        nameSpaces = "";
                        for ii=1:nItr
                            parentId = nameSpaces;
                            nameSpaces =  nameSpaces + "/" + string(strCellarr{ii+1});
                            if strlength(parentId) > 0
                                obj.GraphData.nodes{end+1} = struct('data',struct('id',nameSpaces+"_nms",'text',nameSpaces,'type', 'namespace','parent',parentId+"_nms"));
                            else
                                obj.GraphData.nodes{end+1} = struct('data',struct('id',nameSpaces+"_nms",'text',nameSpaces,'type', 'namespace'));
                            end
                        end
                        obj.GraphData.nodes{end+1} = struct('data',struct('id',nodes{idx},'type', type, 'text',nodes{idx},'parent',nameSpaces+"_nms"));
                    else
                        obj.GraphData.nodes{end+1} = struct('data',struct('id',nodes{idx},'type', type, 'text',nodes{idx}));
                    end
                else
                    obj.GraphData.nodes{end+1} = struct('data',struct('id',nodes{idx},'type', type, 'text',nodes{idx}));
                end
                
                obj.GraphNodes(nodes{idx}) = type;
            end
        end

        function createGraph(obj,graph,layout,nameSpaceLevel)
             
            obj.Graph = graph;
            obj.GraphNodes = containers.Map;
            
            obj.GraphData.nodes = {};

            nodes = obj.Graph.Nodes.name;
            queriedNodes = obj.Graph.QueriedNodes.name;
            
            topics = obj.Graph.Topics.name;
            
            services = obj.Graph.Services.name;
            
            actions = obj.Graph.Actions.name;

            validEntities = obj.Graph.ValidEntities;
           
            obj.GraphData.edges = {};

            for idx = 1:length(topics)
                topicname = topics{idx};
                pubCtr = 0;
                subCtr = 0;
                endpoints = obj.Graph.TopicEndPoints(topicname);

                for j = 1:numel(endpoints)
                    if contains(endpoints(j).nodename, '_matlab_introspec_') ...
                            || contains(endpoints(j).nodename, '_NODE_NAME_UNKNOWN_')
                        continue;
                    end
                    
                    edge = struct('data',struct('source', '-', 'target', '-','type','topic','index',0));

                    nodeName = obj.validator(endpoints(j).nodename, endpoints(j).nodenamespace);
                    if(~ismember(nodeName{1}, nodes) || ~ismember(topicname, topics))
                        continue;
                    end
                    if(~ismember(nodeName{1}, validEntities) || ~ismember(topicname, validEntities))
                        continue;
                    end
                    if ~ismember(nodeName{1}, obj.GraphNodes.keys)
                        addNodesIntoCYGraph(obj,nodeName(1),'rosnode',nameSpaceLevel)
                    end
                    if ~ismember(topicname, obj.GraphNodes.keys)
                        addNodesIntoCYGraph(obj,{topicname},'topic',nameSpaceLevel)
                    end
                    if strcmp(endpoints(j).endpointtype, 'Publisher')
                        edge.data.source = nodeName{1}; 
                        edge.data.target = topicname;
                        pubCtr = pubCtr + 1;
                        edge.data.index = pubCtr;
                    else
                        edge.data.target = nodeName{1}; 
                        edge.data.source = topicname;
                        subCtr = subCtr + 1;
                        edge.data.index = subCtr;
                    end
                    obj.GraphData.edges{end+1} = edge;
                end
            end
            
            serviceList = obj.Graph.ServiceEndPoints;
            for idx = 1:length(serviceList)
                if contains(obj.Graph.ServiceEndPoints(idx).nodename, '_matlab_introspec_')
                    continue;
                end
                service = obj.Graph.ServiceEndPoints(idx).service;
                if contains(service, '_matlab_introspec_')
                    continue;
                end

                
                nodename = obj.Graph.ServiceEndPoints(idx).nodename;
                nodenamespace = obj.Graph.ServiceEndPoints(idx).nodenamespace;
                endpointtype = obj.Graph.ServiceEndPoints(idx).endpointtype;

                nodeName = obj.validator(nodename, nodenamespace);
                edge = struct('data',struct('source', '-', 'target', '-','type','service'));
                if(~ismember(nodeName{1}, nodes) || ~ismember(service, services))
                    continue;
                end
                if(~ismember(nodeName{1}, validEntities) || ~ismember(service, validEntities))
                    continue;
                end
                if ~ismember(nodeName{1}, obj.GraphNodes.keys)
                    addNodesIntoCYGraph(obj,nodeName(1),'rosnode',nameSpaceLevel)
                end
                if ~ismember(service, obj.GraphNodes.keys)
                    addNodesIntoCYGraph(obj,{service},'service_child',nameSpaceLevel)
                end
                if strcmp(endpointtype, 'Server')
                    edge.data.target = nodeName{1}; 
                    edge.data.source = service;
                elseif strcmp(endpointtype, 'Client')
                    edge.data.source = nodeName{1}; 
                    edge.data.target = service;
                end
                obj.GraphData.edges{end+1} = edge;
            end

            actionList = obj.Graph.ActionEndPoints;
            for idx = 1:length(actionList)
                if contains(obj.Graph.ActionEndPoints(idx).nodename, '_matlab_introspec_')
                    continue;
                end
                action = obj.Graph.ActionEndPoints(idx).service;
                if contains(action, '_matlab_introspec_')
                    continue;
                end

                nodename = obj.Graph.ActionEndPoints(idx).nodename;
                nodenamespace = obj.Graph.ActionEndPoints(idx).nodenamespace;
                endpointtype = obj.Graph.ActionEndPoints(idx).endpointtype;

                nodeName = obj.validator(nodename, nodenamespace);
                edge = struct('data',struct('source', '-', 'target', '-','type','action'));
                if(~ismember(nodeName{1}, nodes) || ~ismember(action, actions))
                    continue;
                end
                if ~ismember(nodeName{1}, validEntities) || ~ismember(action, validEntities)
                    continue;
                end
                if ~ismember(nodeName{1}, obj.GraphNodes.keys)
                    addNodesIntoCYGraph(obj,nodeName(1),'rosnode',nameSpaceLevel)
                end
                if ~ismember(action, obj.GraphNodes.keys)
                    addNodesIntoCYGraph(obj,{action},'action_child',nameSpaceLevel)
                end

                if strcmp(endpointtype, 'Server')
                    edge.data.target = nodeName{1}; 
                    edge.data.source = action;
                elseif strcmp(endpointtype, 'Client')
                    edge.data.source = nodeName{1}; 
                    edge.data.target = action;
                end
                obj.GraphData.edges{end+1} = edge;
            end

            displayedNodeIdx = contains(obj.GraphNodes.values, 'rosnode');
            if ~isempty(displayedNodeIdx)
                allDisplayedElements = obj.GraphNodes.keys;
                displayedRosNodes = allDisplayedElements(displayedNodeIdx);
                missedNodes = setdiff(queriedNodes, displayedRosNodes);
            else
                missedNodes = queriedNodes;
            end
            addNodesIntoCYGraph(obj,missedNodes,'rosnode',nameSpaceLevel)
            
            htmlData.messageTypes = [keys(obj.Graph.TypeToTopics), keys(obj.Graph.TypeToServices), keys(obj.Graph.TypeToActions)];
            htmlData.nameList = [obj.Graph.Nodes.name', obj.Graph.Topics.name', obj.Graph.Services.name', obj.Graph.Actions.name'];
            htmlData.graphUpdated = obj.Graph.GraphUpdated;
            htmlData.graphData = obj.GraphData;
            htmlData.layout = layout;
            obj.UIHTMLNetworkView.Data = htmlData;

            % Resetting graphUpdate status
            obj.Graph.GraphUpdated = false;
        end
        
        % getMaxNameSpace sends the MaxNameSpace
        function maxNameSpace = getMaxNameSpace(obj)
            maxNameSpace = obj.MaxNamespace;
        end
        
        % initializeNamespace initializes the MaxNameSpace
        function initializeNamespace(obj)
            obj.MaxNamespace = -1;
        end

        function showDeadSink(obj, val)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventShowHideDeadSinkEvent,val)
        end

        function showLeafTopic(obj, val)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventShowHideLeafTopicEvent,val)
        end

        function showUnreachable(obj, val)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventShowHideUnreachableEvent,val)
        end

        function exportGraph(obj)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventSaveAsImageEvent,{})
        end

        function autoArrangeGraph(obj, layout)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventAutoArrangeEvent,layout)
        end

        function toggleAdvancedFilters(obj, visiblity)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventToggleAdvancedFiltersEvent,visiblity)
        end

        function showElement(obj, elementName)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventShowElementEvent,elementName)
        end

        function hideElement(obj, elementName)
            sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventHideElementEvent,elementName)
        end

        function findConnection(obj, elements)
            if ~isempty(elements.Element1) && ~isempty(elements.Element2)
                sendEventToHTMLSource(obj.UIHTMLNetworkView,obj.EventFindConnectionEvent,elements)
            end
        end

        function elements = getCurrentGraphElements(obj)
            elements = obj.GraphNodes;
        end

        function theme = getTheme(obj)
            % getTheme returns if the current theme is light or dark

            theme = 'light';
            if ~isempty(obj.Document.Figure.Theme)
                theme = lower(obj.Document.Figure.Theme.BaseColorStyle);
            end
        end
    end

    methods(Static)
        function name = validator(name, namespace)
            if (name(1) ~= '/') && not(strcmp(namespace, "/"))
                name = strcat('/', name);
            end
            name = cellstr(strcat(namespace, name));
        end
    end

end

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

    if ~isempty(fcn)
        feval(fcn, varargin{:})
    end
end

% LocalWords:  CY UIHTML uihtml nms introspec rosnode