classdef MessageVisualizer < ros.internal.Visualizer
%This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleMessage'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'message'}
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerMessageVisualizerDisplay'
        TagBaseDataSource = 'RosbagViewerMessageVisualizerDataSource'
    end

    methods
        function updateData(obj, dataSourcePath, data)
        %updateData Change the displayed message

        % Avoid updating the message if the data source chosen has changed
            if (isempty(dataSourcePath) && isempty(obj.DataSources.Value)) || ...
                    strcmp(dataSourcePath, obj.DataSources.Value)
                if ~isempty(data.Message)
                    obj.GraphicsHandles.Value = rosShowDetails(data.Message);
                else
                    obj.GraphicsHandles.Value = '';
                end
            end
        end
    end

    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and image graphics

            % Data source selection
            obj.DataSourcesID = obj.getNewID;
            tag = numberTag(obj, obj.TagBaseDataSource);
            obj.DataSources = uidropdown(obj.GridHandle, ...
                "Editable", true, ...
                "Placeholder", obj.DataSourceLabel, ...
                "Items", {''}, ...
                "Value", '', ...
                "Tag", tag);
            obj.DataSources.ValueChangedFcn = ...
                @(source, event) makeCallback(obj, ...
                obj.DataSourceChangedCallback, ...
                source, ...
                event, ...
                obj.DataSourcesID);
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = 1;

            % Message display field
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles = uitextarea(obj.GridHandle, "Editable", false, "Tag", tag);
            obj.GraphicsHandles.Layout.Row = 2;
            obj.GraphicsHandles.Layout.Column = 1;
            obj.GraphicsHandles.FontName = 'Monospaced';
            obj.GraphicsHandles.FontSize = 14;

        end

        function reinitVisualizer(obj)
            %reinit function is used to reinitialize the ui components to
            %its default values

            obj.GraphicsHandles.Value = {''};
        end
    end
end
