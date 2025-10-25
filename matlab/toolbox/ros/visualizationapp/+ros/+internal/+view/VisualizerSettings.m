classdef VisualizerSettings < handle
    %This class is for internal use only. It may be removed in the future.

    % VisualizerSettings Class for configuring visualizer settings within
    % the rosDataAnalyzer app.
    %
    % This class is designed for internal use within the rosDataAnalyzer
    % provides a user interface for adjusting visualizer settings. It
    % encapsulates the UI components and logic necessary to allow users to
    % customize how data is visualized within the app.
    %
    % Usage:
    %   obj = ros.internal.view.VisualizerSettings(appContainer)
    %

    % Copyright 2024 The MathWorks, Inc.
    properties
        % UI Widgets

        % VisualizerSettingsPanel: A figure panel that acts as a container
        % for the visualizer settings UI.
        VisualizerSettingsPanel

        % GridLayout: A grid layout manager for arranging UIcomponents
        % within the VisualizerSettingsPanel.
        GridLayout

        % DataSourceTree: A UI tree component that displays the hierarchy
        % or structure of data sources.
        DataSourceTree

        % DataSourceTreeRootNode: The root node of the DataSourceTree.
        DataSourceTreeRootNode

        % FrameIDLabel: A UI label that displays text indicating the purpose of the FrameIDDropdown.
        FrameIDLabel

        % FrameIDDropdown: A dropdown to select from a list of frame IDs.
        FrameIDDropdown
    end

    properties
        % DataSourceNodesCheckedFcn: A function handle to callback function
        % that is triggered when the checkbox state of any node
        % in the DataSourceTree changes.
        DataSourceNodesCheckedFcn = function_handle.empty;

        % FrameIDValueChangedFcn: A function handle to callback function
        % that is triggered when the selected value in FrameIDDropdown
        % changes.
        FrameIDValueChangedFcn = function_handle.empty;
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI components

        TagVisualizerSettingsPanel = 'RosbagViewerVisualizerSettingsPanelTag';
        TagGridLayout = 'VisualizerSettingsPanelGridLayoutTag';
        TagDataSourceTree = 'VisualizerSettingsPanelDataSourceTreeTag';
        TagDataSourceTreeRootNode = 'VisualizerSettingsPanelDataSourceTreeRootNodeTag';
        TagFrameIDLabel = 'VisualizerSettingsPanelFrameIDLabelTag';
        TagFrameIDDropdown = 'VisualizerSettingsPanelFrameIDDropdownTag';
    end

    methods
        function obj = VisualizerSettings(appContainer)
            %VisualizerSettings Construct the VisualizerSettings panel

            buildVisualizerSettingsPanel(obj);
            add(appContainer, obj.VisualizerSettingsPanel);
        end

        function set.DataSourceNodesCheckedFcn(obj, val)
            % Setter method for DataSourceNodesCheckedFcn property.

            obj.DataSourceNodesCheckedFcn = validateCallback(val, ...
                "DataSourceNodesCheckedFcn");
        end

        function set.FrameIDValueChangedFcn(obj, val)
            % Setter method for FrameIdDropdownValueChangedFcn property.

            obj.FrameIDValueChangedFcn = validateCallback(val, ...
                "FrameIdDropdownValueChangedFcn");
        end
    end

    methods (Access = protected)
        function buildVisualizerSettingsPanel(obj)
            %buildVisualizerSettingsPanel Create topic panel and
            % initialize contents

            panelOptions = struct("Title", getString(message("ros:visualizationapp:view:VisualizerSettingsTitle")), ...
                "Region", "right", ...
                "Tag", obj.TagVisualizerSettingsPanel);
            obj.VisualizerSettingsPanel = matlab.ui.internal.FigurePanel(panelOptions);
            windowbounds = ros.internal.utils.getWindowBounds;
            obj.VisualizerSettingsPanel.PreferredWidth = windowbounds(3)/4.5;

            % Setup grid layout
            obj.GridLayout = uigridlayout(obj.VisualizerSettingsPanel.Figure, ...
                "Tag", obj.TagGridLayout, ...
                "Scrollable", "on");
            obj.GridLayout.RowHeight = {'fit', 24}; % Adjust row height
            obj.GridLayout.ColumnWidth = {'fit', 'fit'};

            % Add a uitree with checkboxes as nodes
            obj.DataSourceTree = uitree(obj.GridLayout, ...
                'checkbox', ...
                "Tag", obj.TagDataSourceTree);
            obj.DataSourceTree.Layout.Row = 1; % Position in the first row of the grid layout
            obj.DataSourceTree.Layout.Column = [1 2];
            obj.DataSourceTreeRootNode = uitreenode(obj.DataSourceTree, ...
                'Text', getString(message("ros:visualizationapp:view:DataSourceLabel")), ...
                "Tag", obj.TagDataSourceTreeRootNode);
            obj.DataSourceTree.CheckedNodesChangedFcn  = ...
                @(source, event) makeCallback(obj.DataSourceNodesCheckedFcn, source, event);

            % Add a dropdown with a label
            % Label for the Frame ID dropdown
            obj.FrameIDLabel = uilabel(obj.GridLayout, ...
                'Text', getString(message("ros:visualizationapp:view:FrameIdLabel")),...
                "Tag", obj.TagFrameIDDropdown);
            obj.FrameIDLabel.Layout.Row = 2; % Position in the first row of the container
            obj.FrameIDLabel.Layout.Column = 1;

            % Dropdown for FrameID
            obj.FrameIDDropdown = uidropdown(obj.GridLayout, ...
                "Tag", obj.TagFrameIDDropdown);
            obj.FrameIDDropdown.Items = {'map'};
            obj.FrameIDDropdown.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.FrameIDValueChangedFcn, source, event);
            obj.FrameIDDropdown.Layout.Row = 2; % Position in the second row of the container
            obj.FrameIDDropdown.Layout.Column = 2;
        end
    end
    methods(Access = public)
        function node = updateDataSource(obj, topics)
            % addTreeNode dynamically add a new node under the specified
            % parent node
            % nodeText: The text displayed for the new node
            obj.resetDataSourceTreeRoot();
            for indx =1:numel(topics)
                node = uitreenode(obj.DataSourceTreeRootNode, 'Text', topics{indx});
            end
            obj.DataSourceTreeRootNode.expand();
        end

        function addItemsToFrameIdDropdown(obj, items)
            % addTreeNode dynamically add a new node under the specified
            % parent node
            % nodeText: The text displayed for the new node

            obj.FrameIDDropdown.Items = items;
        end

        function resetDataSourceTreeRoot(obj)
            while ~isempty(obj.DataSourceTreeRootNode.Children)
                obj.DataSourceTreeRootNode.Children(end).delete;
            end
            obj.DataSourceTreeRootNode.Parent.CheckedNodes = [];
        end

        function updateFrameIdDropdown(obj, items)

            if isempty(items)
                return;
            end
            obj.FrameIDDropdown.Items = items;

        end

        function updateFrameIdValue(obj, newFrameId)
            obj.FrameIDDropdown.Value = newFrameId;
        end

        function checkSpecificNodesByText(obj, textToCheck)
            % Ensure textToCheck is a cell array, even if a single string is provided
            if ~iscell(textToCheck)
                textToCheck = {textToCheck};
            end
            % First, uncheck all nodes
            obj.DataSourceTree.CheckedNodes = [];

            nodesToCheck = [];
            for k = 1:length(obj.DataSourceTreeRootNode.Children)
                currentNode = obj.DataSourceTreeRootNode.Children(k);
                % If the current node's text is in the list of labels to check, add it to the array
                % Here, we use any() combined with strcmp() to check against each item in textToCheck
                if any(strcmp(currentNode.Text, textToCheck))
                    nodesToCheck = [nodesToCheck, currentNode];
                end
            end
            % Set the collected nodes as checked
            obj.DataSourceTree.CheckedNodes = nodesToCheck;
        end

        function reinit(obj)
            obj.DataSourceTreeRootNode.Parent.CheckedNodes = [];
            obj.FrameIDDropdown.Items = {'map'};
        end
    end %END Protected method
end % END of Class

%% Helper functions that have no need for class access

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

if ~isempty(fcn)
    feval(fcn, varargin{:})
end
end

function fHandle = validateCallback(fHandle, propertyName)
%validateCallback Ensure callback has correct type

% Accept any empty type to indicate no callback
if isempty(fHandle)
    fHandle = function_handle.empty;
else
    validateattributes(fHandle, ...
        "function_handle", ...
        "scalar", ...
        "ViewerVisualizerSettings", ...
        propertyName)
end
end