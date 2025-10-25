classdef TimePlotVisualizer < ros.internal.Visualizer
%This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleTimeSeries'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'numeric'}

        GraphicHandleIdx = 1;
    end

    properties (SetAccess = protected)
        % Indicator of current position
        IndicatorHandles

        % Values related to the current position indicator
        % TODO: Make non-constant, based on map size and zoom level
        IndicatorLongSide = 2
        IndicatorHalfAngle = 0.25   % radians

        DataRangeUpdated = false
        PendingData = {}
        TimeDisplaySettings = []
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base
        TagBaseDisplay = 'RosbagViewerTimePlotVisualizerDisplay'
        TagBaseIndicator = 'RosbagViewerTimePlotVisualizerIndicator'
        TagBaseDataSource = 'RosbagViewerTimePlotVisualizerDataSource'
    end

    methods

        function updateGraphicHandleIdx(obj)
        %updateGraphicHandleIdx is used to create the new GraphicsHandles
        %whenever pause button is pressed so that we can display
        %discontinuous graph
            obj.GraphicHandleIdx = obj.GraphicHandleIdx + 1;
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles(obj.GraphicHandleIdx) = ...
                ros.internal.LineHelper(obj.AxesHandle,"Color", [1, 0.5, 0],  "Tag", tag);
        end

        function updateData(obj, ~, dataContainer)
        %updateData Change the displayed position indicator

            if ~obj.DataRangeUpdated
                pendingData.dataContainer = dataContainer;
                obj.PendingData{length(obj.PendingData) + 1} = pendingData;
                return
            end

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                newTime = getTimeStamp();
                obj.GraphicsHandles(obj.GraphicHandleIdx).XData(end+1) = newTime;
                obj.GraphicsHandles(obj.GraphicHandleIdx).YData(end+1) = dataContainer.Message;
            else
                newTime = dataContainer.Time;
            end

            obj.IndicatorHandles.XData = [newTime newTime];
            obj.IndicatorHandles.YData = ylim(obj.AxesHandle);
        end
        
        function setFullData(obj, dataSourcePath, data, timestamps,~)
            %setFullData Set the data from the data source and timestamps

            crPgIdHdle = obj.launchCircularProgressIndicator();
            c = onCleanup(@()delete(crPgIdHdle));

            reinitVisualizer(obj)
            obj.AxesHandle.XLimitMethod = 'tight';
            for idxDataSource = 1:numel(obj.DataSources)
                if strcmp(dataSourcePath, obj.DataSources(idxDataSource).Value)
                    obj.GraphicsHandles(idxDataSource).XData = timestamps;
                    obj.GraphicsHandles(idxDataSource).YData = data;
                end
            end
            obj.DataRangeUpdated = true;
            if ~isempty(obj.PendingData)
                for ii = 1:length(obj.PendingData)
                    updateData(obj, [], obj.PendingData{ii}.dataContainer);
                end
            end

            if ~isempty(settings)
                updateTimeSettings(obj, obj.TimeDisplaySettings)
            end
        end

        function updateTimeSettings(obj, settings)
            %updateTimeSettings function is used to update visualizer with
            %latest time settings
            
            if ~isempty(settings)
                obj.TimeDisplaySettings = settings;
                obj.AxesHandle.XTickLabel  = settings.ticks;
                obj.AxesHandle.XTick  = linspace(settings.tStart, settings.tEnd, numel(settings.ticks));
            end
        end
    end

    methods (Access = protected)
        function buildInternals(obj)
            %buildInternals Set up data source and plot
            
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            end

            % Data source selection
            obj.DataSourcesID = obj.getNewID;
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
            obj.DataSources.Layout.Column = 1;

            % Axes graphics object
            obj.AxesHandle = uiaxes(obj.GridHandle);
            obj.AxesHandle.Layout.Row = 2;
            obj.AxesHandle.Layout.Column = 1;
            obj.defaultAxesSetting();

            % Position indicator graphics object
            tag = numberTag(obj, obj.TagBaseIndicator);
            obj.IndicatorHandles = ...
                ros.internal.LineHelper(obj.AxesHandle, "--", "LineWidth", 1, "Tag", tag);

            % Line graphics object
            tag = numberTag(obj, obj.TagBaseDisplay);
            obj.GraphicsHandles = ...
                ros.internal.LineHelper(obj.AxesHandle, "Color", [1, 0.5, 0], "Tag", tag);
        end

        function defaultAxesSetting(obj)
            %defaultAxesSetting default setting for Axes 
            
            obj.AxesHandle.NextPlot = "add";
            obj.AxesHandle.XGrid = 'on';
            obj.AxesHandle.YGrid = 'on';
            obj.AxesHandle.XLabel.String = getString(message('ros:visualizationapp:view:TimeLabel'));
        end

        function reinitVisualizer(obj)
            %reinitVisualizer function is used to reinitialize the ui components to
            %its default values

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                %reseting GraphicsHandle
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

function timeStamp = getTimeStamp()
    curTime = datetime('now','Format','HHmmss');
    timeStamp = hour(curTime)*1e4 + minute(curTime)*1e2 + second(curTime);
end
