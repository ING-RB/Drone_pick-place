classdef AppPresentor < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties
        Graph
        View
    end

    properties(Constant)
        InfiniteValue = 9223372036.8548
    end

    properties
        % PreviousNamespace holds the namespace value entered previously.
        % It is initialized with -2 as MaxNameSpace is initialized with -1
        % and it is supposed to be smaller than it for the very first
        % instance of name space change.
        PreviousNamespace = -2

        % Property to hold the advanced filtering settings
        Query
    end

    methods
        function obj = AppPresentor(model,view)
            
            obj.Graph = model;
            obj.View = view;
            view.setContext(obj);

            setupCallbacksListeners(obj)
        end

        function setupCallbacksListeners(obj)
            
            objWeakHndl = matlab.internal.WeakHandle(obj);
            
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.JSToMatlabCallback,@(source, eventData) obj.JSToMatlabCallback(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.RosNetworkDetailsEntered,@(source, eventData, domainId) obj.rosNetworkDetailsEntered(objWeakHndl, source, eventData,domainId))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.ArrangeButtonCallback, @(source, eventData) obj.autoArrange(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.RefreshButtonCallback,@(source, eventData) obj.refresh(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.FilterSettingsChangedCallback,@(source, eventData) obj.filter(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.AdvancedFilterCallback, @(source, eventData) obj.toggleFilters(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.LayoutChangedCallback,@(source, eventData) obj.layoutSelectionChanged(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.ExportButtonCallback,@(source, eventData) obj.export(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.NameSpacelLevelChangedCallback,@(source, eventData) obj.nameSpacelLevelChangedCallback(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.NetworkTreeElementSelectCallback,@(source, eventData) obj.networkTreeElementSelectCallback(objWeakHndl, source, eventData))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.CloseAppCallback,@(~, ~) obj.cleanupAndCloseApp(objWeakHndl))
            obj.View.registerCallback(ros.internal.rosgraph.view.AppView.DeleteProgressDlgCallback,@(source, eventData) obj.deleteProgressDlg(objWeakHndl, source, eventData))
        end
    end

    methods(Static)
        function init(view,model)
            ros.internal.rosgraph.presentor.AppPresentor(view,model);
        end

        function nameSpacelLevelChangedCallback(objWeakHndl, ~, ~)

            obj = objWeakHndl.get;
            % Loading progress bar when name space level is changed
            obj.View.displayProgressDlg;
            % TODO: g3291369: warning issue on rapid namespace change
            pause(0.5)


            % Avoiding updating graph if change in namespace level will not
            % affect the graph
            if obj.PreviousNamespace >= obj.View.getMaxNameSpace && ...
                    obj.View.getNameSpaceLavel >= obj.View.getMaxNameSpace
                % Updating PreviousNamespace
                obj.PreviousNamespace = obj.View.getNameSpaceLavel;
                % Deleting Progress Dialog bar
                obj.View.deleteProgressDlg;
                return;
            end
            % Updating Previous Namespace
            obj.PreviousNamespace = obj.View.getNameSpaceLavel;
            obj.View.createRosGraph(obj.Graph,obj.View.getSelectedLayout,obj.View.getNameSpaceLavel);

            keys = [string(getString(message('ros:rosgraphapp:view:PropertyDomainId'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfNodes'))); ...
                    string(getString(message('ros:rosgraphapp:view:PropertyNumberOfTopics'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfServices'))); ...
                    string(getString(message('ros:rosgraphapp:view:PropertyNumberOfActions')))];
            values = [string(obj.Graph.getDomainId); string(numel(obj.Graph.Nodes.name)); string(numel(obj.Graph.Topics.name)); string(numel(obj.Graph.Services.name)); string(numel(obj.Graph.Actions.name))];
            obj.View.updatePropertyView(keys,values)
        end
        
        % callback to delete the progress dialogue bar if sosmething fails
        % while loading the graph
        function deleteProgressDlg(objWeakHndl, ~, ~)
            obj = objWeakHndl.get;
            obj.View.deleteProgressDlg;
            return;
        end
        
        % Callback when elements in network tree are selected/unselected
        function networkTreeElementSelectCallback(objWeakHndl, src, ~)

            obj = objWeakHndl.get;
            
            node = src.SelectedNodes;
            checkedNodes = src.CheckedNodes;
            
            if ismember(node, checkedNodes)
                % Change the name from Service(5) to Service format and
                % pass to js
                obj.View.showRosGraphElement(regexprep(node.Text, '\(.*?\)', ''))
            else
                % Change the name from Service(5) to Service format and
                % pass to js
                obj.View.hideRosGraphElement(regexprep(node.Text, '\(.*?\)', ''))
            end
        end

        function ret = cleanupAndCloseApp(objWeakHndl, ~, ~)
            %cleanupAndCloseApp cleanup app before closing
            
            obj = objWeakHndl.get;
            % Cleanup the graph object that was available when creating the
            % graph in model
            obj.Graph.MLGraph = [];
            if ~isempty(obj.Graph.ros2ParamObjMapForNodeName)
                obj.Graph.ros2ParamObjMapForNodeName.remove(obj.Graph.ros2ParamObjMapForNodeName.keys);
            end
            ret = true;
        end

        function JSToMatlabCallback(objWeakHndl,~,event)
            obj = objWeakHndl.get;

            if strcmp(event.HTMLEventData.event,'selected')
                type = event.HTMLEventData.type;
                if strcmp(type, 'rosnode')
                    
                    nodeName = string(event.HTMLEventData.element);

                    % Get parameter details
                    parameterDetails = obj.Graph.getParameterWithvalue(nodeName);
                    
                    % Get info about node neighbors
                    nodeNeighbors = obj.Graph.getNodeNeighborsInfo(nodeName, ...
                                obj.View.getDefaultTopicvisibility, ...
                                obj.View.getDefaultServicevisibility, ...
                                obj.View.getActionTopicServicevisibility);

                    publishersText = nodeNeighbors.publishersText;
                    subscribersText = nodeNeighbors.subscribersText;
                    svcClientsText = nodeNeighbors.svcClientsText;
                    svcServersText = nodeNeighbors.svcServersText;
                    actClientsText = nodeNeighbors.actClientsText;
                    actServersText = nodeNeighbors.actServersText;

                    tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyEntity'))); string(getString(message('ros:rosgraphapp:view:PropertyName')));...
                        string(getString(message('ros:rosgraphapp:view:PropertyParameters'))); string(getString(message('ros:rosgraphapp:view:PropertyPublishesTo'))); ...
                        string(getString(message('ros:rosgraphapp:view:PropertySubscribesTo')));string(getString(message('ros:rosgraphapp:view:PropertySvcServer'))); ...
                        string(getString(message('ros:rosgraphapp:view:PropertySvcClient'))); string(getString(message('ros:rosgraphapp:view:PropertyActServer'))); 
                        string(getString(message('ros:rosgraphapp:view:PropertyActClient')))];
                    values = ["Node"; nodeName; parameterDetails; publishersText; subscribersText; svcServersText; svcClientsText; actServersText; actClientsText];
                    obj.View.updatePropertyView(tblKeys,values)
                    
                elseif strcmp(type, 'topic')

                    topicName = string(event.HTMLEventData.element);
                    
                    % Get topic type
                    topicType = getTopicType(obj.Graph,topicName);

                    % Get info about topic neighbors
                    topicNeighbors = obj.Graph.getTopicNeighborsInfo(topicName);
                    subTopicsText = topicNeighbors.subTopicsText;
                    pubTopicsText = topicNeighbors.pubTopicsText;

                    tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyEntity'))); string(getString(message('ros:rosgraphapp:view:PropertyName')));...
                        string(getString(message('ros:rosgraphapp:view:PropertyTopicType'))); string(getString(message('ros:rosgraphapp:view:PropertyPublisherNodes'))); ...
                        string(getString(message('ros:rosgraphapp:view:PropertySubscriberNodes')))];
                    values = ["Topic"; topicName; topicType; pubTopicsText; subTopicsText];
                    obj.View.updatePropertyView(tblKeys,values)

                elseif strcmp(type, 'service_child')
                    
                    svcName = string(event.HTMLEventData.element);
                    svcType = getServiceType(obj.Graph,svcName);

                    % Get info about service neighbors
                    svcNeighbors = obj.Graph.getServiceNeighborsInfo(svcName);
                    svcServerNodesText = svcNeighbors.servers;
                    svcClientNodesText = svcNeighbors.clients;

                    tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyEntity'))); string(getString(message('ros:rosgraphapp:view:PropertyName'))); ... 
                        string(getString(message('ros:rosgraphapp:view:PropertySvcType'))); getString(message('ros:rosgraphapp:view:PropertySvcServerNodes')); ...
                        string(getString(message('ros:rosgraphapp:view:PropertySvcClientNodes')))];
                    values = ["Service"; svcName; svcType; svcServerNodesText; svcClientNodesText];
                    obj.View.updatePropertyView(tblKeys,values)
                
                elseif strcmp(type, 'action_child')

                    actName = string(event.HTMLEventData.element);
                    actType = getActionType(obj.Graph,actName);

                    % Get info about action neighbors
                    actNeighbors = obj.Graph.getActionNeighborsInfo(actName);
                    actServerNodesText = actNeighbors.servers;
                    actClientNodesText = actNeighbors.clients;

                    tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyEntity'))); string(getString(message('ros:rosgraphapp:view:PropertyName'))); ... 
                                string(getString(message('ros:rosgraphapp:view:PropertyActType'))); string(getString(message('ros:rosgraphapp:view:PropertyActServerNodes'))); 
                                string(getString(message('ros:rosgraphapp:view:PropertyActClientNodes')))];
                    values = ["Action"; actName; actType; actServerNodesText; actClientNodesText];
                    obj.View.updatePropertyView(tblKeys,values)

                elseif strcmp(type, 'edge_topic')
                    
                    sourceName = string(event.HTMLEventData.source);
                    targetName = string(event.HTMLEventData.target);
                    index = event.HTMLEventData.index;
                    targetType = string(event.HTMLEventData.targetType);
                    if strcmpi(targetType,'topic')
                        topicEdgeType = 'Publisher';
                        topicName = targetName;
                        nodeName = sourceName;
                    else
                        topicEdgeType = 'Subscriber';
                        topicName = sourceName;
                        nodeName = targetName;
                    end
                    
                    endPointDetails = getTopicEndPoint(obj.Graph,topicName, topicEdgeType,index);

                    if isequal(endPointDetails.qoshistory, 'Unknown') 
                        qosHistory = getString(message("ros:rosgraphapp:view:PropertyInformationUnavailable"));
                    else
                        qosHistory = lower(string(endPointDetails.qoshistory));
                    end

                    if endPointDetails.qosdepth == 0
                        qosDepth = getString(message("ros:rosgraphapp:view:PropertyInformationUnavailable"));
                    else
                        qosDepth = lower(string(endPointDetails.qosdepth));
                    end

                    qosReliability = lower(string(endPointDetails.qosreliability));
                    qosDurability = lower(string(endPointDetails.qosdurability));

                    % Assigning Inf if value is more than or equal to Inf
                    if round(endPointDetails.qosdeadline,4) >= obj.InfiniteValue
                        endPointDetails.qosdeadline = Inf;
                    end
                    qosDeadLine = string(endPointDetails.qosdeadline);

                    % Assigning Inf if value is more than or equal to Inf
                    if round(endPointDetails.qoslifespan,4) >= obj.InfiniteValue
                        endPointDetails.qoslifespan = Inf;
                    end
                    qosLifespan = string(endPointDetails.qoslifespan);
                    qosLiveliness = lower(string(endPointDetails.qosliveliness));

                    % Assigning Inf if value is more than or equal to Inf
                    if round(endPointDetails.qosleaseduration,4) >= obj.InfiniteValue
                        endPointDetails.qosleaseduration = Inf;
                    end
                    qosLeaseDuration = string(endPointDetails.qosleaseduration);
                    
                    tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyConnectionType'))); string(getString(message('ros:rosgraphapp:view:PropertyTopicName'))); ...
                                string(getString(message('ros:rosgraphapp:view:PropertyNodeName'))); string(getString(message('ros:rosgraphapp:view:PropertyQOSHistory'))); ... 
                                string(getString(message('ros:rosgraphapp:view:PropertyQOSDepth')));...
                                string(getString(message('ros:rosgraphapp:view:PropertyQOSReliability'))); string(getString(message('ros:rosgraphapp:view:PropertyQOSDurability')));...
                                string(getString(message('ros:rosgraphapp:view:PropertyQOSDeadline')));  string(getString(message('ros:rosgraphapp:view:PropertyQOSLifespan')));  ...
                                string(getString(message('ros:rosgraphapp:view:PropertyQOSLiveliness'))); string(getString(message('ros:rosgraphapp:view:PropertyQOSLeaseDuration')))];
                    values =  [topicEdgeType;     topicName; nodeName;  qosHistory; qosDepth; qosReliability; qosDurability; qosDeadLine; qosLifespan; qosLiveliness; qosLeaseDuration];
                    obj.View.updatePropertyView(tblKeys,values)
                elseif startsWith(type, 'edge_')
                    tblKeys = ["Source";"Target"];
                    values = [string(event.HTMLEventData.source);string(event.HTMLEventData.target)];
                    obj.View.updatePropertyView(tblKeys,values)
                end
            elseif strcmp(event.HTMLEventData.event,'graphLoded')
                obj.View.graphDisplayedOnUI;
            elseif strcmp(event.HTMLEventData.event,'HTMLPageLoaded')
                    obj.View.setMATLABTheme;
            % advancedFiltering event is sent by JS when user clicks on
            % filter, Network Depth or clear filters buttons. This event
            % also comes with query
            elseif strcmp(event.HTMLEventData.event,'advancedFiltering')
                obj.Query = rmfield(event.HTMLEventData,'event');
                obj.refresh(objWeakHndl,"filter",[])
            elseif strcmp(event.HTMLEventData.event,'depthChanged')
                % Not required to do any change in graph if no filtering
                % has been done before and only depth is changed
                if isempty(obj.Query)
                    return;
                end
                obj.Query.depth = event.HTMLEventData.depth;
                obj.refresh(objWeakHndl,"updateDepth",[])
            elseif strcmp(event.HTMLEventData.event,'clearFilter')
                % Not required to do any change in graph if no filtering
                % has been done before and only depth is changed
                if isempty(obj.Query)
                    return;
                end
                obj.Query = rmfield(event.HTMLEventData,'event');
                obj.refresh(objWeakHndl,"clearFilter",[])
                obj.Query = [];
            else
                tblKeys = [string(getString(message('ros:rosgraphapp:view:PropertyDomainId'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfNodes'))); ...
                            string(getString(message('ros:rosgraphapp:view:PropertyNumberOfTopics'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfServices'))); ...
                            string(getString(message('ros:rosgraphapp:view:PropertyNumberOfActions')))];
                values = [string(obj.Graph.getDomainId); string(numel(obj.Graph.Nodes.name)); string(numel(obj.Graph.Topics.name)); string(numel(obj.Graph.Services.name)); string(numel(obj.Graph.Actions.name))];
                obj.View.updatePropertyView(tblKeys,values)
            end
        

        end

        function rosNetworkDetailsEntered(objWeakHndl, ~, ~,domainId)

           obj = objWeakHndl.get;
           if ~isempty(domainId)
               % Loading progress bar when network details are entered
               obj.View.displayProgressDlg(domainId);
               % Initializing PreviousNamespace and MaxNameSpace. It is required to update these
               % values as addition or removal of nodes will change these
               % values
               obj.PreviousNamespace = -2;
               obj.View.initializeNameSpace();
               obj.Graph.updateDomainId(domainId)
               obj.Graph.applyFilter( ...
                           obj.View.getDefaultTopicvisibility, ...
                           obj.View.getDefaultServicevisibility, ...
                           obj.View.getActionTopicServicevisibility, ...
                           obj.Query)
               obj.View.createRosGraph(obj.Graph,obj.View.getSelectedLayout,obj.View.getNameSpaceLavel);
               keys = [string(getString(message('ros:rosgraphapp:view:PropertyDomainId'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfNodes'))); ...
                       string(getString(message('ros:rosgraphapp:view:PropertyNumberOfTopics'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfServices'))); ... 
                       string(getString(message('ros:rosgraphapp:view:PropertyNumberOfActions')))];
               values = [string(obj.Graph.getDomainId); string(numel(obj.Graph.Nodes.name)); string(numel(obj.Graph.Topics.name)); string(numel(obj.Graph.Services.name)); string(numel(obj.Graph.Actions.name))];
               obj.View.updatePropertyView(keys,values)
               
               obj.View.buildNetworkTree(obj.View.getCurrentGraphElements,true);
               obj.View.updateDomainIdInStatusBar(domainId);
               obj.View.updateTimeStampInStatusBar(string(datetime('now')));
               
           end   
        end

        function layoutSelectionChanged(objWeakHndl, ~, event)
            
            obj = objWeakHndl.get;

            obj.View.autoArrangeRosGraph(event.EventData.NewValue);
        end
        
        function refresh(objWeakHndl,src, event)
            
            obj = objWeakHndl.get;
            if ~isempty(obj.Graph)
                % Loading progress bar when refresh button is pressed
                if isequal(src, "filter")
                    % Invoking progress bar with text for filtering data.
                    obj.View.displayProgressDlg(-1);
                elseif isequal(src, "updateDepth")
                    % Invoking progress bar with text for updating network depth.
                    obj.View.displayProgressDlg(-2);
                    % Random rapid clicking of network depth number spinner
                    % causes loading of graph to fail, hence adding a pause to
                    % prevent user from rapid clicking of network depth number
                    % spinner
                    pause(0.5)
                    % Change src to filter rest behavior is expected to be
                    % same as that of filter
                    src = "filter";
                elseif isequal(src, "clearFilter")
                    % Invoking progress bar with text for clear filters.
                    obj.View.displayProgressDlg(-3);
                    % Change src to filter rest behavior is expected to be
                    % same as that of filter
                    src = "filter";
                else
                    obj.View.displayProgressDlg;
                end
                % Initializing namespaces. It is required to update these
                % values as addition or removal of nodes will change these
                % values
                obj.PreviousNamespace = -2;
                obj.View.initializeNameSpace();
                if ~(isempty(src) && isempty(event)) && ~isequal(src, "filter")
                    %If this function is not called from filter and called
                    %from refresh button, this function will be called
                    obj.Graph.fetchLatestNetworkInfo
                end

                obj.Graph.applyFilter( ...
                                obj.View.getDefaultTopicvisibility, ...
                                obj.View.getDefaultServicevisibility, ...
                                obj.View.getActionTopicServicevisibility, ...
                                obj.Query)
                
                obj.View.createRosGraph(obj.Graph,obj.View.getSelectedLayout,obj.View.getNameSpaceLavel);

                keys = [string(getString(message('ros:rosgraphapp:view:PropertyDomainId'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfNodes'))); ...
                        string(getString(message('ros:rosgraphapp:view:PropertyNumberOfTopics'))); string(getString(message('ros:rosgraphapp:view:PropertyNumberOfServices'))); ...
                        string(getString(message('ros:rosgraphapp:view:PropertyNumberOfActions')))];
                values = [string(obj.Graph.getDomainId); string(numel(obj.Graph.Nodes.name)); string(numel(obj.Graph.Topics.name)); string(numel(obj.Graph.Services.name)); string(numel(obj.Graph.Actions.name))];
                obj.View.updatePropertyView(keys,values)
                
                obj.View.buildNetworkTree(obj.View.getCurrentGraphElements,true);
                
                obj.View.updateTimeStampInStatusBar(string(datetime('now')));
            end
        end

        function filter(objWeakHndl,src, ~)
            
            obj = objWeakHndl.get;

            if strcmp(src.Text, getString(message('ros:rosgraphapp:view:TextDeadSinkChkBox')))
                obj.View.setDeadSinkVisibility(src.Selected);
            elseif strcmp(src.Text, getString(message('ros:rosgraphapp:view:TextLeafTopicChkBox')))
                obj.View.setLeafTopicVisibility(src.Selected);
            elseif strcmp(src.Text, getString(message('ros:rosgraphapp:view:TextUnreachableChkBox')))
                obj.View.setUnreachableVisibility(src.Selected);
            else
                obj.refresh(objWeakHndl,"filter",[])
            end
        end

        function toggleFilters(objWeakHndl,~, event)
            obj = objWeakHndl.get;
            obj.View.toggleAdvancedFilters(event.EventData.NewValue);
        end

        function export(objWeakHndl,~, ~)

            obj = objWeakHndl.get;
            
            obj.View.exportRosGraphAsImage();
        end

        function autoArrange(objWeakHndl,~, ~)

            obj = objWeakHndl.get;
            
            obj.View.autoArrangeRosGraph(obj.View.getSelectedLayout);
        end
    end
end

% LocalWords:  rosnode Svc Chk