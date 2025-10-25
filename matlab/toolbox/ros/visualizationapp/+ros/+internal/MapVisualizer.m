classdef MapVisualizer < ros.internal.Visualizer
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties
        % Initial title of the visualizer
        InitialTitle = getString(message('ros:visualizationapp:view:TabTitleMap'))

        % Types of messages/fields that can be visualized
        % Options are defined by the RosbagTree object
        CompatibleTypes = {'sensor_msgs/NavSatFix', ...
                            'sensor_msgs/msg/NavSatFix', ...
                            'gps_common/GPSFix'}
        GraphicHandleIdx = 1;
    end

    properties (SetAccess = protected)
        % Indicator of current position
        IndicatorHandles
    end

    properties (SetAccess = ?matlab.unittest.TestCase)
        % Indicates if the data range is updated or not
        DataRangeUpdated = false

        % Indicates data ranges for how many data sources are updated
        DataRangeUpdatedCtr = 0

        % Indicates the data range
        DataRange = 0

        % Indicates the lower bound index of the most recent time
        % Used to help display the current VectorHandle when the time is
        % not found in the TimeAngleDict
        TimeIndex = 1;

        PendingData = {};
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for UI elements, including "tag bases" where there may be
        % multiple UI elements sharing a base

        TagBaseDisplay = 'RosbagViewerMapVisualizerDisplay'
        TagBaseIndicator = 'RosbagViewerMapVisualizerIndicator'
        TagBaseDataSource = 'RosbagViewerMapVisualizerDataSource'
    end

    methods
        function updateGraphicHandleIdx(obj)
            %updateGraphicHandleIdx is used to create the new GraphicsHandles
            %whenever pause button is pressed so that we can display
            %discontinuous graph
            
            %Note: this method is required for Live Ros Topic Visualization
            
            obj.GraphicHandleIdx = obj.GraphicHandleIdx + 1;
            tag = numberTag(obj, obj.TagBaseDisplay);
            
            obj.GraphicsHandles(obj.GraphicHandleIdx) = ros.internal.view.MapHelper(obj.AxesHandle, ...
                '--mw-graphics-colorOrder-1-primary',...
                "-", ...
                "Tag", tag, ...
                "LineWidth", 3.5);
        end
        
        function updateData(obj, dataSourcePath, dataContainer)
            %updateData Change the displayed position indicator

            if ~obj.DataRangeUpdated
                pendingData.dataSourcePath = dataSourcePath;
                pendingData.dataContainer = dataContainer;
                obj.PendingData{length(obj.PendingData) + 1} = pendingData;
                return
            end
            [~, fieldPath] = splitTopicFieldPath(dataSourcePath);
            if isempty(fieldPath)
                msg = dataContainer.Message;
            else
                msg = getfield(dataContainer.Message, fieldPath{:});
            end
            fieldMap = dataContainer.FieldMap;
            lat = eval(['msg.' char(fieldMap.latitude)]);
            longt = eval(['msg.' char(fieldMap.longitude)]);
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.GraphicsHandles(obj.GraphicHandleIdx).Latitude(end+1) = lat;
                obj.GraphicsHandles(obj.GraphicHandleIdx).Longitude(end+1) = longt;

            end

            obj.IndicatorHandles.Latitude = lat;
            obj.IndicatorHandles.Longitude = longt;
        end

        function setFullData(obj, ~, data, ~, fieldMap)
            %setFullData is called to plot all the data points when the
            %dataSource is selected. It sets full data

            crPgIdHdle = obj.launchCircularProgressIndicator();
            c = onCleanup(@()delete(crPgIdHdle));

            N = numel(data);
            lat = zeros(N,1);
            lng = zeros(N,1);
            agl = zeros(N,1);
            latt = arrayfun(@(msg)eval(['msg.' char(fieldMap.latitude)]), data); %#ok<EVLDOT>
            longt = arrayfun(@(msg)eval(['msg.' char(fieldMap.longitude)]), data); %#ok<EVLDOT>

            for i = 1:N
                lat(i) = latt(i);
                lng(i) = longt(i);
                if(i > 1)
                    agl(i-1) =  atan2d(lat(i) - lat(i-1), lng(i) - lng(i-1));
                end
            end

            obj.GraphicsHandles(obj.GraphicHandleIdx).Latitude = lat;
            obj.GraphicsHandles(obj.GraphicHandleIdx).Longitude = lng;

            obj.DataRangeUpdated = true;
            obj.DataRange = N;

            if ~isempty(obj.PendingData)
                for ii = 1:length(obj.PendingData)
                    updateData(obj, obj.PendingData{ii}.dataSourcePath, ...
                        obj.PendingData{ii}.dataContainer);
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

        function buildInternals(obj)
            %buildInternals Set up data source and plot

            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            end
            obj.DataSourcesID = obj.getNewID;
            % Data source
            tag = numberTag(obj, obj.TagBaseDataSource, 1);
            obj.DataSources = uidropdown(obj.GridHandle, ...
                "Editable", true, ...
                "Placeholder", obj.DataSourceLabel, ...
                "Items", {''}, ...
                "Value", '', ...
                "Tag", tag);
            obj.DataSources.ValueChangedFcn = @(source, event) makeCallback(obj, ...
                obj.DataSourceChangedCallback, ...
                source, ...
                event, ...
                obj.DataSourcesID);
            obj.DataSources.Layout.Row = 1;
            obj.DataSources.Layout.Column = [1 2];

            % Axes graphics object
            obj.AxesHandle = geoaxes(obj.GridHandle);
            obj.AxesHandle.Layout.Row = 2;
            obj.AxesHandle.Layout.Column = [1 2];
            obj.defaultAxesSetting();

            % Line graphics object
            tag = numberTag(obj, obj.TagBaseDisplay);
            % Follow MATLAB graphic order
            obj.GraphicsHandles = ros.internal.view.MapHelper(obj.AxesHandle, ...
                '--mw-graphics-colorOrder-1-primary',...
                "-", ...
                "Tag", tag, ...
                "LineWidth", 3.5);


            % marker graphics object
            tag = numberTag(obj, obj.TagBaseIndicator);
            % Follow MATLAB Graphic order
            obj.IndicatorHandles = ros.internal.view.MapHelper(obj.AxesHandle, ...
                '--mw-graphics-colorOrder-2-primary' ,...
                "Marker", ".", ...
                "MarkerSize", 23,  ...
                "Tag", tag);
        end

        function defaultAxesSetting(obj)
            obj.AxesHandle.NextPlot = "add";
            obj.AxesHandle.Grid = 'on';
            obj.AxesHandle.Basemap = 'topographic';
            obj.AxesHandle.Scalebar.Visible = 'on';
            obj.AxesHandle.LatitudeLabel.String = getString(message('ros:visualizationapp:view:LatitudeAxisLabel'));
            obj.AxesHandle.LongitudeLabel.String = getString(message('ros:visualizationapp:view:LongitudeAxisLabel'));
        end

        function reinitVisualizer(obj)
            %reinitVisualizer function is used to reinitialize the
            %ui components to its default values
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.GraphicsHandles = [];
                tag = numberTag(obj, obj.TagBaseDisplay);
                obj.GraphicsHandles = ros.internal.view.MapHelper(obj.AxesHandle, ...
                    "b-", ...
                    "Tag", tag, ...
                    "LineWidth", 3.5);
                obj.GraphicHandleIdx = 1;
            end
            obj.GraphicsHandles.Latitude = [];
            obj.GraphicsHandles.Longitude = [];
            obj.IndicatorHandles.Latitude = [];
            obj.IndicatorHandles.Longitude = [];
            reset(obj.AxesHandle);
            obj.defaultAxesSetting();
            if isequal(obj.AppMode,ros.internal.ViewerPresenter.LiveRosTopicVisualization)
                obj.DataRangeUpdated = true;
            else
                obj.DataRangeUpdated = false;
            end
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
