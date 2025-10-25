classdef NetworkTreeViewer < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.
    
    properties(Access = {?matlab.unittest.TestCase, ?ros.internal.rosgraph.view.AppView})

        NetworkBrowserPanel
        NetworkTree
        
        NodeList
        TopicList
        ServiceList
        ActionList

        NetworkTreeElementSelectCallback = function_handle.empty
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)

        %% Tags
        TagNetworkBrowser = "NetworkBrowser"
        TagNodeList ="Nodes"
        TagTopicList ="Topics"
        TagServiceList ="Services"
        TagActionList ="Actions"
        %% Catalogs
        TitleNetworkBrowser = getString(message("ros:rosgraphapp:view:TitleNetworkBrowserPnl"))
        TextNodeList = getString(message("ros:rosgraphapp:view:TextNodeListTreeView"))
        TextTopicList = getString(message("ros:rosgraphapp:view:TextTopicListTreeView"))
        TextServiceList = getString(message("ros:rosgraphapp:view:TextServiceListTreeView"))
        TextActionList = getString(message("ros:rosgraphapp:view:TextActionListTreeView"))
    end

    methods
        function obj = NetworkTreeViewer(appContainer)
            
           createNetworkElementTreeUI(obj,appContainer)
           obj.NetworkTree.Visible = matlab.lang.OnOffSwitchState.off;
        end
        
        function createNetworkElementTreeUI(obj, appContainer)
            
            networkBrowserOptions.Title = obj.TitleNetworkBrowser;
            networkBrowserOptions.Region = "left";
            networkBrowserOptions.Tag = obj.TagNetworkBrowser;
            obj.NetworkBrowserPanel = matlab.ui.internal.FigurePanel(networkBrowserOptions);
            appContainer.add(obj.NetworkBrowserPanel);
            % Creating grid layout to make Network browser panel responsive
            gridLayout = uigridlayout(obj.NetworkBrowserPanel.Figure);
            gridLayout.ColumnWidth = {'1x'};
            gridLayout.RowHeight = {'1x'};
            obj.NetworkTree = uitree(gridLayout, 'checkbox');

            obj.NetworkTree.CheckedNodesChangedFcn = ...
                @(src, event) makeCallback(obj.NetworkTreeElementSelectCallback, src, event);
            obj.NodeList = uitreenode(obj.NetworkTree, 'Text', obj.TextNodeList);
            obj.TopicList = uitreenode(obj.NetworkTree, 'Text', obj.TextTopicList);
            obj.ServiceList = uitreenode(obj.NetworkTree, 'Text', obj.TextServiceList);
            obj.ActionList = uitreenode(obj.NetworkTree, 'Text', obj.TextActionList);

            % Add icons
            matlab.ui.control.internal.specifyIconID(obj.NodeList, 'nodeEllipseBlue', 24);
            matlab.ui.control.internal.specifyIconID(obj.TopicList, 'nodeRectangleYellow', 24);
            matlab.ui.control.internal.specifyIconID(obj.ServiceList, 'nodeOblongGreen', 24);
            matlab.ui.control.internal.specifyIconID(obj.ActionList, 'nodeOctagonPurple', 24);

            obj.NetworkTree.CheckedNodes = [obj.NodeList, obj.TopicList, obj.ServiceList, obj.ActionList];
        end

        function buildNetworkTree(obj, currentGraphElements, restTree)

            if restTree
                 resetUITree(obj)
            end
            obj.NetworkTree.Visible = matlab.lang.OnOffSwitchState.on;
            if ~isempty(obj.NetworkTree)
                graphElements = currentGraphElements.keys;
                for idx=1:numel(graphElements)
                    element = graphElements{idx};
                    elementType = currentGraphElements(element);
                    if strcmp(elementType,'rosnode')
                        uitreenode(obj.NodeList, 'Text', element, 'NodeData', 'ros-node','Tag',obj.TagNodeList);
                    elseif strcmp(elementType,'topic')
                        uitreenode(obj.TopicList, 'Text', element, 'NodeData', 'ros-topic','Tag',obj.TagTopicList);
                    elseif strcmp(elementType,'service_child')
                        uitreenode(obj.ServiceList, 'Text', element, 'NodeData', 'ros-service','Tag',obj.TagServiceList);
                    elseif strcmp(elementType,'action_child')
                        uitreenode(obj.ActionList, 'Text', element, 'NodeData', 'ros-action','Tag',obj.TagActionList);
                    end
                end
            end
            obj.NodeList.Text = [obj.NodeList.Text '(' num2str(numel(obj.NodeList.Children)) ')'];
            obj.TopicList.Text = [obj.TopicList.Text '(' num2str(numel(obj.TopicList.Children)) ')'];
            obj.ServiceList.Text = [obj.ServiceList.Text '(' num2str(numel(obj.ServiceList.Children)) ')'];
            obj.ActionList.Text = [obj.ActionList.Text '(' num2str(numel(obj.ActionList.Children)) ')'];

        end

         function resetUITree(obj)

             % DELETE ALL THE LEVEL-2 NODES FROM THE UI TREE
             delete(obj.NodeList);
             obj.NodeList = uitreenode(obj.NetworkTree, 'Text', obj.TextNodeList);
             
             delete(obj.TopicList);
             obj.TopicList = uitreenode(obj.NetworkTree, 'Text', obj.TextTopicList);

             delete(obj.ServiceList);
             obj.ServiceList = uitreenode(obj.NetworkTree, 'Text', obj.TextServiceList);           
            
             delete(obj.ActionList);
             obj.ActionList = uitreenode(obj.NetworkTree, 'Text', obj.TextActionList);
         
             % Add icons
             matlab.ui.control.internal.specifyIconID(obj.NodeList, 'nodeEllipseBlue', 24);
             matlab.ui.control.internal.specifyIconID(obj.TopicList, 'nodeRectangleYellow', 24);
             matlab.ui.control.internal.specifyIconID(obj.ServiceList, 'nodeOblongGreen', 24);
             matlab.ui.control.internal.specifyIconID(obj.ActionList, 'nodeOctagonPurple', 24);

             obj.NetworkTree.CheckedNodes = [obj.NodeList, obj.TopicList, obj.ServiceList, obj.ActionList];
        end
    end
        
end

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

    if ~isempty(fcn)
        feval(fcn, varargin{:})
    end
end