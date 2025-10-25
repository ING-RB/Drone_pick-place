classdef AppView < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.
    
    properties
        AppContainer

        RosGraphViewerObj
        ToolStripViewerObj
        NetworkTreeViewerObj
        PropertyViewerObj
        StatusBarViewerObj
        ProgressDlgObj
        Context
    end

    properties(Constant)

        %% Callbacks
        JSToMatlabCallback = 1
        RosNetworkDetailsEntered = 2
        ArrangeButtonCallback = 3
        RefreshButtonCallback = 4
        FilterSettingsChangedCallback = 5
        LayoutChangedCallback = 6
        ExportButtonCallback = 7
        NetworkTreeElementSelectCallback = 8
        NameSpacelLevelChangedCallback = 9
        AdvancedFilterCallback = 10
        CloseAppCallback = 11
        DeleteProgressDlgCallback = 12

        %% Tags
        TagAppContainer = "ROS2NetworkVisualizerApp"

        %% Catalogs
        TitleAppContainer = getString(message("ros:rosgraphapp:view:Ros2NetworkAnalyzerAppTitle"))
    end

    methods
        function obj = AppView()
            % Checkout ROS Toolbox License
            ros.internal.utilities.checkoutROSToolboxLicense();
            
            obj.createAppContainer;
            obj.ToolStripViewerObj = ros.internal.rosgraph.view.ToolStripViewer(obj.AppContainer);
            obj.NetworkTreeViewerObj = ros.internal.rosgraph.view.NetworkTreeViewer(obj.AppContainer);
            obj.PropertyViewerObj = ros.internal.rosgraph.view.PropertyViewer(obj.AppContainer);
            obj.RosGraphViewerObj = ros.internal.rosgraph.view.RosGraphViewer(obj.AppContainer);
            obj.StatusBarViewerObj = ros.internal.rosgraph.view.StatusBarViewer(obj.AppContainer);
            obj.ToolStripViewerObj.deactivateElements;
            obj.displayApp;
        end
        
        function createAppContainer(obj)
            
            appOptions = struct;

            % Construct the app
            appOptions.Tag = obj.TagAppContainer;
            appOptions.Title = obj.TitleAppContainer;
            appOptions.EnableTheming = true;
            obj.AppContainer = matlab.ui.container.internal.AppContainer(appOptions);
        end

        function displayApp(obj)
            obj.AppContainer.Visible = true;
            bringToFront(obj.AppContainer);
        end

        function setContext(obj, context)
            obj.Context = context;
        end

        function registerCallback(obj,callBackName, hFcn)
            switch callBackName
                case ros.internal.rosgraph.view.AppView.JSToMatlabCallback
                    obj.RosGraphViewerObj.JSToMatlabCallback = hFcn;    
                case ros.internal.rosgraph.view.AppView.RosNetworkDetailsEntered
                    obj.ToolStripViewerObj.RosNetworkDetailsEntered = hFcn;
                case ros.internal.rosgraph.view.AppView.ArrangeButtonCallback
                    obj.ToolStripViewerObj.ArrangeButtonCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.RefreshButtonCallback
                    obj.ToolStripViewerObj.RefreshButtonCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.FilterSettingsChangedCallback
                    obj.ToolStripViewerObj.FilterSettingsChangedCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.LayoutChangedCallback
                    obj.ToolStripViewerObj.LayoutChangedCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.ExportButtonCallback
                    obj.ToolStripViewerObj.ExportButtonCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.NameSpacelLevelChangedCallback
                    obj.ToolStripViewerObj.NameSpaceLevelChangedCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.AdvancedFilterCallback
                    obj.ToolStripViewerObj.AdvancedFilterCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.NetworkTreeElementSelectCallback
                    obj.NetworkTreeViewerObj.NetworkTreeElementSelectCallback = hFcn;
                case ros.internal.rosgraph.view.AppView.CloseAppCallback
                    obj.AppContainer.CanCloseFcn = hFcn;
                case ros.internal.rosgraph.view.AppView.DeleteProgressDlgCallback
                    obj.ToolStripViewerObj.DeleteProgressDlgCallback = hFcn;
            end
        end
        
        % getMaxNameSpace gets MaxNameSpace from RosGraphViewerObj
        function maxNameSpace = getMaxNameSpace(obj)
            maxNameSpace = obj.RosGraphViewerObj.getMaxNameSpace();
        end
        
        % initializeNameSpace initializes MaxNameSpace of RosGraphViewerObj
        function initializeNameSpace(obj)
            obj.RosGraphViewerObj.initializeNamespace();
        end

        function showRosGraphElement(obj, eId)
            obj.RosGraphViewerObj.showElement(eId)
        end

        function hideRosGraphElement(obj, eId)
            obj.RosGraphViewerObj.hideElement(eId)
        end

        function updatePropertyView(obj,keys,values)
            if ~isempty(obj.PropertyViewerObj) && isvalid(obj.PropertyViewerObj)
                obj.PropertyViewerObj.update(keys,values)
            end
        end

        function visibility = getDefaultTopicvisibility(obj)
            visibility = obj.ToolStripViewerObj.getDefaultTopicvisibility;
        end

        function visibility = getDefaultServicevisibility(obj)
            visibility = obj.ToolStripViewerObj.getDefaultServicevisibility;
        end

        function visibility = getActionTopicServicevisibility(obj)
            visibility = obj.ToolStripViewerObj.getActionTopicServicevisibility;
        end
        
        function createRosGraph(obj,graph,layout,nameSpaceLevel)

            obj.ToolStripViewerObj.deactivateElements;
            obj.RosGraphViewerObj.createGraph(graph,layout,nameSpaceLevel);
            obj.ToolStripViewerObj.graphLoaded(graph);
        end

        function graphDisplayedOnUI(obj)
            obj.deleteProgressDlg;
            obj.ToolStripViewerObj.activateElements;
        end
        
        function layout = getSelectedLayout(obj)
            layout = obj.ToolStripViewerObj.getSelectedLayout;
        end

        function buildNetworkTree(obj,graph, restTree)
            obj.NetworkTreeViewerObj.buildNetworkTree(graph,restTree);
        end

        function updateDomainIdInStatusBar(obj,domainId)
            obj.StatusBarViewerObj.updateDomainId(string(domainId));
        end

        function updateTimeStampInStatusBar(obj,timeStamp)
            obj.StatusBarViewerObj.updateLastRefrestedTime(timeStamp);
        end

        function autoArrangeRosGraph(obj, layout)
            obj.RosGraphViewerObj.autoArrangeGraph(layout);
        end

        function setDeadSinkVisibility(obj,val)
            obj.RosGraphViewerObj.showDeadSink(val);
        end

        function setLeafTopicVisibility(obj,val)
            obj.RosGraphViewerObj.showLeafTopic(val);
        end

        function setUnreachableVisibility(obj,val)
            obj.RosGraphViewerObj.showUnreachable(val);
        end

        function exportRosGraphAsImage(obj)
            obj.RosGraphViewerObj.exportGraph();
        end

        function toggleAdvancedFilters(obj, visiblity)
            obj.RosGraphViewerObj.toggleAdvancedFilters(visiblity);
        end
        
        function setMATLABTheme(obj)
            obj.RosGraphViewerObj.setMATLABTheme();
        end

        function val = getNameSpaceLavel(obj)
            val = obj.ToolStripViewerObj.getNameSpaceLavel;
        end

        function val = getSelectedElementsForConnection(obj)
            val = obj.ToolStripViewerObj.getSelectedElementsForConnection;
        end

        function findConnection(obj, elements)
            obj.RosGraphViewerObj.findConnection(elements);
        end

        function query = getKeyWordFilterQuery(obj)
            query = obj.ToolStripViewerObj.getKeyWordFilterQuery;
        end

        function elements = getCurrentGraphElements(obj)
            elements = obj.RosGraphViewerObj.getCurrentGraphElements;
        end

        function displayProgressDlg(obj, varargin)
            if nargin == 2
                domainId = varargin{1};
            else
                domainId  = obj.Context.Graph.getDomainId;
            end
            % ROS 2 Network cannot have domain ID as -1, so value -1 for
            % domain ID will be used to invoke filter text.
            if domainId == -1
                obj.ProgressDlgObj = uiprogressdlg(obj.AppContainer, 'Indeterminate', 'on', ...
                    'Message',getString(message('ros:rosgraphapp:view:FilterGraph')));
            % ROS 2 Network cannot have domain ID as -2, so value -2 for
            % domain ID will be used to invoke update network depth text.
            elseif domainId == -2
                obj.ProgressDlgObj = uiprogressdlg(obj.AppContainer, 'Indeterminate', 'on', ...
                    'Message',getString(message('ros:rosgraphapp:view:UpdateNetworkDepth')));
            % ROS 2 Network cannot have domain ID as -3, so value -3 for
            % domain ID will be used to invoke clear filters text.
            elseif domainId == -3
                obj.ProgressDlgObj = uiprogressdlg(obj.AppContainer, 'Indeterminate', 'on', ...
                    'Message',getString(message('ros:rosgraphapp:view:ClearFilters')));
            else
                obj.ProgressDlgObj = uiprogressdlg(obj.AppContainer, 'Indeterminate', 'on', ...
                    'Message',getString(message('ros:rosgraphapp:view:LoadGraph',domainId)));
            end
			%store the progress bar dialog handle to the app container for testing purpose
			appDocument = obj.AppContainer.getDocument("NetworkGraphDocGroup","ROS2NetworkGraphViewer");
            setappdata(appDocument.Figure,'ProgressBarHandle',obj.ProgressDlgObj);
        end
        
        % function to delete the progress bar when the graph is loaded.
        function deleteProgressDlg(obj)
            if ~isempty(obj.ProgressDlgObj)
                delete(obj.ProgressDlgObj);
                obj.ProgressDlgObj = [];
            end
        end
    end
end

