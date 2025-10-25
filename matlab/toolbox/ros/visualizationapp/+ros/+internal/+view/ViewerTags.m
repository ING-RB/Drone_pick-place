classdef ViewerTags < handle
    %This class is for internal use only. It may be removed in the future.

    %ViewerTags Rosbag tags contents UI for the Rosbag Viewer app
    %   tags = ros.internal.ViewerTags(APPCONTAINER)
    %      Create the panel for adding tags

    %   Copyright 2023 The MathWorks, Inc.

    % UI objects
    properties
        % Figure panel containing all topic details
        TagsPanel
        GridLayout
        TagDescriptionHandle
        TagLabelHandle
        TagEditFieldHandle
        TagsGridContainer

        AppContainerWeakHndl

        TagsHandleTab
    end

    properties
        TagEditFieldCallback = function_handle.empty
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        TagsPanelTag = 'RosbagViewerTagsPanel'
    end

    methods
        function obj = ViewerTags(appContainer)
            %ViewerBookmark Construct a topic list panel on the provided app
            obj.AppContainerWeakHndl = matlab.internal.WeakHandle(appContainer);
        end

        function setAppMode(obj, appMode)
            appContainer = obj.AppContainerWeakHndl.get;
            if appMode == ros.internal.ViewerPresenter.RosbagVisualization
                if isempty(obj.TagsPanel) || ~isvalid(obj.TagsPanel)
                    buildTagsPanel(obj);
                    add(appContainer, obj.TagsPanel);
                end
            elseif ~isempty(obj.TagsPanel) && isvalid(obj.TagsPanel)
                removePanel(appContainer, obj.TagsPanel.Tag);
            end
        end

        function createTagComponent(obj, newVal)
            hndle = ros.internal.view.widget.TagComponent(obj.TagsGridContainer);
            hndle.Value = newVal;
            hndle.DeleteButtonClickedFcn = @(source, event) deleteTagCallback(obj, source, event);
            obj.appendToTagsTable(newVal, hndle);
            if any(strcmp(obj.TagsHandleTab.Properties.VariableNames, {'Var1', 'Var2'}))
                obj.TagsHandleTab.Properties.VariableNames = ["TagValue", "TagComponentHandle"];
            end
        end

        function resetTagPanel(obj)
            obj.TagEditFieldHandle.Value = '';
            if isempty(obj.TagsHandleTab)
                return;
            end
            nTags = numel(obj.TagsHandleTab.TagValue);
            for indx=1:nTags
                obj.TagsHandleTab.TagComponentHandle(1).delete;
                obj.deleteFromTagsTable(1);
            end
        end
    end

    methods
        % All callback properties validate and set the same way
        function set.TagEditFieldCallback(obj, val)
            obj.TagEditFieldCallback = validateCallback(val, "TagEditFieldCallback");
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function deleteTagCallback(obj, source, event)
            %deleteTagCallback callback for the delete button click in the
            %tag component
            
            %find the index of the source in the list
            index = [];
            for i = 1:numel(obj.TagsHandleTab.TagComponentHandle)
                if isequal(obj.TagsHandleTab.TagComponentHandle(i), source)
                    index = [index, i]; %#ok<AGROW>
                end
            end
            
            % get parent
            layout = source.Parent;
            
            % delete the source
            obj.deleteFromTagsTable(index);
            source.delete();

            %get new list of children
            children = layout.Children;
            
            % Calculate the new number of rows and columns
            numWidgets = numel(children);
            numCols = 4; % Number of columns in the grid
            numRows = ceil(numWidgets / numCols);

            % Update the layout size
            layout.RowHeight = repmat({'fit'}, 1, numRows);
            layout.ColumnWidth = repmat({'fit'}, 1, numCols);

            % Rearrange the widgets in the grid
            for i = 1:numWidgets
                [row, col] = ind2sub([numRows, numCols], i);
                layout.Children(i).Layout.Row = row;
                layout.Children(i).Layout.Column = col;
            end
        end
    end

    methods (Access = protected)

        function buildTagsPanel(obj)
            %buildTagsPanel Create topic panel and initialize contents

            % Add the topic tree panel to the left
            panelOptions = struct("Title", getString(message("ros:visualizationapp:view:TagsLabel")), ...
                "Region", "right" );
            obj.TagsPanel = matlab.ui.internal.FigurePanel(panelOptions);
            obj.TagsPanel.Closable = false;
            windowbounds = ros.internal.utils.getWindowBounds;
            obj.TagsPanel.PreferredWidth = windowbounds(3)/4.5;
            obj.TagsPanel.Tag = obj.TagsPanelTag;

            % Setup grid layout
            obj.GridLayout = uigridlayout(obj.TagsPanel.Figure, [1 1]);
            obj.GridLayout.RowHeight = {'fit', 'fit' 'fit'};
            obj.GridLayout.ColumnWidth = {'fit', '1x', 23};
            obj.GridLayout.Padding = [5 5 5 5];
            obj.GridLayout.Scrollable = matlab.lang.OnOffSwitchState.on;

            % Description
            obj.TagDescriptionHandle = uilabel(obj.GridLayout);
            obj.TagDescriptionHandle.Layout.Row = 1;
            obj.TagDescriptionHandle.Layout.Column = [1 3];
            obj.TagDescriptionHandle.Text = getString(message("ros:visualizationapp:view:AddTagTooltip"));

            % Add Tag Label
            obj.TagLabelHandle = uilabel(obj.GridLayout);
            obj.TagLabelHandle.Layout.Row = 2;
            obj.TagLabelHandle.Layout.Column = 1;
            obj.TagLabelHandle.Text = getString(message("ros:visualizationapp:view:AddTagPanel"));

            % Add Tag Edit field
            obj.TagEditFieldHandle =  uieditfield(obj.GridLayout);
            obj.TagEditFieldHandle.Layout.Row = 2;
            obj.TagEditFieldHandle.Layout.Column = 2;
            obj.TagEditFieldHandle.Placeholder = getString(message("ros:visualizationapp:view:EnterText"));
            obj.TagEditFieldHandle.ValueChangedFcn = @(source, event) ...
                makeCallback(obj.TagEditFieldCallback, source, event);

            % Add Tag Edit field
            obj.TagsGridContainer =  uigridlayout(obj.GridLayout);
            obj.TagsGridContainer.Layout.Row = 3;
            obj.TagsGridContainer.Layout.Column = [1 3];
            obj.TagsGridContainer.RowHeight = {'fit'};
            obj.TagsGridContainer.ColumnWidth = {'fit', 'fit', 'fit', 'fit'};
            obj.TagsGridContainer.Scrollable = matlab.lang.OnOffSwitchState.on;

            obj.TagsHandleTab = table();
        end

        

        function appendToTagsTable(obj, val, handle)
            %appendToTagsTable used to append data to the tags table

            obj.TagsHandleTab(end+1,:) = {val, handle};
        end

        function deleteFromTagsTable(obj, index)
            %deleteFromTagsTable used to delete the data from the tags
            %table

            obj.TagsHandleTab(index, :) = [];
        end
    end
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
        "ViewerTags", ...
        propertyName)
end
end