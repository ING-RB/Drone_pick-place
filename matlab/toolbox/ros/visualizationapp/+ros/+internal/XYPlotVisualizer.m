classdef XYPlotVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleXY'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'numeric'}

        GraphicHandleIdx = 1;
    end

    properties (SetAccess = protected)
        % Indicator of current position
        IndicatorHandles
    end

    properties (SetAccess = ?matlab.unittest.TestCase)
        % Indicates if the data range is updated or not
        DataRangeUpdated = false

        % Indicates data ranges for howmany data sources are updated
        DataRangeUpdatedCtr = 0

        PendingData = {}
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerXYVisualizerDisplay'
        TagBaseIndicator = 'RosbagViewerXYVisualizerIndicator'
        TagBaseDataSource = 'RosbagViewerXYVisualizerDataSource'
    end

    methods

        function updateGraphicHandleIdx(obj)
        %updateGraphicHandleIdx is used to create the new GraphicsHandles
        %whenever pause button is pressed so that we can display
        %discontinuous graph
            obj.GraphicHandleIdx = obj.GraphicHandleIdx + 1;
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles(obj.GraphicHandleIdx) = ...
                ros.internal.LineHelper(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
        end
        
        function updateData(obj, dataSourcePath, dataContainer)
            %updateData Change the displayed position indicator

            if ~obj.DataRangeUpdated
                pendingData.dataSourcePath = dataSourcePath;
                pendingData.dataContainer = dataContainer;
                obj.PendingData{length(obj.PendingData) + 1} = pendingData;
                return
            end
            
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                % avoid updating data if any of the 2 sources is not yet
                % updated
                if isempty(obj.DataSources(1).Value) || isempty(obj.DataSources(2).Value)
                    return
                end
                
                updateXYDataForGraphics(obj, obj.GraphicsHandles, dataSourcePath, dataContainer.Message)
                updateXYDataInHandles(obj, obj.IndicatorHandles, dataSourcePath, dataContainer.Message)
            else
                updateXYDataInHandles(obj, obj.IndicatorHandles, dataSourcePath, dataContainer.Message)
            end 
        end

        function setFullData(obj, dataSourcePath, data, ~, ~)
            %setFullData Set the data from the data source to the right field
            crPgIdHdle = obj.launchCircularProgressIndicator();
            c = onCleanup(@()delete(crPgIdHdle));

            updateXYDataInHandles(obj, obj.GraphicsHandles, dataSourcePath, data)

            obj.DataRangeUpdatedCtr = obj.DataRangeUpdatedCtr + 1;
            if obj.DataRangeUpdatedCtr >= numel(obj.DataSources)
                obj.DataRangeUpdated = true;
                if ~isempty(obj.PendingData)
                    for ii = 1:length(obj.PendingData)
                        updateData(obj, obj.PendingData{ii}.dataSourcePath, ...
                            obj.PendingData{ii}.dataContainer);
                    end
                end
            end
        end

        function validateDataSources(obj)
            %validateDataSources function is used to validate the data
            %sources available in a visualizer.
            
            validateDataSources@ros.internal.Visualizer(obj);
            
            lastTopic = '';
            for idxDataSource = 1:numel(obj.DataSources)
                dataSourcePath = obj.DataSources(idxDataSource).Value;
                if ~isempty(dataSourcePath)
                    [topic, ~] = splitTopicFieldPath(dataSourcePath);
                    if isempty(lastTopic)
                        lastTopic = topic;
                    elseif ~strcmp(topic,lastTopic)
                        visualizerName = obj.InitialTitle; 
                        me = ros.internal.utils.getMException(...
                                'ros:visualizationapp:view:TopicMismatchInDataSources', ...
                                dataSourcePath, visualizerName);
                        throw(me);
                    end
                end
            end
        end
    end

    methods (Access = protected)
        function updateXYDataInHandles(obj, handles, dataSourcePath, data)
            %updateXYDataInHandles Set X-Y graphics data based on source
            %   Based on data source path, determine which graphics objects in
            %   handles should be updated, and update the X and/or Y fields of
            %   those objects with the value in data. The data input must be a
            %   numeric array ready for setting. The handles input must be an
            %   array of graphics objects of length numel(obj.DataSources)/2.

            for idxDataSource = 1:numel(obj.DataSources)
                if strcmp(dataSourcePath, obj.DataSources(idxDataSource).Value)
                    idxLine = ceil(idxDataSource/2);
                    if mod(idxDataSource, 2)
                        handles(idxLine).XData = data;
                    else
                        handles(idxLine).YData = data;
                    end
                end
            end
        end

        function updateXYDataForGraphics(obj, handles, dataSourcePath, data)
            %updateXYDataInHandles Set X-Y graphics data based on source
            %   Based on data source path, determine which graphics objects in
            %   handles should be updated, and update the X and/or Y fields of
            %   those objects with the value in data. The data input must be a
            %   numeric array ready for setting. The handles input must be an
            %   array of graphics objects of length numel(obj.DataSources)/2.

            for idxDataSource = 1:numel(obj.DataSources)
                if strcmp(dataSourcePath, obj.DataSources(idxDataSource).Value)
                    idxLine = obj.GraphicHandleIdx - 1 + ceil(idxDataSource/2);
                    if mod(idxDataSource, 2)
                        handles(idxLine).XData(end+1) = data;
                    else
                        handles(idxLine).YData(end+1) = data;
                    end
                end
            end
        end

        function buildInternals(obj)
            %buildInternals Set up data source and plot

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            end

            % Layout inside visualizer
            obj.GridHandle.RowHeight = {obj.DataSourceHeight, obj.DataSourceHeight, '1x'};
            obj.GridHandle.ColumnWidth = {'fit', '1x'};

            % Data source selection
            obj.DataSourcesID = [obj.getNewID, obj.getNewID];
            
            % X data source
            xDataSource = uilabel(obj.GridHandle, ...
                "Text", obj.XDataSourceLabel, ...
                "HorizontalAlignment", "left");
            xDataSource.Layout.Row = 1;
            xDataSource.Layout.Column = 1;

            tag = numberTag(obj, obj.TagBaseDataSource, 1);
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
                obj.DataSourcesID(1));
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = 2;

            % Y data source
            yDataSource = uilabel(obj.GridHandle, ...
                "Text", obj.YDataSourceLabel, ...
                "HorizontalAlignment", "left");
            yDataSource.Layout.Row = 2;
            yDataSource.Layout.Column = 1;

            tag = numberTag(obj, obj.TagBaseDataSource, 2);
            obj.DataSources(2) = uidropdown(obj.GridHandle, ...
                "Editable", true, ...
                "Placeholder", obj.DataSourceLabel, ...
                "Items", {''}, ...
                "Value", '', ...
                "Tag", tag);
            obj.DataSources(2).ValueChangedFcn = ...
                @(source, event) makeCallback(obj, ...
                obj.DataSourceChangedCallback, ...
                source, ...
                event, ...
                obj.DataSourcesID(2));
            obj.DataSources(2).Layout.Row = 2;
            obj.DataSources(2).Layout.Column = 2;

            % Axes graphics object
            obj.AxesHandle = uiaxes(obj.GridHandle);
            obj.AxesHandle.Layout.Row = 3;
            obj.AxesHandle.Layout.Column = [1 2];
            obj.defaultAxesSetting();

            % Position indicator graphics object
            tag = numberTag(obj, obj.TagBaseIndicator);
            obj.IndicatorHandles = ...
                ros.internal.LineHelper(obj.AxesHandle, "+", ...
                "MarkerSize", 10, "LineWidth", 2, "Tag", tag);

            % Line graphics object
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles = ...
                ros.internal.LineHelper(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
        end

        function defaultAxesSetting(obj)
            obj.AxesHandle.NextPlot = "add";
            obj.AxesHandle.XGrid = 'on';
            obj.AxesHandle.YGrid = 'on';
            obj.AxesHandle.XLabel.String = getString(message('ros:visualizationapp:view:XAxisLabel'));
            obj.AxesHandle.YLabel.String = getString(message('ros:visualizationapp:view:YAxisLabel'));
        end

        function reinitVisualizer(obj)
            %reinitVisualizer function is used to reinitialize the
            %ui components to its default values

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.GraphicsHandles = [];
                tag = numberTag(obj, obj.TagBaseDisplay);
                obj.GraphicsHandles = ...
                    ros.internal.LineHelper(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
                obj.GraphicHandleIdx = 1;
            else
                obj.GraphicsHandles.XData = [];
                obj.GraphicsHandles.YData = [];
            end
            obj.IndicatorHandles.XData = [];
            obj.IndicatorHandles.YData = [];
            reset(obj.AxesHandle);
            obj.defaultAxesSetting();
        end
    end
end

function [topic, fieldPath] = splitTopicFieldPath(fullPath)
splitPath = strsplit(fullPath, '.');
topic = splitPath{1};
fieldPath = {};
if numel(splitPath) > 1
    fieldPath = splitPath(2:end);
end
end
