classdef ThreeDSettingsPanel < handle
%This class is for internal use only. It may be removed in the future.

    % ThreeDSettingsPanel Class for configuring 3D visualizer settings within
    % the rosDataAnalyzer app.
    %
    % This class is designed for internal use within the rosDataAnalyzer
    % provides a user interface for adjusting v3D visualizer settings. It
    % encapsulates the UI components and logic necessary to allow users to
    % customize how data is visualized within the app.
    %

    % Copyright 2024 The MathWorks, Inc.
    properties
        %UI Widgets

        ThreeDPanel
        GridLayout
        DataSourceTable
        FrameIDLabel
        FrameIDDropdown
    end

    properties
        TableCellEditCallback = function_handle.empty;
        TableCellSelectionCallback = function_handle.empty;

        FrameIDValueChangedFcn =  function_handle.empty;
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI components
        TagPanelFigure = "Tag3DSettingsPanelFigure";
        TagPanelGrid = "Tag3DSettingsPanelGrid";
        TagSelectionTable = "Tag3DSettingsPanelTable";
        
        TagFrameIDLabel = '3DSettingsPanelFrameIDLabelTag';
        TagFrameIDDropdown = '3DSettingsPanelFrameIDDropdownTag';
    end


    methods
        function obj = ThreeDSettingsPanel(appContainer)
            buildPanel(obj);
            add(appContainer, obj.ThreeDPanel);
        end
        
        function set.TableCellEditCallback(obj, val)
            obj.TableCellEditCallback = validateCallback(val, ...
                "TableCellEditCallback");
        end

        function set.TableCellSelectionCallback(obj, val)
            obj.TableCellSelectionCallback = validateCallback(val, ...
                "TableCellEditCallback");
        end

        function set.FrameIDValueChangedFcn(obj, val)
            % Setter method for FrameIdDropdownValueChangedFcn property.

            obj.FrameIDValueChangedFcn = validateCallback(val, ...
                "FrameIdDropdownValueChangedFcn");
        end

        function setColor(obj, row, c)
            if length(c) == 3 % Valid Color
                % Apply color style
                style = uistyle('BackgroundColor', c);
                addStyle(obj.DataSourceTable, style, 'cell', [row, 4])
            end
        end

        %g3466888: Add an icon so it's clear that user needs to click to
        %select color.
        function addIcon(obj, row)
            iconStyle = matlab.ui.style.internal.IconIDStyle('IconId',"select_colorPicker");
            addStyle(obj.DataSourceTable, iconStyle, 'cell', [row, 4]);
        end

        function removeStyle(obj, row)
            styles = obj.DataSourceTable.StyleConfigurations;
            idxs = styles.TargetIndex;

            ordernums = [];
            for i = 1:numel(idxs)
                curr = idxs(i);
                if isequal(curr, {[row 4]})
                    if isempty(ordernums)
                        ordernums = i;
                    else
                        ordernums = [i ordernums];
                    end
                end
            end
            
            removeStyle(obj.DataSourceTable, ordernums);
        end

        function flag = isFlatColor(obj, row)
            flag = strcmp(obj.DataSourceTable.Data{row, 3}, getString(message("ros:visualizationapp:view:ThreeDSettingsModeFlat")));
        end

        function topicName = getTopicNameAt(obj, row)
            topicName = obj.DataSourceTable.Data{row, 2};
        end

        function resetDataSources(obj)
            obj.DataSourceTable.Data = {};
        end


        function color = getColor(obj, row)
        % function cellStyle = getCellStyle(table, row, col)
        % Initialize as empty
            color = [];
            
            % Iterate over all styles applied to the table
            for i = 1:height(obj.DataSourceTable.StyleConfigurations)
                if isequal(obj.DataSourceTable.StyleConfigurations.TargetIndex{i}, [row 4])
                    style = obj.DataSourceTable.StyleConfigurations.Style(i);
                    if isprop(style, 'BackgroundColor')
                        color = style.BackgroundColor;
                    end
                end
                
            end
        
        end
        function updateDataSources(obj, topics)
            
            numTopics = numel(topics);
            defaultData = cell(numTopics, 4);

            for i = 1:numTopics
                defaultData{i, 1} = false; % Default for 'Select' column
                defaultData{i, 2} = topics{i}; % Fill 'Topics' column
                defaultData{i, 3} = 'Default'; % Default for 'Color Mode' column
                defaultData{i, 4} = []; % Default for 'Color' column
            end

            obj.DataSourceTable.Data = defaultData;
        end

        function updateSourceProps(obj, source, props)
            topics = {obj.DataSourceTable.Data{:, 2}};
            sourceIndex = find(strcmp(topics, source));

            if ~isempty(sourceIndex)
                obj.DataSourceTable.Data{sourceIndex, 1} = true;
                obj.DataSourceTable.Data{sourceIndex, 3} = props.ColorMode;
                if ~isequal(props.ColorMode, 'Default')
                    obj.setColor(sourceIndex, [props.Color]);
                end
            end
        end

        function row = getSourceRow(obj, source)
            row = [];
            for idx = 1:size(obj.DataSourceTable.Data, 1) % Get number of rows
                if isequal(obj.DataSourceTable.Data{idx,2}, source)
                    row = idx;
                end
            end
        end

        function reset(obj)
            removeStyle(obj.DataSourceTable);

            numTopics = size(obj.DataSourceTable.Data, 1);

            for idx = 1:numTopics
                obj.DataSourceTable.Data{idx, 1} = false;
                obj.DataSourceTable.Data{idx, 3} = 'Default';
            end
        end

        function updateFrameIdDropdown(obj, items)

            if isempty(items)
                return;
            end
            obj.FrameIDDropdown.Items = items;

        end

        function updateFrameIdValue(obj, value)
            obj.FrameIDDropdown.Value = value;
        end

        function obj = buildPanel(obj)
            panelOptions = struct("Title", getString(message("ros:visualizationapp:view:ThreeDSettingsPanelTitle")), ...
                "Region", "right", ...
                "Tag", obj.TagPanelFigure);

            obj.ThreeDPanel = matlab.ui.internal.FigurePanel(panelOptions);
            windowbounds = ros.internal.utils.getWindowBounds;
            obj.ThreeDPanel.PreferredWidth = windowbounds(3)/3.8;

            %Setup Grid Layout

            obj.GridLayout = uigridlayout(obj.ThreeDPanel.Figure, ...
                "Tag", obj.TagPanelGrid);
            obj.GridLayout.RowHeight = {'0.5x', 24, '0.5x'}; % Adjust row height
            obj.GridLayout.ColumnWidth = {'1x', '1x'};
            obj.GridLayout.Scrollable = matlab.lang.OnOffSwitchState.on;

            % Setup topic selection table
            defaultData = cell(0, 4);

            obj.DataSourceTable = uitable(obj.GridLayout, "Tag", obj.TagSelectionTable, ...
                "Visible", matlab.lang.OnOffSwitchState.off, ...
                "ColumnName", {getString(message("ros:visualizationapp:view:ThreeDSettingsSelectColumnName")), ...
                getString(message("ros:visualizationapp:view:ThreeDSettingsTopicColumnName")), ...
                getString(message("ros:visualizationapp:view:ThreeDSettingsModeColumnName")), ...
                getString(message("ros:visualizationapp:view:ThreeDSettingsColorColumnName"))}, ...
                "Data", defaultData);
            obj.DataSourceTable.ColumnEditable = [true false true false];
            obj.DataSourceTable.ColumnFormat = {'logical', 'char', ...
                {getString(message("ros:visualizationapp:view:ThreeDSettingsModeDefault")), ...
                getString(message("ros:visualizationapp:view:ThreeDSettingsModeFlat"))...
                }, 'char'};

            obj.DataSourceTable.Layout.Row = 1;
            obj.DataSourceTable.Layout.Column = [1 2];
            
            obj.DataSourceTable.RowName = [];
            obj.DataSourceTable.CellEditCallback = ...
                @(source, event) makeCallback(obj.TableCellEditCallback, source, event);
            obj.DataSourceTable.CellSelectionCallback = ...
                @(source, event) makeCallback(obj.TableCellSelectionCallback, source, event);

            obj.DataSourceTable.Visible = matlab.lang.OnOffSwitchState.on;

            
            % Add a dropdown with a label
            % Label for the Frame ID dropdown
            obj.FrameIDLabel = uilabel(obj.GridLayout, ...
                'Text', getString(message("ros:visualizationapp:view:FrameIdLabel")),...
                "Tag", obj.TagFrameIDLabel);
            obj.FrameIDLabel.Layout.Row = 2; % Position in the first row of the container
            obj.FrameIDLabel.Layout.Column = 1;

            % Dropdown for FrameID
            obj.FrameIDDropdown = uidropdown(obj.GridLayout, ...
                "Tag", obj.TagFrameIDDropdown);
            obj.FrameIDDropdown.Items = ""; % Empty assuming no frame_ids are present.
            obj.FrameIDDropdown.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.FrameIDValueChangedFcn, source, event);
            obj.FrameIDDropdown.Layout.Row = 2; % Position in the second row of the container
            obj.FrameIDDropdown.Layout.Column = 2;
        end
    end
end

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
        "Viewer3DSettings", ...
        propertyName)
end
end

% LocalWords:  DSettings Dropdown dropdown
