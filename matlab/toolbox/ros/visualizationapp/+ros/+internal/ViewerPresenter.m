classdef ViewerPresenter < handle & ros.internal.mixin.ROSInternalAccess
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2022-2025 The MathWorks, Inc.

    properties (Access = ?ros.internal.mixin.ROSInternalAccess)
        % Shared object for notifying and listening for events
        EventObject

        % UI elements
        AppContainer
        Toolstrip
        TopicList
        VisualizerDocGroup
        Timeline
        UIAlert
        UIProgress

        % Structure mapping data sources to the visualizer to update
        VisualizerMapping

        % Information on the structure of the topic and message types
        TopicTree

        % Indicator if app is currently in playback mode (false = paused)
        PlaybackState = false

        PlaybackDirection = 1

        % This timer controls the playback events
        PlaybackTimer

        % Previously used bagfile path
        LastOpenedBagPath

        % To determine Automatic Topic for playback
        AutomaticTopic

        % Save Cache related
        LayoutFromCache
        VisualizerInfo
        RestoringCache = false
        SkipUpdateCache = false
        CacheLoaded = false
        % Bookmark
        BookmarkTabObj
        BookmarkPanelObj
        BookmarkDataFromSession

        % tag
        AddTagsPanelObj
        AddTagsTableObj
        TagsDataFromSession

        % Mode of the app : Live topic / bag file visualization
        AppMode = ""

        % Search ROS bag App
        SearchRosbagAppObj

        
        % Export ROS bag App
        ExportFromTopicAppObj
        ExportFromBookmarkAppObj
        
        % Flag to check if the current event handler is in progress
        ProcessingFlag = false;

        % VisualizerSetting
        VisualizerSettingPanelObj;

        % 3D Settings
        ThreeDSettingsObj;

        %Measure Distance
        measureDistancePlotted = false

        %3D Model to manage source properties
        SourceManager

        % Transform Manager
        TransformManager
    end

    properties(Access = ?matlab.unittest.TestCase)
        EnableSaveAppState = true % switch for testing
    end

    properties (Hidden)
        UniqueTagApp
        UniqueTimerName
        CacheDataForSearch
    end

    properties (Access=private)
        LastVizID;
    end

    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        TagAppContainer = "RosbagViewerAppContainer"
        TagDocGroup = "RosbagViewerDocGroup"

        % Minimal pause time to give up the thread
        PauseTime = 0.03

        % Preference group for MATLAB preference
        PrefGroup = 'ROS_Toolbox'

        % Previously used bag path
        LastUsedBagPathPrefName = 'VIS_APP_LAST_USED_BAG_PATH'

        LastUsedROSMasterURIs = 'VIS_APP_LAST_USED_ROS_MASTER_URIS'

        LastUsedROSDomainIDs = 'VIS_APP_LAST_USED_ROS_DOMAIN_IDS'


        % PlaybackTimer Name
        PlaybackTimerName = "RosbagViewerPlaybackTimer"

        % Represents forward playback mode
        ForwardPlayback = 1

        % Represents reverse playback mode
        ReversePlayback = -1

        %Automatic Topic Priority List for playback
        AutomaticTopicPriorityList = ["image", "pointcloud", "laserscan", "odometry"];
    end

    properties (Constant)
        RosbagVisualization = "RosbagVisualization"
        LiveRosTopicVisualization = "LiveRosTopicVisualization"
    end

    methods
        function obj = ViewerPresenter(eventObject)
            %RosbagViewer Create UI elements for initial display
            %   Also prepare to react to events and UI interactions.

            % Parse input
            narginchk(1, 1)
            validateattributes(eventObject, ...
                "ros.internal.RosbagViewerEvents", ...
                "scalar", ...
                "ViewerPresenter", ...
                "eventObject")
            obj.EventObject = eventObject;

            % This will generate unique tag and timer name where multiple
            % sessions are launched.
            %it is required that each app session has a unique tag
            persistent appIdx;
            if isempty(appIdx)
                appIdx = 1;
            end
            obj.UniqueTagApp = obj.TagAppContainer + num2str(appIdx);
            obj.UniqueTimerName = obj.PlaybackTimerName + num2str(appIdx) + ...
                string(datetime("now","Format","ddHHmmssSSSS"));

            % Construct the app
            createAppContainerAndContents(obj);

            % Create UI dlgs for App
            obj.UIAlert = ros.internal.view.UIAlert();
            obj.UIProgress = ros.internal.view.UIProgressdlg();

            % Initialize mapping of visualizer data sources
            obj.VisualizerMapping = ...
                struct("ID", [], "Handle", [], "Topic", {""}, ...
                "DataSource", {""}, "DataType", string.empty);
            obj.VisualizerMapping(1) = [];

            obj.PlaybackTimer = timer('Name', obj.UniqueTimerName, ...
                'Period', obj.PauseTime, 'ExecutionMode', 'fixedSpacing');

            obj.SourceManager = ros.internal.utils.AppSourceManager();

            % Listen to events
            setupCallbacksListeners(obj)

            % Make the app visible and accessible
            obj.AppContainer.Visible = true;
            % % collapse the bookmark by default
            % waitfor(obj.AppContainer, 'State', matlab.ui.container.internal.appcontainer.AppState.RUNNING);
            % obj.AppContainer.RightCollapsed = 1;

            % Load last time used bag path from preference
            if ispref(obj.PrefGroup,obj.LastUsedBagPathPrefName)
                obj.LastOpenedBagPath = getpref(obj.PrefGroup,obj.LastUsedBagPathPrefName);
            else
                obj.LastOpenedBagPath = '';
            end
            appIdx = appIdx+1;
        end

        function delete(obj)
            %delete Close the app and free up resources

            import matlab.ui.container.internal.appcontainer.AppState;

            weakHndlObj = matlab.internal.WeakHandle(obj);
            ros.internal.ViewerPresenter.cleanupAndCloseApp(weakHndlObj);

            if isvalid(obj.AppContainer) && ...
                    ~(obj.AppContainer.State == AppState.TERMINATED)
                obj.AppContainer.CanCloseFcn = [];
                close(obj.AppContainer);
            end
        end
    end

    methods (Access = ?ros.internal.mixin.ROSInternalAccess)    % Helper methods
        function addDataSourceToMapping(obj, id, hVisualizer, dataType)
            %addDataSourceToMapping Add new data source for tracking
            %   The ID is unique to that specific data source
            %   The handle is to the visualizer with that data source
            %   The data type refers to the type of data to be displayed

            % Data source should initially be empty
            % Just set ID, handle, and data type (based on visualizer type)
            obj.VisualizerMapping(end+1) = ...
                struct("ID", id, "Handle", hVisualizer, "Topic", {""}, ...
                "DataSource", {""}, "DataType", dataType);

        end

        function sendSourceListToModel(obj)
            %sendSourceListToModel Sends the sources and their types to model.
            %Usually this should be invoked after a change in the source list
            %to notify model.
      
            % Initialize empty cell arrays for DataSource and DataType
            dataSources = [];  % Initialize as an empty string array
            dataTypes = [];    % Initialize as an empty string array for DataType strings

            % Iterate over each element in obj.VisualizerMapping
            for i = 1:length(obj.VisualizerMapping)
                currentDataSources = obj.VisualizerMapping(i).DataSource;  % Assuming this might be cell or array
                currentDataType = string(obj.VisualizerMapping(i).DataType{1});  % Convert DataType to string

                % Flatten currentDataSources into a string array if it's a cell array of strings
                if iscell(currentDataSources)
                    currentDataSources = string([currentDataSources{:}]);  % Convert cell array to string array
                else
                    currentDataSources = string(currentDataSources);  % Ensure it's a string even if not a cell
                end

                % Replicate currentDataType for each dataSource
                replicatedDataTypes = repmat(currentDataType, length(currentDataSources), 1);
                
                if strcmp(currentDataType, "3d")
                    for idx = 1:length(currentDataSources)
                        dataSource = currentDataSources(idx);
                        currType = getTypeWithFieldPath(obj.TopicTree, dataSource);

                        if strcmp(currType, 'sensor_msgs/PointCloud2')
                            tempDataType = "pointcloud";
                        elseif strcmp(currType, 'sensor_msgs/LaserScan')
                            tempDataType = "laserscan";
                        else
                            tempDataType = "marker";
                        end
                        replicatedDataTypes(idx) = tempDataType;
                    end                    
                end
                % Append to the accumulators
                dataSources = [dataSources; currentDataSources(:)];  % Concatenate string arrays
                dataTypes = [dataTypes; replicatedDataTypes];  % Concatenate string arrays
            end

            % Now, create the table with both as string arrays
            mappingTable = table(dataSources, dataTypes, 'VariableNames', {'DataSource', 'DataType'});
            % remove visualizer with empty data source
            whichEmpty = strcmp(mappingTable.DataSource, "");
            mappingTable(whichEmpty, :) = [];
            % notify the model
            eventDataOut = ros.internal.EventDataContainer(mappingTable);
            notify(obj.EventObject, "DataSourcesRequiredPM", eventDataOut)
        end

        function createAppContainerAndContents(obj)
            %createAppContainerAndContents Initialize the App UI

            appOptions = struct("Tag", obj.UniqueTagApp, ...
                "Title", getString(message("ros:visualizationapp:view:AppTitle")), ...
                "EnableTheming", true);

            obj.AppContainer = matlab.ui.container.internal.AppContainer(appOptions);
            appWindowBounds = ros.internal.utils.getWindowBounds();
            obj.AppContainer.WindowBounds = appWindowBounds;
            %Add a global toolstrip tab group
            obj.Toolstrip = ros.internal.ViewerToolstrip(obj.AppContainer);

            % Add a document group
            obj.VisualizerDocGroup = matlab.ui.internal.FigureDocumentGroup("Tag", obj.TagDocGroup);
            add(obj.AppContainer, obj.VisualizerDocGroup);

            % Add the topic tree panel to the left
            obj.TopicList = ros.internal.ViewerTopicList(obj.AppContainer);

            % Add the timeline panel to the bottom
            obj.Timeline = ros.internal.ViewerTimeline(obj.AppContainer);

            obj.BookmarkTabObj = ros.internal.model.BookmarkTable();
            obj.BookmarkPanelObj = ros.internal.view.ViewerBookmark(obj.AppContainer, obj.BookmarkTabObj.BookmarkTableList);

            % Add the tag panel
            obj.AddTagsPanelObj = ros.internal.view.ViewerTags(obj.AppContainer);

        end

        function setupCallbacksListeners(obj)
            %setupCallbacksListeners Enable UI interaction and event reaction

            objWeakHndl = matlab.internal.WeakHandle(obj);

            % Set up initial UI for interaction
            % toolstrip widgets callbacks
            obj.Toolstrip.OpenFileCallback = @(~, ~) ros.internal.ViewerPresenter.openRosbag(objWeakHndl);
            obj.Toolstrip.OpenROSMasterURICallback = @(~, ~) ros.internal.ViewerPresenter.inputRosNetwork(objWeakHndl,'ros1');
            obj.Toolstrip.OpenROS2DomainIDCallback = @(~, ~) ros.internal.ViewerPresenter.inputRosNetwork(objWeakHndl,'ros2');
            obj.Toolstrip.SearchCallback = @(~,~) ros.internal.ViewerPresenter.searchRosbagCallback(objWeakHndl);
            obj.TopicList.RefreshCallback = @(~, ~) ros.internal.ViewerPresenter.refreshTopicList(objWeakHndl);
            obj.Toolstrip.ImageViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.ImageVisualizer, "image", false);
            obj.Toolstrip.PointCloudViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.PointCloudVisualizer, "pointcloud", false);
            obj.Toolstrip.LaserScanViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.LaserScanVisualizer, "laserscan", false);
            obj.Toolstrip.OdometryViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.OdometryVisualizer, "odometry", true);
            obj.Toolstrip.XYPlotViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.XYPlotVisualizer, "numeric", true);
            obj.Toolstrip.TimePlotViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.TimePlotVisualizer, "numeric", true);
            obj.Toolstrip.MessageViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.MessageVisualizer, "message", false);
            obj.Toolstrip.MapViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.MapVisualizer, "map", true);
            obj.Toolstrip.ThreeDViewerCallback = @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.ThreeDVisualizer, "3d", false); 
            obj.Toolstrip.GridLayoutCallback = @(source, eventData) ros.internal.ViewerPresenter.gridlayout(objWeakHndl, source, eventData);
            obj.Toolstrip.DefaultLayoutCallback = @(source, eventData) ros.internal.ViewerPresenter.gridlayout(objWeakHndl, source, eventData);
            obj.Toolstrip.AddBookmarkCallback = @(~, ~) ros.internal.ViewerPresenter.addBookmark(objWeakHndl);
            obj.Toolstrip.AddTagCallback = @(~, ~) ros.internal.ViewerPresenter.addTagsToRosbag(objWeakHndl);
            obj.Toolstrip.ManageBookmarkCallback = @(~, ~) ros.internal.ViewerPresenter.manageBookmark(objWeakHndl);
            obj.Toolstrip.PlayCallback = @(~, ~) ros.internal.ViewerPresenter.playPausePushed(objWeakHndl);
            obj.Toolstrip.ExportFromTopicCallback = @(~, ~) ros.internal.ViewerPresenter.exportFromTopic(objWeakHndl);
            obj.Toolstrip.ExportFromBookmarkCallback = @(~, ~) ros.internal.ViewerPresenter.exportFromBookmark(objWeakHndl);
            obj.Toolstrip.MarkerViewerCallback =  @(~, ~) ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, @ros.internal.MarkerVisualizer, "marker", false);
            obj.Toolstrip.ViewToggleCallback = @(~, ~) ros.internal.ViewerPresenter.ViewToggle(objWeakHndl);
            obj.Toolstrip.MeasureDistanceCallback = @(~, ~) ros.internal.ViewerPresenter.MeasureDistance(objWeakHndl);
        
            %timeline widgets callbacks
            obj.Timeline.SliderValueChangedCallback = @(source, ~) ros.internal.ViewerPresenter.timelineValueChanged(objWeakHndl, source);
            obj.Timeline.TimeTypeValueChangedCallback   = @(source, event) ros.internal.ViewerPresenter.updateCurrentTimeFieldChanged(objWeakHndl, source, event);
            obj.Timeline.SliderValueChangingCallback = @(source, ~) ros.internal.ViewerPresenter.timelineValueChanging(objWeakHndl, source);
            obj.Timeline.TimeFieldValueChangedCallback = @(source, event) ros.internal.ViewerPresenter.currentTimeFieldChanged(objWeakHndl, source, event);
            obj.Timeline.PlayCallback = @(source, ~) ros.internal.ViewerPresenter.playPausePushed(objWeakHndl, source);
            obj.Timeline.NextCallback = @(~, ~) ros.internal.ViewerPresenter.nextPushed(objWeakHndl);
            obj.Timeline.PreviousCallback = @(~, ~) ros.internal.ViewerPresenter.previousPushed(objWeakHndl);
            obj.Timeline.ShowBookmarkValueChangedFcn = @(~, ~) ros.internal.ViewerPresenter.showBookmarkOnTimeline(objWeakHndl);
            obj.AppContainer.CanCloseFcn = @(~, ~) ros.internal.ViewerPresenter.cleanupAndCloseApp(objWeakHndl);
            
            obj.PlaybackTimer.TimerFcn = @(source,~)ros.internal.ViewerPresenter.playBackTimerCallback(objWeakHndl,source);

            % Set up to react to events
            addlistener(obj.EventObject, "RosbagLoadedMP", @(~, eventData) updateAppWithLoadedRosbag(obj, eventData));
            addlistener(obj.EventObject, "DataForTimeMP", @(~, eventData) updateVisualizers(obj, eventData));
            addlistener(obj.EventObject, "DataForTimeRangeMP", @(~, eventData) updateVisualizersWithDataRange(obj, eventData));
            addlistener(obj.EventObject, "TopicsInfoMP", @(~, eventData) updateTopicInfo(obj, eventData));

            % Setup Layout
            addlistener(obj.EventObject, 'ReturnAppSessionCacheDataMP', @(~, eventData) getAppCacheData(obj, eventData));

            %Bookmark widget callback
            obj.BookmarkPanelObj.TableSelectionChangedFcn = @(source, event) ros.internal.ViewerPresenter.bmTableSelectionChanged(objWeakHndl, source, event);
            obj.BookmarkPanelObj.TableCellSelectionCallback = @(source, event) ros.internal.ViewerPresenter.bmTableSelectionChanged(objWeakHndl, source, event);
            obj.BookmarkPanelObj.TableCellEditCallback = @(source, event) ros.internal.ViewerPresenter.bmTableCellEditCallback(objWeakHndl, source, event);
            obj.BookmarkPanelObj.TableClickedFcn = @(source, event) ros.internal.ViewerPresenter.bmTableClickedFcn(objWeakHndl, source, event);

            %Tag rosbag  callback
            obj.AddTagsPanelObj.TagEditFieldCallback = @(source, event) ros.internal.ViewerPresenter.tagsAddCallback(objWeakHndl, source, event);
            
            % listener to the marker visualizer setting panel
            addlistener(obj.VisualizerDocGroup, 'PropertyChanged', @(source, event)ros.internal.ViewerPresenter.documentSelectionChanged(objWeakHndl, source, event));

           
        end

        function requestDataForTime(obj, t)
            %requestDataForTime Inform model time has changed

            eventDataOut = ros.internal.EventDataContainer(t);
            notify(obj.EventObject, "CurrentTimeChangedPM", eventDataOut)
        end

        function stepTime(obj, direction)
            %stepTime Move to a new message based on current position
            %   The next time depends on the provided direction, selected main
            %   signal, and selected rate.
            %   direction = 1 for forward, -1 for backwards

            if isequal(obj.AppMode,obj.RosbagVisualization)
                % get current time
                t = getCurrentTime(obj.Timeline);

                % get current speed
                rate = getRate(obj.Timeline);

                % get the reference signal
                [referenceTopicIdx, referenceTopic] = getSelectedSignal(obj.Timeline);
                if referenceTopicIdx == 0
                    referenceTopic = obj.AutomaticTopic;
                end

                % Send request to determine the next message to the model
                if ~isempty(referenceTopic)
                    %Don't send any request to model if reference topic is
                    %empty. It could happen when all visualizers are closed and
                    %reference topic is Automatic.
                    eventDataOutStruct = struct("CurrentTime", t, ...
                        "Direction", direction, ...
                        "Rate", rate, ...
                        "MainSignal", referenceTopic);
                    eventDataOut = ros.internal.EventDataContainer(eventDataOutStruct);

                    notify(obj.EventObject, "MoveToNextMessagePM", eventDataOut);
                elseif obj.PlaybackState
                    %If playback is going on and reference topic is empty due
                    %to all visualizers are closed, stop the playback
                    stopPlayBack(obj);
                end
            else
                eventDataOutStruct = struct();
                eventDataOut = ros.internal.EventDataContainer(eventDataOutStruct);
                notify(obj.EventObject, "MoveToNextMessagePM", eventDataOut);
            end
        end

        function updateGraphicHandleIdx(obj)
            for iVis = 1:numel(obj.VisualizerMapping)
                if isprop(obj.VisualizerMapping(iVis).Handle, 'GraphicHandleIdx')
                    updateGraphicHandleIdx(obj.VisualizerMapping(iVis).Handle);
                end
            end
        end

        function resetCacheProperties(obj)
            obj.TagsDataFromSession = [];
            obj.BookmarkDataFromSession = [];
            obj.VisualizerInfo = [];
            obj.LayoutFromCache = [];
        end

        function vizID = getSelectVizId(obj)
            %Fetches the currently selected visualizer id
            tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
            matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
            whichVis = matchingIndexes;
            vizID = obj.VisualizerMapping(whichVis).Handle.DataSourcesID;
        end

    end

    methods (Access = ?ros.internal.mixin.ROSInternalAccess)    % Event callbacks
        function automaticTopic = getReferenceTopicForAutomatic(obj)
            %getReferenceTopicForAutomatic - algorithm to determine
            %automatic reference topic.

            % if no visualizer loaded then return empty
            if isempty(obj.VisualizerMapping)
                automaticTopic = '';
                return;
            end
            % filter out the visualizer where data source is not selected
            %TO DO - support array of topics
            %visualizerList = obj.VisualizerMapping([obj.VisualizerMapping.Topic] ~="");

            logicalIndex = arrayfun(@(x) any(x.Topic ~= ""), obj.VisualizerMapping);
            filteredVisualizerMapping = obj.VisualizerMapping(logicalIndex);
            visualizerList = filteredVisualizerMapping;
            if isempty(visualizerList)
                automaticTopic = '';
                return;
            end
            % if only one visualizer has datasource is selected
            automaticTopic = visualizerList(1).Topic(1);
            % if more than one visualizer then prioritize as in order
            % ["image", "pointcloud", "laserscan", "odometry"]
            if numel(visualizerList) >1
                for tindx = 1:numel(obj.AutomaticTopicPriorityList)
                    % prioritize as in order ["image", "pointcloud", "laserscan", "odometry"]
                    if any(ismember([visualizerList.DataType], obj.AutomaticTopicPriorityList(tindx)))
                        % find if there are more than one vis with same
                        % datatype
                        indexes = [visualizerList.DataType] == obj.AutomaticTopicPriorityList(tindx);
                        % get min freq when multiple visualizer with
                        % same data type
                        topicsWithMinFreq = obj.TopicList.getFrequencyForTopic([visualizerList(indexes).Topic]);
                        % returns the logical array where the condition is
                        % satisfied.for example [20 20 10] if searching for
                        % 10 it returns [0 0 1]
                        minFreqTopics = [topicsWithMinFreq.Frequency] == min([topicsWithMinFreq.Frequency]);
                        % matlab will select indexes which has boolean
                        automaticTopic = topicsWithMinFreq(minFreqTopics).Topic;
                        return;
                    end
                end
                topicsWithMinFreq = obj.TopicList.getFrequencyForTopic([visualizerList(:).Topic]);
                % returns the logical array where the condition is
                % satisfied.for example [20 20 10] if searching for
                % 10 it returns [0 0 1]
                minFreqTopics = [topicsWithMinFreq.Frequency] == min([topicsWithMinFreq.Frequency]);
                % matlab will select indexes which has boolean
                automaticTopic = topicsWithMinFreq(minFreqTopics).Topic;
            elseif isequal(class(visualizerList(1).Handle), 'ros.internal.MarkerVisualizer')
              %Explicitly handle MarkerVisualizer since it can have multiple sources.
              topicsWithMinFreq = obj.TopicList.getFrequencyForTopic([visualizerList(:).Topic]);
              minFreqTopics = [topicsWithMinFreq.Frequency] == min([topicsWithMinFreq.Frequency]);
              automaticTopic = topicsWithMinFreq(minFreqTopics).Topic;
            end
        end

        function changeAppMode(obj)
            obj.TopicList.setAppMode(obj.AppMode)
            obj.Toolstrip.setAppMode(obj.AppMode)
            obj.BookmarkPanelObj.setAppMode(obj.AppMode)
            obj.AddTagsPanelObj.setAppMode(obj.AppMode)
            obj.Timeline.setAppMode(obj.AppMode)
        end

        function updateTopicInfo(obj, eventData)

            if ~isempty(eventData.Data.Error)
                throwError(obj, eventData.Data.Error);
            else
                if obj.EnableSaveAppState
                    if ~isempty(obj.TopicTree) && obj.CacheLoaded
                        %obj.updateSaveAppStateFile();
                        listofopenvisualizer = obj.VisualizerMapping;
                        obj.SkipUpdateCache = true; % skip updating the cache file
                        c = onCleanup(@()setrestoring(obj, 'SkipUpdateCache', false));
                        for indx =1:numel(listofopenvisualizer)
                            if isvalid(listofopenvisualizer(indx).Handle)
                                listofopenvisualizer(indx).Handle.Document.close; % close all visualizers if any
                            end
                        end
                        if isequal(obj.AppMode,obj.RosbagVisualization)
                            obj.BookmarkPanelObj.resetBookmarkTable;
                            obj.BookmarkTabObj.resetTable;
                        end
                        obj.AppContainer.DocumentGridDimensions = [1 1];
                        obj.LayoutFromCache = [];
                        obj.VisualizerInfo = [];
                        obj.CacheLoaded =  false;
                    end
                end
                obj.AppMode = obj.LiveRosTopicVisualization;
                changeAppMode(obj);
                
               

                obj.TopicTree = eventData.Data.Tree;
                createTopicTreeForLive(obj.TopicList, eventData.Data);
               
                % Create a transform util.
                obj.TransformManager = ros.internal.utils.AppTFUtil(obj.TopicTree.TfTree, obj.TopicTree.Helper);
                
                % refresh the DataSource dropdown and VisualizerMapping
                resetVisualizerMappingAndDataSource(obj,false);

                if isequal(eventData.Data.rosVer,'ros1')
                    networkDetails = ['ROS_MASTER_URI : ' eventData.Data.rosNetworkInput];
                else
                    networkDetails = ['ROS_DOMAIN_ID : ' num2str(eventData.Data.rosNetworkInput)];
                end

                obj.AppContainer.Title = [getString(message("ros:visualizationapp:view:AppTitle")) ' - ' networkDetails];

                if eventData.Data.HasCache
                    % parse the cache file data
                    obj.getAppCacheData(eventData.Data.CacheData);
                    % create visualizer from cache data
                    createVisualizerUsingCacheData(obj);
                end
                %obj.startPlayBack
            end
        end

        function updateAppWithLoadedRosbag(obj, eventData)
            %updateAppWithLoadedRosbag will update all the UI components of
            %the app with the loaded rosbag data.

            if ~isempty(eventData.Data.Error)
                throwError(obj, eventData.Data.Error);
            else
                obj.AppMode = obj.RosbagVisualization;
                changeAppMode(obj)
                obj.TopicTree = eventData.Data.Tree;

                obj.TransformManager = ros.internal.utils.AppTFUtil(obj.TopicTree.Rosbag, obj.TopicTree.RosbagHelper);
                % update TopicList Panel
                createTopicTree(obj.TopicList, obj.TopicTree);
                % refresh the DataSource dropdown and VisualizerMapping
                resetVisualizerMappingAndDataSource(obj);
                % reset the Time for NewBag
                resetTimeForNewBag(obj, eventData);
                % reset Timeline accordingly
                obj.Timeline.updateTimeSettings;
                % reset the automatic signal
                obj.AutomaticTopic = '';
                % parse the cache file data
                obj.getAppCacheData(eventData.Data.CacheData);
                % create visualizer from cache data
                createVisualizerUsingCacheData(obj);
                
            end
        end

        function resetVisualizerMappingAndDataSource(obj, ifResetVisualizer)
            %resetDataSource will referesh the DataSource dropdown items
            %for all the open visulizier with the loaded rosbag file

            if nargin < 2
                ifResetVisualizer = false;
            end

            % Reset the source manager
            obj.SourceManager.resetAllVisualizers;

            if ~isempty(obj.VisualizerMapping)
                for indx = 1: length(obj.VisualizerMapping)
                    visualizer = obj.VisualizerMapping(indx).Handle;
                    % reset the dropdown
                    updateDataSourceOptions(visualizer, obj.TopicTree);
                    
                    %Reset data sources for Marker visualizer.
                    if isequal(class(visualizer), 'ros.internal.MarkerVisualizer') ...
                            && ~isempty(obj.TopicTree) && ~isempty(obj.VisualizerSettingPanelObj)
                        compatibletopics = visualizer.getCompatibleTopics(obj.TopicTree);
                        obj.VisualizerSettingPanelObj.updateDataSource(compatibletopics);
                        obj.VisualizerSettingPanelObj.updateFrameIdDropdown(obj.TopicTree.getAvailableTfFrames());
                    end

                    if isequal(class(visualizer), 'ros.internal.ThreeDVisualizer') ...
                            && ~isempty(obj.TopicTree) && ~isempty(obj.ThreeDSettingsObj)

                        compatibletopics = visualizer.getCompatibleTopics(obj.TopicTree);
                        obj.ThreeDSettingsObj.updateDataSources(compatibletopics);
                        frames = obj.TopicTree.getAvailableTfFrames();
                        obj.ThreeDSettingsObj.updateFrameIdDropdown(frames);
                        
                        if ~isempty(frames)
                            obj.SourceManager.updateFrameID(visualizer.DataSourcesID, frames{1});
                        end
                    end

                    if ifResetVisualizer
                        % reset the graphics in the visualizer
                        visualizer.reinit();
                        % reset the VisualizerMapping Fields
                        obj.VisualizerMapping(indx).Topic = {};
                        obj.VisualizerMapping(indx).DataSource = {};
                    end
                end
            end
        end

        function createVisualizerUsingCacheData(obj)
            %createVisualizerUsingCacheData method is used to create the
            %visualizer and set the data source from the cache data

            % if the layout is not empty
            if isempty(obj.LayoutFromCache)
                obj.CacheLoaded =  true;
                return;
            else

                obj.RestoringCache = true; % set the flag that it is restoring the cache to avoid updating the cache file
                c = onCleanup(@()setrestoring(obj, 'RestoringCache', false));
                %get the original layout setting to reset incase there is an error
                originalgridDimension = obj.AppContainer.DocumentGridDimensions;
                originallayoutjson = obj.AppContainer.DocumentLayout;
                try
                    % set the layout
                    obj.AppContainer.DocumentGridDimensions = obj.LayoutFromCache.DocumentGridDimensions;
                    obj.AppContainer.DocumentLayout = obj.LayoutFromCache.LayoutJSON;
                    if isequal(obj.AppMode,obj.RosbagVisualization)
                        obj.BookmarkPanelObj.updateBookmarkTable(obj.BookmarkDataFromSession);
                        obj.BookmarkTabObj.BookmarkTableList = obj.BookmarkDataFromSession;
                        obj.BookmarkPanelObj.showBookmarkTable();
                        if ~isequal(obj.TagsDataFromSession, {''})
                            for indx =1:length(obj.TagsDataFromSession)
                                obj.AddTagsPanelObj.createTagComponent(obj.TagsDataFromSession{indx});
                            end
                        end
                    end
                    objWeakHndl = matlab.internal.WeakHandle(obj);
                    indx=1;
                    % create the visualizers and set the datasource value
                    while indx <= numel(obj.VisualizerInfo)
                        if any(strcmp({'ros.internal.XYPlotVisualizer', 'ros.internal.OdometryVisualizer', 'ros.internal.TimePlotVisualizer', 'ros.internal.MapVisualizer'}, ...
                                obj.VisualizerInfo(indx).VisualizerName))
                            isFullrange = true;
                        else
                            isFullrange = false;
                        end

                        ros.internal.ViewerPresenter.createVisualizer(objWeakHndl, ...
                            str2func(obj.VisualizerInfo(indx).VisualizerName), ...
                            obj.VisualizerInfo(indx).DataType, isFullrange);
                        previousValue = '';
                        % Create event data for 'ValueChanged'
                        if strcmp(obj.VisualizerInfo(indx).VisualizerName, 'ros.internal.XYPlotVisualizer')

                            newValue = obj.VisualizerInfo(indx).DataSource;
                            if ismember(newValue,obj.VisualizerMapping(indx).Handle.DataSources(1).Items)
                                obj.VisualizerMapping(indx).Handle.DataSources(1).Value = newValue;
                                valueChangedEventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
                                ros.internal.ViewerPresenter.dataSourceValueChanged(objWeakHndl, ...
                                    obj.VisualizerMapping(indx).Handle.DataSources(1), valueChangedEventData, ...
                                    obj.VisualizerMapping(indx).ID, obj.VisualizerMapping(indx).Handle.CompatibleTypes, isFullrange);
                            end
                            newValue = obj.VisualizerInfo(indx+1).DataSource;
                            if ismember(newValue,obj.VisualizerMapping(indx+1).Handle.DataSources(2).Items)
                                obj.VisualizerMapping(indx+1).Handle.DataSources(2).Value = newValue;
                                valueChangedEventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
                                ros.internal.ViewerPresenter.dataSourceValueChanged(objWeakHndl, ...
                                    obj.VisualizerMapping(indx+1).Handle.DataSources(2), valueChangedEventData, ...
                                    obj.VisualizerMapping(indx+1).ID, obj.VisualizerMapping(indx).Handle.CompatibleTypes, isFullrange);
                            end
                            indx = indx +1;
                        elseif strcmp(obj.VisualizerInfo(indx).VisualizerName, 'ros.internal.MarkerVisualizer')
                            %TO DO 
                                % set the checkbox tree
                                % set the frame id
                                obj.VisualizerSettingPanelObj.checkSpecificNodesByText(obj.VisualizerMapping(indx).DataSource);
                                newValue = obj.VisualizerInfo(indx).DataSource;
                                valueChangedEventData = matlab.ui.eventdata.CheckedNodesChangedData(newValue, previousValue);
                                ros.internal.ViewerPresenter.dataSourceValueChanged(objWeakHndl, ...
                                    obj.VisualizerSettingPanelObj.DataSourceTree, valueChangedEventData, ...
                                    obj.VisualizerMapping(indx).ID, obj.VisualizerMapping(indx).Handle.CompatibleTypes, ...
                                    isFullrange);
                        %g3455677 3D needs special handling to open from
                        %cache
                        elseif strcmp(obj.VisualizerInfo(indx).VisualizerName, 'ros.internal.ThreeDVisualizer')
                            sources = obj.VisualizerInfo(indx).DataSource;
                            for idx = 1:numel(sources)
                                source = sources(idx);
                                sourceProp = struct("ColorMode", 'Default', "Color", []);
                                obj.ThreeDSettingsObj.updateSourceProps(source, sourceProp);
                                row = obj.ThreeDSettingsObj.getSourceRow(source);
                               
                                if ~isempty(row)
                                    % Create mock event data. Only indices and NewData are
                                    % needed. Call the
                                    % dataSourceValueChanged function.
    
                                    eventData = struct("Indices", [row 1], "NewData", true);
                                    ros.internal.ViewerPresenter.dataSourceValueChanged(objWeakHndl, ...
                                        obj.ThreeDSettingsObj.DataSourceTable, eventData, ...
                                        obj.VisualizerMapping(indx).ID, obj.VisualizerMapping(indx).Handle.CompatibleTypes, ...
                                        isFullrange);
                                end
                            end
                        else
                            newValue = obj.VisualizerInfo(indx).DataSource;
                            if ismember(newValue,obj.VisualizerMapping(indx).Handle.DataSources.Items)
                                obj.VisualizerMapping(indx).Handle.DataSources.Value = newValue;
                                valueChangedEventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
                                ros.internal.ViewerPresenter.dataSourceValueChanged(objWeakHndl, ...
                                    obj.VisualizerMapping(indx).Handle.DataSources, valueChangedEventData, ...
                                    obj.VisualizerMapping(indx).ID, obj.VisualizerMapping(indx).Handle.CompatibleTypes, ...
                                    isFullrange);
                            end
                        end
                        indx = indx+1;
                        obj.CacheLoaded = true;
                    end
                 catch ME 
                    ME.getReport();
                    obj.AppContainer.DocumentGridDimensions = originalgridDimension;
                    obj.AppContainer.DocumentLayout = originallayoutjson;
                    obj.RestoringCache = false;
                    obj.CacheLoaded = true; % We tried to load cache but failed.
                                            % This flag is checked when we
                                            % close visualizers before
                                            % opening a new bagfile.
                    return; % use the default layout
                end
            end
        end % END createVisualizerUsingCacheData

        function getAppCacheData(obj, dataIn)
            % getAppCacheData
            if ~isempty(dataIn)
                obj.LayoutFromCache = dataIn.layoutInfo;
                obj.VisualizerInfo = dataIn.visualizerInfo;
                obj.BookmarkDataFromSession = dataIn.bookmarkData;
                obj.TagsDataFromSession = dataIn.tags;
            end
        end

        function throwErrorAsDialog(obj, eventData)
            %throwErrorAsDialog function is used to throw an error from
            % the event as UI Alert.

            bringToFront(obj.AppContainer);
            obj.UIAlert.run(obj.AppContainer, ...
                eventData.Data.Error.message, ...  % message
                getString(message('ros:visualizationapp:view:TextError')), ... % title
                'Icon', 'error');
        end

        function throwError(obj, errorMessage)
            %throwError function is used to throw an error from
            % the function callback

            bringToFront(obj.AppContainer);
            obj.UIAlert.run(obj.AppContainer, ...
                errorMessage.message, ...  % message
                getString(message('ros:visualizationapp:view:TextError')), ... % title
                'Icon', 'error');
        end

        function throwWarning(obj, topic, visualizer, timestamp, mlException)
            %throwWarning function is used to throw an warning on ML

            backtracestate = warning('off', 'backtrace');
            b = onCleanup(@() warning(backtracestate.state, 'backtrace'));
            verbosestate = warning('off', 'verbose');
            v = onCleanup(@() warning(verbosestate.state, 'verbose'));
            if isequal(obj.AppMode,obj.RosbagVisualization)
                msg = [getString(message('ros:visualizationapp:view:TimeStampLabel')) ': '...
                    sprintf('%9.9f', timestamp) newline ...
                    getString(message('ros:visualizationapp:view:DataSourceLabel')) ': ' ...
                    char(topic) newline ...
                    getString(message('ros:visualizationapp:view:VisualizersLabel')) ': ' ...
                    visualizer newline mlException.message];
            else
                msg = [getString(message('ros:visualizationapp:view:DataSourceLabel')) ': ' ...
                    char(topic) newline ...
                    getString(message('ros:visualizationapp:view:VisualizersLabel')) ': ' ...
                    visualizer newline mlException.message];
            end
            warning(mlException.identifier, msg);
        end

        function resetTimeForNewBag(obj, eventData)
            %resetTimeForNewBag Set up timeline for new rosbag

            % Set time limits
            if ~isempty(eventData.Data.Error)
                return;
            end

            tStart = eventData.Data.Rosbag.StartTime;
            tEnd = eventData.Data.Rosbag.EndTime;
            setTimeLimits(obj.Timeline, tStart, tEnd)

            % Set title
            [~, fName, fExt] = fileparts(eventData.Data.Rosbag.FilePath);
            obj.AppContainer.Title = [getString(message("ros:visualizationapp:view:AppTitle")) ' - ' fName fExt];

            % Set topics to main signal options
            topicList = convertCharsToStrings(eventData.Data.Tree.Topics);
            updateSignalOptions(obj.Timeline, topicList)
        end

        function updateVisualizers(obj, eventData)
            %TODO (g3437016): v2, update visualizer definition in base
            %class to accept varargin.
            %updateVisualizers Distribute new messages to relevant visualizers

            if ~isVisualizerLoadedWithTopicForPlayback(obj)
                stopPlayBack(obj)
                return;
            end

            crPgIdHdle = obj.VisualizerMapping(1).Handle.launchCircularProgressIndicator;
            c = onCleanup(@()delete(crPgIdHdle));

            % filtering out the unique topics to avoid repeated updating of
            % data
            eventData.Data.TopicData = filterRepeatedTopics(eventData.Data.TopicData);
            
            clearAxesFlags = true(size(obj.VisualizerMapping));
            for iTopic = 1:numel(eventData.Data.TopicData)

                data = eventData.Data.TopicData(iTopic);

                % Add the timestamp to the source-specific data passed
                if isequal(obj.AppMode,obj.RosbagVisualization)
                    data.Time = eventData.Data.Time;
                end

                % Find the appropriate visualizers for the data source
                %whichSources = arrayfun(@(visMap) strcmp(data.Topic, visMap.DataSource) && strcmp(data.DataType, visMap.DataType), ...
                %   obj.VisualizerMapping);
                whichSources = arrayfun(@(visMap) any(strcmp(data.Topic, visMap.DataSource)) && ...
                    (strcmp(data.DataType, visMap.DataType) || strcmp(visMap.DataType, "3d")), ...
                    obj.VisualizerMapping);
                visualizerMappingSubset = obj.VisualizerMapping(whichSources);

                for iVis = 1:numel(visualizerMappingSubset)
                    % check if there is any error in data
                    if isempty(eventData.Data.TopicData(iTopic).Error)
                        try
                            if isa(visualizerMappingSubset(iVis).Handle,  'ros.internal.MarkerVisualizer')
                                dataSources = visualizerMappingSubset(iVis).DataSource;
                                % Find the index where Topic is '1'
                                index = strcmp(visualizerMappingSubset(iVis).Topic, eventData.Data.TopicData(iTopic).Topic);

                                % Use the index to retrieve the corresponding DataSource
                                dataSourceWhenTopicIsOne = dataSources{index};

                                % Apply transformation
                                frame_id =  getFrameID(obj.SourceManager, visualizerMappingSubset(iVis).Handle.DataSourcesID);
                                transformedData = data;
                                if ~isempty(frame_id)
                                    transformedData.Message = obj.TransformManager.transform(data.Message, data.DataType, frame_id);
                                end

                                % Call updateData with the clearAxes flag set to true only for the last DataSource
                                updateData(visualizerMappingSubset(iVis).Handle, ...
                                    dataSourceWhenTopicIsOne, ...
                                    transformedData, ...
                                    clearAxesFlags(iVis));
                                clearAxesFlags(iVis) = false;
                            
                            elseif isa(visualizerMappingSubset(iVis).Handle, 'ros.internal.ThreeDVisualizer')
                                dataSources = visualizerMappingSubset(iVis).DataSource;
                                % Find the index where Topic is '1'
                                index = strcmp(visualizerMappingSubset(iVis).Topic, eventData.Data.TopicData(iTopic).Topic);

                                % Use the index to retrieve the corresponding 
                                % DataSource
                                dataSourceWhenTopicIsOne = dataSources{index};

                                source_props = obj.SourceManager.getSource(visualizerMappingSubset(iVis).Handle.DataSourcesID, ...
                                    dataSourceWhenTopicIsOne);
                                % data = obj.ThreeDModel.transformMessage(visualizerMappingSubset(iVis).Handle.DataSourcesID, data);
                                frame_id =  getFrameID(obj.SourceManager, visualizerMappingSubset(iVis).Handle.DataSourcesID);
                                transformedData = data;
                                if ~isempty(frame_id)
                                    transformedData.Message = obj.TransformManager.transform(data.Message, data.DataType, frame_id);
                                end
                                updateData(visualizerMappingSubset(iVis).Handle, ...
                                    dataSourceWhenTopicIsOne, ...
                                    transformedData, ...
                                    source_props);
                            else
                                updateData(visualizerMappingSubset(iVis).Handle, ...
                                    visualizerMappingSubset(iVis).DataSource, ...
                                    data)

                            end
                        catch ex
                            if isequal(obj.AppMode,obj.RosbagVisualization)
                                obj.throwWarning(eventData.Data.TopicData(iTopic).Topic, ...
                                    visualizerMappingSubset(iVis).Handle.InitialTitle, ...
                                    eventData.Data.Time, ex);
                            elseif isequal(obj.AppMode,obj.LiveRosTopicVisualization)
                                obj.throwWarning(eventData.Data.TopicData(iTopic).Topic, ...
                                    visualizerMappingSubset(iVis).Handle.InitialTitle, ...
                                    0, ex);
                            end
                        end
                    elseif isequal(obj.AppMode,obj.RosbagVisualization)
                        obj.throwWarning(eventData.Data.TopicData(iTopic).Topic, ...
                            visualizerMappingSubset(iVis).Handle.InitialTitle, ...
                            eventData.Data.Time, eventData.Data.TopicData(iTopic).Error);
                    elseif isequal(obj.AppMode,obj.LiveRosTopicVisualization)
                        obj.throwWarning(eventData.Data.TopicData(iTopic).Topic, ...
                            visualizerMappingSubset(iVis).Handle.InitialTitle, ...
                            0, eventData.Data.TopicData(iTopic).Error);
                    end
                end
            end

            if isequal(obj.AppMode,obj.RosbagVisualization)
                curTime = eventData.Data.Time;
                setCurrentTime(obj.Timeline, curTime);

                if isfield(eventData.Data,'MainSignalStartTime') && ...
                        isfield(eventData.Data,'MainSignalEndTime')
                    tStart = eventData.Data.MainSignalStartTime;
                    tEnd = eventData.Data.MainSignalEndTime;
                    if ~(obj.PlaybackState && ...
                            ((curTime < tEnd && isequal(obj.PlaybackDirection,obj.ForwardPlayback)) || ...
                            (curTime > tStart && isequal(obj.PlaybackDirection,obj.ReversePlayback))))

                        % Request the timer to stop the playback
                        obj.PlaybackState = false;
                    end
                end
            end
        end

        function updateVisualizersWithDataRange(obj, eventData)
            %updateVisualizersWithDataRange Pass full bag of data to visualizer
            %   Visualizers that display a subset of data from all messages in
            %   a rosbag need all that data for display at once.

            % following lines of code is used to handle the race condition
            % that occurs while loading the cache file with xy data . In XY
            % this event call is triggered back to back in short span of
            % time which is leading to race condition and dropping the
            % second event.
            if obj.ProcessingFlag
                waitfor(obj, 'ProcessingFlag', false);
            end
            obj.ProcessingFlag = true;
            c = onCleanup(@()setrestoring(obj, 'ProcessingFlag', false));

            crPgIdHdle = obj.VisualizerMapping(1).Handle.launchCircularProgressIndicator;
            c = onCleanup(@()delete(crPgIdHdle));
            dataSource = eventData.Data.DataSource;
            dataArray = eventData.Data.Data;
            timeArray = eventData.Data.Time;
            fieldMap = eventData.Data.FieldMap;

            % Find the appropriate visualizers for the data source
            whichVisualizers = arrayfun(@(visMap) strcmp(dataSource, visMap.DataSource), ...
                obj.VisualizerMapping);
            visualizerMappingSubset = obj.VisualizerMapping(whichVisualizers);
            for iVis = 1:numel(visualizerMappingSubset)
                setFullData(visualizerMappingSubset(iVis).Handle, dataSource, dataArray, timeArray, fieldMap)
            end
        end

        function updateSaveAppStateFile(obj)
            %updateSaveAppStateFile method is used to update the cache file
            %with the new information. this is called when a new visualizer
            %is created, or exisitng visualizer is closed, app is closed,
            %datasource value is changed.
            if obj.SkipUpdateCache
                return;
            end
            try
                if ~obj.RestoringCache
                    layoutjson = obj.AppContainer.DocumentLayout;
                    layout = struct("LayoutJSON", layoutjson, ...
                        "DocumentGridDimensions", obj.AppContainer.DocumentGridDimensions);
                    visualizers = struct("VisualizerName", arrayfun(@(x)class(obj.VisualizerMapping(x).Handle), 1:numel(obj.VisualizerMapping),'UniformOutput',false), ...
                        "DataSource", arrayfun(@(x)obj.VisualizerMapping(x).DataSource, 1:numel(obj.VisualizerMapping),'UniformOutput',false), ...
                        "DataType", arrayfun(@(x)obj.VisualizerMapping(x).DataType, 1:numel(obj.VisualizerMapping),'UniformOutput',false));
                    if isequal(obj.AppMode,obj.RosbagVisualization)
                        rosbaginfo = dir(obj.TopicTree.Rosbag.FilePath);
                    elseif isequal(obj.AppMode,obj.LiveRosTopicVisualization)
                        rosbaginfo = obj.TopicTree.Network;
                    end
                    bookmarkdata = obj.BookmarkTabObj.BookmarkTableList;
                    if isempty(obj.AddTagsPanelObj.TagsHandleTab)
                        tagsdata = '';
                    else
                        tagsdata = obj.AddTagsPanelObj.TagsHandleTab.TagValue;
                    end
                    eventDataOutStruct = struct("RosbagInfo", rosbaginfo, ...
                        "Layout", layout, ...
                        "VisualizerInfo", visualizers, ...
                        "BookmarkData", bookmarkdata, ...
                        "TagsData", tagsdata);
                    eventDataOutStruct = ros.internal.EventDataContainer(eventDataOutStruct);
                    notify(obj.EventObject, "UpdateAppSessionCachePM", eventDataOutStruct);
                end
            catch ME 
                return;
            end
        end

        function openSelectedRosbag(obj, fileFullPath)

            if isempty(fileFullPath)
                return;
            end
            if ~exist(fileFullPath) %#ok<EXIST>
                errmsg.message = getString(message("ros:visualizationapp:view:FileNotExist", fileFullPath));
                throwError(obj, errmsg);
                return;
            end

            [dirName, fileName, ext] = fileparts(fileFullPath);
            fileName = [fileName, ext];

            if ~isequal(fileName, 0) && ...
                    (isempty(obj.TopicTree) || ...
                    ~isequal(obj.AppMode,obj.RosbagVisualization) || ...
                    ~isequal(fullfile(dirName,fileName), obj.TopicTree.Rosbag.FilePath))

                % If playback is going on, stop it before loading the bag file
                if obj.PlaybackState
                    stopPlayBack(obj);
                end

                if obj.EnableSaveAppState
                    % is the bag is already loaded clear all the
                    % visualizers
                    if ~isempty(obj.TopicTree) && obj.CacheLoaded
                        obj.updateSaveAppStateFile();
                        listofopenvisualizer = obj.VisualizerMapping;
                        obj.SkipUpdateCache = true; % skip updating the cache file
                        c = onCleanup(@()setrestoring(obj, 'SkipUpdateCache', false));
                        for indx =1:numel(listofopenvisualizer)
                            if isvalid(listofopenvisualizer(indx).Handle)
                                listofopenvisualizer(indx).Handle.Document.close; % close all visualizers if any
                            end
                        end
                        obj.AppContainer.DocumentGridDimensions = [1 1];
                        obj.LayoutFromCache = [];
                        obj.VisualizerInfo = [];
                        obj.CacheLoaded =  false;
                    end
                    if isequal(obj.AppMode,obj.RosbagVisualization)
                        obj.BookmarkPanelObj.resetBookmarkTable;
                        obj.BookmarkTabObj.resetTable;
                        obj.AddTagsPanelObj.resetTagPanel();
                        obj.resetCacheProperties();
                    end
                end

                % File selection was not canceled
                filePath = fullfile(dirName, fileName);

                filePathArr = split(dirName,filesep);
                bagDirName = filePathArr{end};
                if isempty(bagDirName)
                    bagDirName = filePathArr{end-1}; %Parent folder of the file
                end

                obj.LastOpenedBagPath = dirName;

                % Show progress bar until bag file is loaded
                d = obj.UIProgress.run(obj.AppContainer, 'Message', ...
                    getString(message('ros:visualizationapp:view:LoadRosbagFile', ...
                    fullfile(bagDirName,fileName))));
                c = onCleanup(@() delete(d));

                eventDataStruct = struct("FilePath", filePath);
                eventDataStruct = ros.internal.EventDataContainer(eventDataStruct);
                notify(obj.EventObject, "RosbagSelectedPM", eventDataStruct);
                if strcmp(obj.AppMode, "RosbagVisualization")
                    obj.AppContainer.RightCollapsed = 0;
                    obj.AppContainer.RightCollapsed = 1;
                end
            end

        end

        function searchBagAlgorithm(obj)
            cacheFieldName = {'tags', 'bookmarks', 'visualizerTypes'};
            objectName = {'TagPanelObj', 'BookmarkPanelObj', 'VisualizerPanelObj'};
            BagPathArray = [];
            % check if the any or all the active filter have data and
            % get active filter array and search the bag file
            if ~isequal((strsplit(obj.SearchRosbagAppObj.TagPanelObj.Value{1},';')), {''}) ...
                    || ~isequal((strsplit(obj.SearchRosbagAppObj.BookmarkPanelObj.Value{1},';')), {''}) ...
                    || ~isequal((strsplit(obj.SearchRosbagAppObj.VisualizerPanelObj.Value{1},';')), {''})
                for indx = 1: numel(cacheFieldName)
                    activeFilter = strsplit(obj.SearchRosbagAppObj.(objectName{indx}).Value{1}, ';');
                    if ~isequal(activeFilter, {''})
                        for i = 1:numel(activeFilter)
                            if isempty(activeFilter{i})
                                continue;
                            end
                            jindx = ros.internal.utilities.findElement(obj.CacheDataForSearch.(cacheFieldName{indx}), activeFilter{i});
                            if ~isempty(jindx)
                                for jjindx=1:length(jindx)
                                    BagPathArray = [BagPathArray, obj.CacheDataForSearch.bagPaths(jindx{jjindx}(1))]; %#ok<AGROW>
                                end
                            end

                        end
                    end
                end
                if isempty(BagPathArray)
                    obj.SearchRosbagAppObj.updateResultsTableData({});
                else
                    obj.SearchRosbagAppObj.updateResultsTableData(unique(BagPathArray)');
                end
            else
                %Cache table will always be present if this function is
                %called.
                BagPathArray = obj.CacheDataForSearch.bagPaths;
                obj.SearchRosbagAppObj.updateResultsTableData(unique(BagPathArray));
            end
        end
    end %END Method

    methods (Static, Access = ?ros.internal.mixin.ROSInternalAccess)    % UI Callbacks
        function openRosbag(objWeakHndl)
            %openRosbag Open file selection for rosbag and initiate loading

            obj = objWeakHndl.get;

            if isempty(obj.LastOpenedBagPath)
                obj.LastOpenedBagPath = '';
            end

            title = getString(message("ros:visualizationapp:view:OpenDialogTitle"));
            rosbagFileFilter = getString(message("ros:visualizationapp:view:RosbagFileFilter"));
            ros2bagFileFilter = getString(message("ros:visualizationapp:view:Ros2bagFileFilter"));
            rosRos2bagFileFilter = getString(message("ros:visualizationapp:view:RosRos2bagFileFilter"));
            allFileFilter = getString(message("ros:visualizationapp:view:AllFileFilter"));

            filter = { '*.bag;*.db3;*.mcap;metadata.yaml',rosRos2bagFileFilter; ...
                '*.bag',rosbagFileFilter; ...
                '*.db3;*.mcap;metadata.yaml',ros2bagFileFilter; ...
                '*.*',allFileFilter};
            [fileName, dirName] = uigetfile(filter, title, obj.LastOpenedBagPath);

            % Workaround for app going behind MATLAB
            bringToFront(obj.AppContainer);
            if ~isequal(fileName, 0)
                obj.openSelectedRosbag([dirName, fileName])
            end

        end

        function documentSelectionChanged(objWeakHndl, src, evt)
            %documentSelectionChanged
            obj = objWeakHndl.get;
            obj.Toolstrip.disableToolsSection();
            if isequal(evt.PropertyName, 'LastSelected')
                % Assuming the tag you are looking for is 'Tag'
                desiredTag = src.LastSelected.tag;
                if isempty(obj.VisualizerMapping)
                    return;
                end
                % Iterate through each element in the VisualizerMapping array
                for k = 1:length(obj.VisualizerMapping)
                    % Access the Document's Tag property
                    currentTag = obj.VisualizerMapping(k).Handle.Document.Tag;

                    % Check if the current tag matches the desired tag
                    if strcmp(currentTag, desiredTag)
                        % If there's a match, do something
                        obj.LastVizID = obj.VisualizerMapping(k).Handle.DataSourcesID;
                        if isa(obj.VisualizerMapping(k).Handle,  'ros.internal.MarkerVisualizer')
                            obj.VisualizerSettingPanelObj.checkSpecificNodesByText(cellstr(obj.VisualizerMapping(k).DataSource));
                            frameId = obj.SourceManager.getFrameID(obj.LastVizID);
                            if ~isempty(frameId) %Simple guard to ensure only a valid frameId is set.
                                obj.VisualizerSettingPanelObj.updateFrameIdValue(frameId);
                            end
                            obj.Toolstrip.enableToolsSection();
                        end

                        if isa(obj.VisualizerMapping(k).Handle, 'ros.internal.ThreeDVisualizer')
                            sources = obj.SourceManager.getSources(obj.LastVizID);
                            obj.ThreeDSettingsObj.reset();

                            for idx = 1:numel(sources)
                                source = sources{idx};
                                props = obj.SourceManager.getSource(obj.LastVizID, source);
                                obj.ThreeDSettingsObj.updateSourceProps(source, props);
                                obj.Toolstrip.enableOnlyViewTool();
                            end

                            frameId = obj.SourceManager.getFrameID(obj.LastVizID);
                            obj.ThreeDSettingsObj.updateFrameIdValue(frameId);
                        end
                        break;
                    end
                end

            end
        end

        function inputRosNetwork(objWeakHndl, networkType)
            obj = objWeakHndl.get;

            fig = uifigure('Position',[500 500 430 200],'WindowStyle','modal');
            matlab.graphics.internal.themes.figureUseDesktopTheme(fig);
            fig.Name = getString(message("ros:visualizationapp:view:EnterNetworkDetails"));
            if isequal(networkType,'ros1')
                inputTypeString = getString(message("ros:visualizationapp:view:ROSMasterURI"));
                prefName = obj.LastUsedROSMasterURIs;
                defaultNetworkInput = 'http://localhost:11311';
            else
                inputTypeString = getString(message("ros:visualizationapp:view:ROSDomainID"));
                prefName = obj.LastUsedROSDomainIDs;
                defaultNetworkInput = '0';
            end
            uilabel(fig,...
                'Position',[100 150 215 15],...
                'Text',inputTypeString,'HorizontalAlignment','center','Tag','NetworkTypeLabel');

            % Load last time used sources from preference
            prefNetworkInput = {};
            if ispref(obj.PrefGroup,prefName)
                prefNetworkInput = getpref(obj.PrefGroup,prefName);
            end


            if ~ismember(defaultNetworkInput,prefNetworkInput)
                prefNetworkInput{end+1} = defaultNetworkInput;
                if numel(prefNetworkInput) >10
                    prefNetworkInput(1) = [];
                end
            end

            textarea = uidropdown(fig,...
                'Position',[100 100 215 30]);
            textarea.Items = prefNetworkInput;
            textarea.Value = defaultNetworkInput;
            textarea.Tag = 'LiveROSNetwork';
            textarea.Editable = 'on';
            uibutton(fig, ...
                "Text",getString(message("ros:visualizationapp:view:SubmitDetails")),...
                "ButtonPushedFcn",@(src,event)rosNetworkDetailsEntered(obj,textarea,fig),...
                'Position',[100 50 215 30]);

            function rosNetworkDetailsEntered(obj,textarea,fig)
                if obj.PlaybackState
                    stopPlayBack(obj);
                end
                if obj.EnableSaveAppState
                    if ~isempty(obj.TopicTree) && obj.CacheLoaded
                        obj.updateSaveAppStateFile();
                    end
                end

                if ~ismember(textarea.Value, prefNetworkInput)
                    prefNetworkInput{end+1} = textarea.Value;

                    if numel(prefNetworkInput) >10
                        prefNetworkInput(1) = [];
                    end
                end

                networkInput = textarea.Value;
                close(fig);

                if isequal(networkType,'ros1')
                    messageStr = getString(message('ros:visualizationapp:view:ConnectRos1Network', networkInput));
                else
                    messageStr = getString(message('ros:visualizationapp:view:ConnectRos2Network', networkInput));
                end
                % Show progress bar until bag file is loaded
                d = obj.UIProgress.run(obj.AppContainer, 'Message',messageStr);
                c = onCleanup(@() delete(d));

                data.NetworkInput = networkInput;
                data.NetworkType = networkType;
                eventData = ros.internal.EventDataContainer(data);
                notify(obj.EventObject, "InputRosNetworkPM", eventData);
                setpref(obj.PrefGroup,prefName,prefNetworkInput);
            end
        end

        %Function to refresh topic list
        function refreshTopicList(objWeakHndl)
            obj = objWeakHndl.get;
            eventData = ros.internal.EventDataContainer([]);
            notify(obj.EventObject, "InputRosNetworkPM", eventData);
        end

        function searchRosbagCallback(objWeakHndl)
            %searchRosbagCallback callback for search rosbag button
            obj = objWeakHndl.get;
            %read cache files
            cachedata = ros.internal.utils.readAppCacheFiles;
            % filter live network data
            % Find rows where 'bagPath' contains 'http'

            tagItems = {' '};
            bmItems = {' '};
            bagPath = {};
            if ~isempty(cachedata)
                rowsToRemove = contains(cachedata.bagPaths, 'http');
                cachedata(rowsToRemove, :) = [];
                obj.CacheDataForSearch = cachedata;
                tagItems = ros.internal.utilities.removeEmptyElement(ros.internal.utilities.flattenNestedCellArray(cachedata.tags));
                tagItems = [' ', tagItems];

                bmItems = ros.internal.utilities.removeEmptyElement(ros.internal.utilities.flattenNestedCellArray(cachedata.bookmarks));
                bmItems = [' ', bmItems];

                bagPath = cachedata.bagPaths;
            end
            obj.SearchRosbagAppObj = ros.internal.view.UISearchRosbag;
            obj.SearchRosbagAppObj.TagSFListBoxObj.ValueChangedFcn = @(src, event) ros.internal.ViewerPresenter.listValueChangedCallbackFcn(objWeakHndl, src, event, obj.SearchRosbagAppObj.TagPanelObj);
            obj.SearchRosbagAppObj.BookmarkSFListBoxObj.ValueChangedFcn =  @(src, event) ros.internal.ViewerPresenter.listValueChangedCallbackFcn(objWeakHndl, src, event, obj.SearchRosbagAppObj.BookmarkPanelObj);
            obj.SearchRosbagAppObj.VisualizerSFListBoxObj.ValueChangedFcn =  @(src, event) ros.internal.ViewerPresenter.listValueChangedCallbackFcn(objWeakHndl, src, event, obj.SearchRosbagAppObj.VisualizerPanelObj);
            obj.SearchRosbagAppObj.ResultsTableObj.CellSelectionCallback =  @(src, event) ros.internal.ViewerPresenter.resultTableClickedFcn(objWeakHndl, src, event);
            obj.SearchRosbagAppObj.ClearTagTextAreaButtonObj.ButtonPushedFcn = @(source, event) ros.internal.ViewerPresenter.onClickClearTextAreaButton(objWeakHndl, source, event, obj.SearchRosbagAppObj.TagPanelObj);
            obj.SearchRosbagAppObj.ClearBMTextAreaButtonObj.ButtonPushedFcn = @(source, event) ros.internal.ViewerPresenter.onClickClearTextAreaButton(objWeakHndl, source, event, obj.SearchRosbagAppObj.BookmarkPanelObj);
            obj.SearchRosbagAppObj.ClearVisualizerTextAreaButtonObj.ButtonPushedFcn = @(source, event) ros.internal.ViewerPresenter.onClickClearTextAreaButton(objWeakHndl, source, event, obj.SearchRosbagAppObj.VisualizerPanelObj);
            obj.SearchRosbagAppObj.ExportToCSVResultsAreaButtonObj.ButtonPushedFcn = @(source, event) ros.internal.ViewerPresenter.exportButtonClicked(objWeakHndl);


            obj.SearchRosbagAppObj.updateTagItems(unique(tagItems));
            obj.SearchRosbagAppObj.updateBmItems(unique(bmItems));
            obj.SearchRosbagAppObj.updateResultsTableData(bagPath);
            obj.SearchRosbagAppObj.showApp();
        end

        function listValueChangedCallbackFcn(objWeakHndl, source, event, textareaobj)
            % listValueChangedCallbackFcn - Handle list value change event

            % Extract the object from the weak handle
            obj = objWeakHndl.get;

            % Get the current text from the textarea object
            currentText = textareaobj.Value{1};

            % Split the current text into an array of values
            currentValues = strsplit(currentText, ';');

            % Get the new value from the event
            newValue = event.Value;

            % Check if the new value is not already in the list
            if ~any(ismember(currentValues, newValue))
                % Add the new value to the text area
                newVal = [currentText, newValue, ';'];
                textareaobj.Value = newVal;
            end

            % Reset the source value
            source.Value = ' ';

            % Check if CacheDataForSearch is empty
            if isempty(obj.CacheDataForSearch)
                return;
            else
                % Perform the search algorithm
                obj.searchBagAlgorithm();
            end
        end

        function resultTableClickedFcn(objWeakHndl, source, event)
            %resultTableClickedFcn

            obj = objWeakHndl.get;
            filePath = source.Data(event.DisplayIndices(1));

            % Remove "href" using regular expressions
            filePath = regexprep(filePath{1}, '<a\s+href="[^"]*">', '');
            filePath = regexprep(filePath, '</a>', '');
            %load the rosbag
            obj.openSelectedRosbag(filePath);
            %close the search app
            obj.SearchRosbagAppObj.closeApp();
        end

        function exportButtonClicked(objWeakHdl)
            % exportButtonClicked callback for export button on searchBag
            % UI
            obj = objWeakHdl.get;
            
            searchResults = obj.SearchRosbagAppObj.ResultsTableObj.Data;
            cachedata = ros.internal.utils.readAppCacheFiles();
            
           
            % Export data, RosbagSearchData
            [csvFilename, csvFilepath] = uiputfile('*.csv', ...
                getString(message('ros:visualizationapp:view:ExportFilePickerTitle')), ...
                'data.csv');
            if ~isequal(csvFilename, 0)
                fullPath = fullfile(csvFilepath, csvFilename);
                try
                    ros.internal.utils.filterLinksAndExportToCSV(searchResults, cachedata, fullPath);
                catch ME
                    obj.throwError(ME);
                    obj.SearchRosbagAppObj.closeApp();
                end
            end
        end

        function onClickClearTextAreaButton(objWeakHndl, ~, ~, textareaobj)
            %onClickClearTextAreaButton
            obj = objWeakHndl.get;
            % clear the selected textarea
            textareaobj.Value = {''};
            % Search Algorithm

            % Search only if Cache is present
            if istable(obj.CacheDataForSearch)
                obj.searchBagAlgorithm();
            end
        end

        function createVisualizer(objWeakHndl, constructorFcn, type, isFullRange)
            %createVisualizer Create document and initialize specified visualizer
            %   The constructorFcn argument is the specific visualizer constructor.
            %   The type argument is related to the data to be displayed.

            obj = objWeakHndl.get;
            visualizer = constructorFcn(obj.AppContainer, obj.TagDocGroup, obj.AppMode);
            visualizer.DataSourceChangedCallback = ...
                @(src, valueChangedEventData, id) ros.internal.ViewerPresenter.dataSourceValueChanged(...
                objWeakHndl, ...
                src, valueChangedEventData, id, ...
                visualizer.CompatibleTypes, isFullRange);
            % If marker visualizer do not update the datasource dropdown.
            if ~strcmp(type, "marker") && ~strcmp(type, "3d")
                updateDataSourceOptions(visualizer, obj.TopicTree);
            end
            for k = 1:numel(visualizer.DataSourcesID)
                addDataSourceToMapping(obj, visualizer.DataSourcesID(k), visualizer, type)
            end
            visualizer.CloseCallback = ...
                @(~, ~) ros.internal.ViewerPresenter.removeDataSourcesFromMapping(objWeakHndl, visualizer.DataSourcesID);
            %TO DO
            % % add code to open the visualizer setting tab if type is marker
            % % visualizer
            if strcmp(type, "marker")
                obj.SourceManager.addVisualizer(visualizer.DataSourcesID, '');
                if isempty(obj.VisualizerSettingPanelObj)
                    obj.VisualizerSettingPanelObj = ros.internal.view.VisualizerSettings(obj.AppContainer);
                    %Visualizer Settings  callback
                    obj.VisualizerSettingPanelObj.DataSourceNodesCheckedFcn = @(source, event) ...
                        ros.internal.ViewerPresenter.dataSourceValueChanged(...
                        objWeakHndl, source, event, visualizer.DataSourcesID, visualizer.CompatibleTypes, isFullRange);
                    obj.VisualizerSettingPanelObj.FrameIDValueChangedFcn = @(source, event) ros.internal.ViewerPresenter.frameIdValueChanged(objWeakHndl, source, event);

                else
                    obj.VisualizerSettingPanelObj.resetDataSourceTreeRoot();
                end
                if  ~isempty(obj.TopicTree)
                    compatibletopics = visualizer.getCompatibleTopics(obj.TopicTree);
                    obj.VisualizerSettingPanelObj.updateDataSource(compatibletopics);
                    obj.VisualizerSettingPanelObj.updateFrameIdDropdown(obj.TopicTree.getAvailableTfFrames());
                    frames = obj.TopicTree.getAvailableTfFrames();
                    if ~isempty(frames)
                        obj.SourceManager.updateFrameID(visualizer.DataSourcesID, frames{1});
                    end
                end
                obj.Toolstrip.enableToolsSection();
            end
            
            if strcmp(type, "3d")
                % Add visualizer with the empty base frame_id to the model
                obj.SourceManager.addVisualizer(visualizer.DataSourcesID, '');
                obj.LastVizID = visualizer.DataSourcesID;
               
                if isempty(obj.ThreeDSettingsObj)
                    % 3D Settings callbacks
                    obj.ThreeDSettingsObj = ros.internal.ThreeDSettingsPanel(obj.AppContainer);
                    obj.ThreeDSettingsObj.TableCellEditCallback = @(source, event) ...
                            ros.internal.ViewerPresenter.dataSourceValueChanged(...
                            objWeakHndl, source, event, visualizer.DataSourcesID, visualizer.CompatibleTypes, isFullRange);
                    obj.ThreeDSettingsObj.TableCellSelectionCallback = @(source, event) ros.internal.ViewerPresenter.threeDTtableSelect(objWeakHndl, source, event);
                    obj.ThreeDSettingsObj.FrameIDValueChangedFcn = @(source, event) ros.internal.ViewerPresenter.threeDFrameIdUpdated(objWeakHndl, source, event);
                else
                    obj.ThreeDSettingsObj.resetDataSources();
                end
                
                if ~isempty(obj.TopicTree)
                    compatibletopics = visualizer.getCompatibleTopics(obj.TopicTree);
                    obj.ThreeDSettingsObj.updateDataSources(compatibletopics);
                    frames = obj.TopicTree.getAvailableTfFrames();
                    obj.ThreeDSettingsObj.updateFrameIdDropdown(frames);

                    if ~isempty(frames)
                        obj.SourceManager.updateFrameID(visualizer.DataSourcesID, frames{1});
                    end
                end
                obj.Toolstrip.enableOnlyViewTool;
            end

            if obj.EnableSaveAppState
                if ~isempty(obj.TopicTree)
                    obj.updateSaveAppStateFile();
                end
            end
        end

        function dataSourceValueChanged(objWeakHndl, ...
                source, valueChangedEventData, dataSourceID, ...
                compatibleTypes, isFullRange)
            %dataSourceValueChanged Update mapping of visualizer to topics
            %   The source will be the data source selection field.
            %   The compatible types will come from the visualizer type.
            %   The data source ID is in the visualizer topic mapping.
            %   The full range boolean indicates if it is necessary to extract
            %   the data range from the bag to initialize the display.
            
            % Return early if any other field is edited in 3D settings
            % table or callback is called with ill defined indices
            event = valueChangedEventData;
            toReturnEarly = false;
            obj = objWeakHndl.get;
            if isa(source, 'matlab.ui.control.Table')
                if numel(event.Indices) >= 2
                    col = event.Indices(2);
                    row = event.Indices(1);
                    if col == 3
                        toReturnEarly = true;
                        if isequal(event.NewData, 'Default')
                            obj.ThreeDSettingsObj.removeStyle(row);

                            source_prop = struct('ColorMode', 'Default', 'Color', []);
                            obj.SourceManager.updateSource(obj.getSelectVizId(), ...
                                obj.ThreeDSettingsObj.getTopicNameAt(row), ...
                                source_prop.ColorMode, source_prop.Color);
                            % Update the visualizers as Color mode is
                            % updated
                            tNow = getCurrentTime(obj.Timeline);
                            obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();
                            requestDataForTime(obj, tNow)
                        else
                            obj.ThreeDSettingsObj.addIcon(row);
                        end
                    elseif col ~= 1
                        toReturnEarly = true; % Not source column
                    end
                else
                    toReturnEarly = true; % Ill defined Indices
                end
            end

            if toReturnEarly
                return
            end

            % progress status indicator launch
            indx = [obj.VisualizerMapping.ID] == dataSourceID;
            crPgIdHdle = obj.VisualizerMapping(indx).Handle.launchCircularProgressIndicator;
            c = onCleanup(@()delete(crPgIdHdle));

            % validate the data sources
            try
                obj.VisualizerMapping(indx).Handle.validateDataSources
            catch ex
                if strcmp('ros:visualizationapp:view:InvalidDataSources',ex.identifier)
                    % throw error and reset to previous value.
                    source.Value = valueChangedEventData.PreviousValue;
                end
                obj.throwError(ex)
            end

            % Handle 3D Settings
            if isa(source, 'matlab.ui.control.Table')
                row = event.Indices(1);
                col = event.Indices(2);
                
                fieldPath = obj.ThreeDSettingsObj.getTopicNameAt(row);
                if isempty(valueChangedEventData)
                    return; % If empty then MATLAB detected some error
                end
                sourceAdded = valueChangedEventData.NewData;


            % Get current data source and message/field type
            elseif isa(source, 'matlab.ui.container.CheckBoxTree')
                fieldPath = source.SelectedNodes.Text;
                currentCheckedNodes = valueChangedEventData.CheckedNodes;
                previousCheckedNodes = valueChangedEventData.PreviousCheckedNodes;
                currentNodeIDs = arrayfun(@(node) node.Text, currentCheckedNodes, 'UniformOutput', false);
                previousNodeIDs = arrayfun(@(node) node.Text, previousCheckedNodes, 'UniformOutput', false);
                newlyCheckedNodeIDs = setdiff(currentNodeIDs, previousNodeIDs);
                newlyUncheckedNodeIDs = setdiff(previousNodeIDs, currentNodeIDs);
                % Remove 'Select Data Source' from node lists
                selectDataSourceText = getString(message("ros:visualizationapp:view:DataSourceLabel"));
                removeIndexUnchecked = strcmp(newlyUncheckedNodeIDs, {selectDataSourceText});
                removeIndexChecked = strcmp(newlyCheckedNodeIDs, {selectDataSourceText});
                newlyUncheckedNodeIDs(removeIndexUnchecked) = [];
                newlyCheckedNodeIDs(removeIndexChecked) = [];
                if ~isempty(newlyCheckedNodeIDs)
                    fieldPath = newlyCheckedNodeIDs{1};
                elseif ~isempty(newlyUncheckedNodeIDs)
                    fieldPath = newlyUncheckedNodeIDs{1};
                end
            else
                fieldPath = source.Value;
            end
            if isempty(fieldPath)
                return;
            end

            currType = getTypeWithFieldPath(obj.TopicTree, fieldPath);
            % Check that the selected source is valid for that visualizer
            if ~isempty(currType) && ...
                    (ismember(currType, compatibleTypes) || ...
                    (any(ismember(compatibleTypes, 'message')) && contains(currType, '/')))
                topicName = splitTopicFieldPath(fieldPath);

                % Update the visualizer topic mapping
                whichVis = [obj.VisualizerMapping.ID] == dataSourceID;
                if isa(source, 'matlab.ui.container.CheckBoxTree')
                    tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
                    matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
                    whichVis = matchingIndexes;
                    if ~isempty(newlyCheckedNodeIDs)
                        nTopics = length(newlyCheckedNodeIDs);
                        for idx_topic = 1:nTopics
                            fieldPath = newlyCheckedNodeIDs{idx_topic};
                            topicName = splitTopicFieldPath(fieldPath);
                            obj.VisualizerMapping(whichVis).Topic(end+1) = {string(topicName)};
                            obj.VisualizerMapping(whichVis).DataSource(end+1) = {string(fieldPath)};
                        end
                        if strcmp(obj.VisualizerMapping(whichVis).DataSource(1), "")
                            obj.VisualizerMapping(whichVis).DataSource(1) = [];
                        end
                        if strcmp(obj.VisualizerMapping(whichVis).Topic(1), "")
                            obj.VisualizerMapping(whichVis).Topic(1) = [];
                        end
                    elseif ~isempty(newlyUncheckedNodeIDs)
                        nTopics = length(newlyUncheckedNodeIDs);
                        for idx_topic = 1:nTopics
                            fieldPath = newlyUncheckedNodeIDs{idx_topic};
                            topicName = splitTopicFieldPath(fieldPath);
                            obj.VisualizerMapping(whichVis).Topic(strcmp(obj.VisualizerMapping(whichVis).Topic, topicName)) = [];
                            obj.VisualizerMapping(whichVis).DataSource(strcmp(obj.VisualizerMapping(whichVis).DataSource, fieldPath)) = [];
                        end
                    end
                elseif isa(source, 'matlab.ui.control.Table')
                    % Handle 3D Settings
                    if ~isempty(obj.VisualizerDocGroup.LastSelected) % Only set LastVizID if possible. Otherwise use the old one
                        tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
                        matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
                        whichVis = matchingIndexes;
                        obj.LastVizID = obj.VisualizerMapping(whichVis).Handle.DataSourcesID;
                    end

                    if sourceAdded
                        %New source added, update in the model and in the
                        %presenter
                        topicName = splitTopicFieldPath(fieldPath);
                        obj.SourceManager.addSource(obj.LastVizID, topicName);
                        if obj.ThreeDSettingsObj.isFlatColor(row)
                            colorMode = 'Flat Color';
                            color = obj.ThreeDSettingsObj.getColor(row);
                        else
                            colorMode = 'Default';
                            color = [];
                        end
                        obj.SourceManager.updateSource(obj.LastVizID, topicName, colorMode, color);

                        obj.VisualizerMapping(whichVis).Topic(end+1) = {string(topicName)};
                        obj.VisualizerMapping(whichVis).DataSource(end+1) = {string(fieldPath)};

                        if strcmp(obj.VisualizerMapping(whichVis).DataSource(1), "")
                            obj.VisualizerMapping(whichVis).DataSource(1) = [];
                        end
                        if strcmp(obj.VisualizerMapping(whichVis).Topic(1), "")
                            obj.VisualizerMapping(whichVis).Topic(1) = [];
                        end
                    else
                        %source removed
                        topicName = splitTopicFieldPath(fieldPath);
                        obj.SourceManager.removeSource(obj.LastVizID, topicName);
                        
                        obj.VisualizerMapping(whichVis).Handle.removeSource(topicName);
                        obj.VisualizerMapping(whichVis).Topic(strcmp(obj.VisualizerMapping(whichVis).Topic, topicName)) = [];
                        obj.VisualizerMapping(whichVis).DataSource(strcmp(obj.VisualizerMapping(whichVis).DataSource, fieldPath)) = [];

                    end
                else
                    obj.VisualizerMapping(whichVis).Topic = string(topicName);
                    obj.VisualizerMapping(whichVis).DataSource = string(fieldPath);
                    
                end

                
             
                %Explicit reset for marker visualizer in case data source
                %list is empty
                if isequal(class(obj.VisualizerMapping(whichVis).Handle), 'ros.internal.MarkerVisualizer') ...
                        && isempty(obj.VisualizerMapping(whichVis).DataSource)
                    resetUI(obj.VisualizerMapping(whichVis).Handle);
                end

                %obj.VisualizerMapping(whichVis).DataSource = string(fieldPath);
                if isequal(obj.AppMode,obj.RosbagVisualization)
                    % Update visualizer with latest time changes
                    settings.ticks = getTimeTicks(obj.Timeline);
                    [settings.tStart, settings.tEnd] = getTimeLimits(obj.Timeline);
                    updateTimeSettings(obj.VisualizerMapping(whichVis).Handle,settings)
                end

                if strcmp(obj.AppMode,obj.LiveRosTopicVisualization)
                    % Reset the UI of visualizer
                    resetUI(obj.VisualizerMapping(whichVis).Handle);
                end

                % Notify the model about the data source change
                sendSourceListToModel(obj)


                if isequal(obj.AppMode,obj.RosbagVisualization)
                    % If necessary, request full range of data for view
                    if isFullRange
                        if strcmp(obj.VisualizerMapping(indx).DataType, '3d')
                            if strcmp(currType, 'sensor_msgs/PointCloud2')
                                dataType = 'pointcloud';
                            elseif strcmp(currType, 'sensor_msgs/LaserScan')
                                dataType = 'laserscan';
                            else
                                dataType = 'marker';
                            end
                        else
                            dataType = obj.VisualizerMapping(indx).DataType;
                        end

                        [tStart, tEnd] = getTimeLimits(obj.Timeline);
                        eventDataStruct = struct("StartTime", tStart, ...
                            "EndTime", tEnd, ...
                            "DataSource", fieldPath, ...
                            "DataType", dataType);
                        eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
                        notify(obj.EventObject, "DataRangeRequestedPM", eventDataOut)
                    end
                    % Display initial data on the graphics
                    % For full-range visuals this will update the position indicator
                    tNow = getCurrentTime(obj.Timeline);
                    obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();
                    requestDataForTime(obj, tNow)
                end
            end

            % first time when the user select the datasource from the
            % dropdown remove the empty items.
            if ~isa(source, 'matlab.ui.container.CheckBoxTree') && ~isa(source, 'matlab.ui.control.Table')
                source.Items = source.Items(~cellfun('isempty', source.Items));
            end
            %obj.updateSaveAppStateFile();
        end

        function frameIdValueChanged(objWeakHndl, ~, eventData)
            selectedFrameID = eventData.Value;
            obj = objWeakHndl.get;

            tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
            matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
            whichVis = matchingIndexes;

            vizID = obj.VisualizerMapping(whichVis).Handle.DataSourcesID;
            % eventDataStruct = struct("FrameId", selectedFrameID);
            % eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
            % notify(obj.EventObject, "UpdateFrameIdPM", eventDataOut);
            obj.SourceManager.updateFrameID(vizID, selectedFrameID);
            tNow = getCurrentTime(obj.Timeline);
            obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();
            requestDataForTime(obj, tNow);
        end

        function currentTimeFieldChanged(objWeakHndl, source, eventData)
            %currentTimeFieldChanged React to change in time edit field

            obj = objWeakHndl.get;
            inputdata = str2double(eventData.Value);
            if isnan(inputdata)||~isreal(inputdata)||isinf(inputdata)
                %throw an error
                timelabelval = obj.Timeline.getTimeLabel;
                errmsg.message = getString(message("ros:visualizationapp:view:InvalidCurrentTime", timelabelval));
                throwError(obj, errmsg);
                source.Value = eventData.PreviousValue;
                return;
            end
            if ~isempty(obj.TopicTree)
                newTime = str2double(source.Value);
                if obj.Timeline.getIsViewElapseTime
                    [tStart, ~] = getTimeLimits(obj.Timeline);
                    newTime = newTime + tStart;
                end
                if ~isempty(obj.VisualizerMapping)
                    requestDataForTime(obj, newTime);
                else
                    obj.Timeline.setCurrentTime(newTime);
                end
            else
                source.Value = eventData.PreviousValue;
            end
        end


        function updateCurrentTimeFieldChanged(objWeakHndl, ~, ~)
            %updateCurrentTimeFieldChanged callback updates the
            %CurrentTimeField to show the time format selected from the
            %dropdown i.e. either elapse time or timestamp

            obj = objWeakHndl.get;
            if ~isempty(obj.TopicTree)
                obj.Timeline.updateTimeSettings

                % Update visualizers with latest time changes
                settings.ticks = getTimeTicks(obj.Timeline);
                [settings.tStart, settings.tEnd] = getTimeLimits(obj.Timeline);
                for iVis = 1:numel(obj.VisualizerMapping)
                    updateTimeSettings(obj.VisualizerMapping(iVis).Handle,settings)
                end
            end
            if ~ isempty(obj.BookmarkTabObj.BookmarkTableList)

                [s, ~] = obj.Timeline.getTimeLimits;
                if obj.Timeline.getIsViewElapseTime
                    if ~obj.BookmarkTabObj.IsElapseTimeFormat
                        obj.BookmarkTabObj.BookmarkTableList(:,2) = ...
                            obj.BookmarkTabObj.BookmarkTableList(:, 2)- s;
                    end
                else
                    if obj.BookmarkTabObj.IsElapseTimeFormat
                        obj.BookmarkTabObj.BookmarkTableList(:,2) = ...
                            obj.BookmarkTabObj.BookmarkTableList(:,2) +s;
                    end
                end
                obj.BookmarkPanelObj.updateBookmarkTable(...
                    obj.BookmarkTabObj.BookmarkTableList);
                obj.BookmarkTabObj.IsElapseTimeFormat = obj.Timeline.getIsViewElapseTime;
            end
        end

        function timelineValueChanged(objWeakHndl, source)
            %timelineValueChanged Request updated data for new time

            obj = objWeakHndl.get;
            newTime = source.Value;

            % Check if the source details are loaded before requesting Data
            if ~isempty(obj.TopicTree)
                requestDataForTime(obj, newTime);
            end

            % Stop playback after timeline is clicked
            stopPlayBack(obj)
        end

        function timelineValueChanging(objWeakHndl, ~)
            %timelineValueChanging Request updated data for new time

            obj = objWeakHndl.get;
            if obj.PlaybackState
                stopPlayBack(obj)
            end
        end

        function playBackTimerCallback(objWeakHndl, ~)
            %playBackTimerCallback callback for playback timer

            obj = objWeakHndl.get;

            if isequal(obj.AppMode,obj.RosbagVisualization)
                % Continue playback until stopped by user or reached end
                [tStart, tEnd] = getTimeLimits(obj.Timeline);
                t = getCurrentTime(obj.Timeline);
                if obj.PlaybackState && ...
                        ((t < tEnd && isequal(obj.PlaybackDirection,obj.ForwardPlayback)) || ...
                        (t > tStart && isequal(obj.PlaybackDirection,obj.ReversePlayback)))
                    stepTime(obj, obj.PlaybackDirection)
                else
                    stopPlayBack(obj)
                    % After reaching end of the bag file, reset time slider to start position
                    requestDataForTime(obj, tStart)
                end
            else
                stepTime(obj, {})
            end
        end

        function playPausePushed(objWeakHndl, ~)
            %playPausePushed Start or stop playback through the rosbag
            %   Source is the play/pause button that was pushed

            obj = objWeakHndl.get;
            % Toggle playback state
            if ~isVisualizerLoadedWithTopicForPlayback(obj)
                stopPlayBack(obj)
                if isequal(obj.AppMode, obj.LiveRosTopicVisualization)
                    ex = MException(message('ros:visualizationapp:view:NoVisualizerIsOpen'));
                    throwError(obj, ex);
                end
                return;
            end
            obj.PlaybackState = ~obj.PlaybackState;

            %set forward playback
            obj.PlaybackDirection = obj.ForwardPlayback;

            if obj.PlaybackState
                startPlayBack(obj)
            else
                stopPlayBack(obj)
                updateGraphicHandleIdx(obj)
            end
        end

        function removeDataSourcesFromMapping(objWeakHndl, idValues)
            %removeDataSourcesFromMapping Remove data sources from tracking
            %   The idValues contain all data source ID values to remove

            obj = objWeakHndl.get;
            if ~isempty(obj) && isvalid(obj)
                numHandlesIsMarker = sum(arrayfun(@(x) isa(x.Handle, 'ros.internal.MarkerVisualizer'), obj.VisualizerMapping));
                numHandlesIs3D = sum(arrayfun(@(x) isa(x.Handle, 'ros.internal.ThreeDVisualizer'), obj.VisualizerMapping));

                whichSource = ismember([obj.VisualizerMapping.ID], idValues);
                vishandle = obj.VisualizerMapping(whichSource).Handle;
                if isa(vishandle, ...
                        'ros.internal.MarkerVisualizer')
                    % If it is, then check the count of such instances
                    if numHandlesIsMarker == 1
                        %close the VisualizerSetting Panel
                        obj.AppContainer.removePanel(getString(message("ros:visualizationapp:view:VisualizerSettingsTitle")));                        
                        obj.VisualizerSettingPanelObj.VisualizerSettingsPanel.delete;
                        obj.VisualizerSettingPanelObj.delete;
                        obj.VisualizerSettingPanelObj = [];
                        obj.Toolstrip.disableToolsSection();
                    elseif numHandlesIsMarker > 1
                        % If there are more than one instances, 
                        % reinitialize the ThreeDSettingPanelObj
                        

                        % Find a ThreeD handle with DataSourcesID value not
                        % getting closed.

                        activeMarkerVisualizers = obj.VisualizerMapping(arrayfun(@(s) isa(s.Handle, 'ros.internal.MarkerVisualizer'), obj.VisualizerMapping) & ~ismember([obj.VisualizerMapping.ID], idValues));
                        
                        % Select the first one and re-attach the callback
                        % to it. Since, numHandlesIs3D > 1
                        % size(activeMarkerVisualizers) will at least be 1.
                        
                        visualizer = activeMarkerVisualizers(1).Handle;

                        obj.VisualizerSettingPanelObj.DataSourceNodesCheckedFcn = @(source, event) ...
                                    ros.internal.ViewerPresenter.dataSourceValueChanged(...
                                    objWeakHndl, source, event, visualizer.DataSourcesID, visualizer.CompatibleTypes, false);
                        obj.VisualizerSettingPanelObj.FrameIDValueChangedFcn = @(source, event) ros.internal.ViewerPresenter.frameIdValueChanged(objWeakHndl, source, event);

                        visualizer.Document.Selected = true;
                    end
                    % No need for an else case here as the actions are based on numHandlesIsMarker values                    
                end
                % 
                if isa(vishandle, 'ros.internal.ThreeDVisualizer')
                    % g3442740 clear 3D settings panel when last 3D
                    % visualizer is closed.
                    if numHandlesIs3D == 1
                        %close the 3D Setting Panel
                        obj.AppContainer.removePanel(getString(message("ros:visualizationapp:view:ThreeDSettingsPanelTitle")));                        
                        obj.ThreeDSettingsObj.ThreeDPanel.delete;
                        obj.ThreeDSettingsObj.delete;
                        obj.ThreeDSettingsObj = [];
                        obj.Toolstrip.disableToolsSection();
                    elseif numHandlesIs3D > 1
                        active3DVisualizers = obj.VisualizerMapping(arrayfun(@(s) isa(s.Handle, 'ros.internal.ThreeDVisualizer'), obj.VisualizerMapping) & ~ismember([obj.VisualizerMapping.ID], idValues));
                    
                        % Select the first one and re-attach the callback
                        % to it. Since, numHandlesIsMaker > 1
                        % size(activeMarkerVisualizers) will at least be 1.
                        
                        visualizer = active3DVisualizers(1).Handle;

                        obj.ThreeDSettingsObj.TableCellEditCallback = @(source, event) ...
                            ros.internal.ViewerPresenter.dataSourceValueChanged(...
                            objWeakHndl, source, event, visualizer.DataSourcesID, visualizer.CompatibleTypes, false);
                        obj.ThreeDSettingsObj.TableCellSelectionCallback = @(source, event) ros.internal.ViewerPresenter.threeDTtableSelect(objWeakHndl, source, event);
                        obj.ThreeDSettingsObj.FrameIDValueChangedFcn = @(source, event) ros.internal.ViewerPresenter.threeDFrameIdUpdated(objWeakHndl, source, event);
    
                            
                        visualizer.Document.Selected = true;
                    end
                end
                dataSource = obj.VisualizerMapping(whichSource).DataSource;
                obj.VisualizerMapping(whichSource) = [];

                if ~isequal(dataSource,"")
                    % update Topic for Automatic Playback
                    obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();

                    % Notify the model about the data source change
                    sendSourceListToModel(obj);
                end
                if ~isempty(obj.TopicTree)
                     obj.updateSaveAppStateFile();
                end
            end
        end

        function nextPushed(objWeakHndl)
            %nextPushed Move on to next message
            %   The new time will depend on the main signal and rate selected

            obj = objWeakHndl.get;
            if ~isVisualizerLoadedWithTopicForPlayback(obj)
                %play only when the data source is selected
                return
            end
            if obj.PlaybackState
                obj.PlaybackDirection = obj.ForwardPlayback;
            else
                stepTime(obj, obj.ForwardPlayback);
            end
        end

        function previousPushed(objWeakHndl)
            %nextPushed Move back to the previous message
            %   The new time will depend on the main signal and rate selected

            obj = objWeakHndl.get;
            if ~isVisualizerLoadedWithTopicForPlayback(obj)
                %play only when the data source is selected
                return
            end
            if obj.PlaybackState
                obj.PlaybackDirection = obj.ReversePlayback;
            else
                stepTime(obj, obj.ReversePlayback);
            end
        end

        function ret = cleanupAndCloseApp(objWeakHndl, src, evt)
            %cleanupAndCloseApp cleanup app before closing

            obj = objWeakHndl.get;

            % Stop the playback
            if obj.PlaybackState
                obj.stopPlayBack();
            end
            % delete the timer
            timerhdl = timerfind('Name', obj.UniqueTimerName);
            if ~isempty(timerhdl) && isvalid(timerhdl)
                obj.PlaybackTimer.stop;
                delete(timerhdl);
            end

            % Save the last time used bag file in preference before App is
            % closed
            if ~isempty(obj.LastOpenedBagPath)
                setpref(obj.PrefGroup,obj.LastUsedBagPathPrefName,obj.LastOpenedBagPath);
                obj.LastOpenedBagPath = '';
            end
            if obj.EnableSaveAppState
                if ~isempty(obj.TopicTree)
                    obj.updateSaveAppStateFile();
                end
            end
            ret = true;

            appMap = ros.internal.RosDataAnalyzer.getAppMap;
            appMap(obj.UniqueTagApp) = []; %#ok<NASGU>
        end

        function gridlayout(objWeakHndl, source, eventData)
            %gridlayout is a callback function for the gridlayout toolstrip
            %option. This callback sets the AppContainer
            %DocumentGridDimensions to the event data i.e. row and column
            %which user selects

            obj = objWeakHndl.get;
            if isa(source, 'matlab.ui.internal.toolstrip.GridPickerButton')
                obj.AppContainer.DocumentGridDimensions = ...
                    [eventData.EventData.NewValue.column eventData.EventData.NewValue.row];
            else
                obj.AppContainer.DocumentGridDimensions = [1 1];
                obj.Toolstrip.setGridLayoutButtonProperties('Selection', struct('row', 1, 'column', 1));
            end
        end

        function defaultlayout(objWeakHndl, ~)
            %defaultlayout is a callback function for the defaultlayout
            % toolstrip option. This callback sets the AppContainer
            %DocumentGridDimensions to [1 1](single and single column)

            obj = objWeakHndl.get;
            obj.AppContainer.DocumentGridDimensions = [1 1];
        end

        function addBookmark(objWeakHndl, ~)
            %addBookmark is used to add a bookmark at a particular time

            obj = objWeakHndl.get;
            % if bag not loaded throw message and return
            if isempty(obj.TopicTree)
                errmsg.message = getString(message("ros:visualizationapp:view:LoadRosbagToAddBookmark"));
                obj.throwError(errmsg);
                return;
            end
            % stop playback
            if obj.PlaybackState
                %If playback is going stop the playback
                stopPlayBack(obj);
            end
            % define input dialog variable names
            startimelabel = getString(message("ros:visualizationapp:view:StartTime"));
            durationlabel = getString(message("ros:visualizationapp:view:Duration"));
            labelbookmarklabel = getString(message("ros:visualizationapp:view:LabelBookmark"));
            dlgtitle = getString(message("ros:visualizationapp:view:AddBookmarkTitle"));
            prompt = {startimelabel, durationlabel, labelbookmarklabel};
            dims = [1 75];
            % get default values
            currTime = getCurrentTime(obj.Timeline);
            [startLim, endLim] = obj.Timeline.getTimeLimits();
            if obj.Timeline.getIsViewElapseTime
                [s,~] = obj.Timeline.getTimeLimits;
                currTime = currTime-s;
                [startLim, endLim] = obj.Timeline.getTimeLimits();
                startLim = startLim -s;
                endLim = endLim -s;
            end
            definput = {num2str(currTime), '0', ['Bookmark_' ros.internal.utils.generateRandomString(4)]};
            bookmarkdata = inputdlg(prompt, dlgtitle, dims, definput);
            if ~isempty(bookmarkdata)
                % parse input data
                starttime = bookmarkdata(1);
                starttime = str2double(starttime{1});
                % validate starttime is valid within limits of the bag
                if ~((startLim-starttime)<=1e-4 && (starttime <= endLim))
                    %throw an error
                    errmsg.message = getString(message("ros:visualizationapp:view:InvalidStartTime", ...
                        bookmarkdata{1}, num2str(startLim), num2str(endLim)));
                    throwError(obj, errmsg);
                    return;
                end
                % validate duration is valid
                duration = bookmarkdata(2);
                duration = str2double(duration{1});
                if duration <0 || ~(duration <= endLim-starttime)
                    %throw an error
                    errmsg.message = getString(message("ros:visualizationapp:view:InvalidDuration", ...
                        bookmarkdata{2}, num2str(endLim-starttime)));
                    throwError(obj, errmsg);
                    return;
                end
                label = bookmarkdata(3);
                label = label{1};
                % append data to the table
                obj.BookmarkTabObj.appendToBookmarkTable(starttime, duration, label);
                % update to manage bookmark panel
                obj.BookmarkPanelObj.updateBookmarkTable(obj.BookmarkTabObj.BookmarkTableList);
                obj.updateSaveAppStateFile();
            end
            obj.AppContainer.bringToFront();
            obj.BookmarkPanelObj.showBookmarkTable();

        end

        function addTagsToRosbag(objWeakHndl, ~)
            %addTagsToRosbag is used to add a tags at a particular time

            obj = objWeakHndl.get;
            obj.AppContainer.RightCollapsed = 0;
            obj.AddTagsPanelObj.TagsPanel.Selected = 1;

        end

        function ViewToggle(objWeakHndl, ~)
            % This function helps in toggling the view
            obj = objWeakHndl.get;
            tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
            matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
            whichVis = matchingIndexes;

            % g3426572 Make view toggle specific to a visualizer.
            obj.VisualizerMapping(whichVis).Handle.viewToggle()

        end

        function MeasureDistance(objWeakHndl, ~)
            %addTagsToRosbag is used to add a tags at a particular time
            obj = objWeakHndl.get;

            % Looping through all the current Visualizers (TO-DO: Change it
            % to only work for the current window user is on)
            for i = 1: length(obj.VisualizerMapping)
                % Check if the Visualizer is for Markers (TO-DO: Support
                % other Visualizer in the future)
                if obj.VisualizerMapping(i).DataType == "marker"
                    axesHandle = obj.VisualizerMapping(i).Handle.AxesHandle;
                    hFig = get(axesHandle,"Parent");
                    figObjs = findall(hFig);
                    % Find all the Data tips
                    dataTips = figObjs(arrayfun(@(h)isa(h,'matlab.graphics.shape.internal.PointDataTip'),figObjs));
                    % Check if data tips are more than 1 and display error.
                    % Also check if user deleted the data tips post
                    % plotting as this will help clear the measuring
                    % distance plot handles
                    if length(dataTips) < 2 && obj.measureDistancePlotted == false % this flag is to toggle TO DO remove this when new button is added to clear measure
                        errmsg.message = "Please select 2 or more data tips to use the measure distance tool";
                        obj.throwError(errmsg);
                    else
                        % Plot the distances
                        obj.measureDistancePlotted = obj.VisualizerMapping(i).Handle.measureDistance(dataTips);
                    end
                end
                %TODO
                % check selected visualizer is there is single grid
                % if multiple grid then we plot for all when there are data
                % tips else plot for available visualizer only (do not
                % throw error for non data tip or marker visualizers)
            end

        end
        % Bookmark panel callbacks
        function manageBookmark(objWeakHndl)
            % manageBookmark will open the bookmarkpanel

            obj = objWeakHndl.get;
            obj.AppContainer.RightCollapsed = 0;
            obj.BookmarkPanelObj.BookmarkPanel.Selected = 1;
        end

        function bmTableSelectionChanged(objWeakHndl, source, event)
            %bmTableSelectionChanged is called when user selects the row,
            %whichever row is selected the timeline should goto the
            %selected time

            obj = objWeakHndl.get;
            if isa(event, 'matlab.ui.eventdata.TableSelectionChangedData')
                selectedData = source.Data(event.Selection, :);
                currTime = selectedData.Starttime;
                if obj.Timeline.getIsViewElapseTime
                    [s,~] = obj.Timeline.getTimeLimits;
                    currTime = selectedData.Starttime +s;
                end
                setCurrentTime(obj.Timeline, currTime);
                if ~isempty(obj.TopicTree)
                    requestDataForTime(obj, currTime);
                end
            elseif isa(event, 'matlab.ui.eventdata.CellSelectionChangeData')
                return;
            end
        end

        function bmTableCellEditCallback(objWeakHndl, ~, event)
            %BmTableCellEditCallback is called when edits the table

            obj = objWeakHndl.get;
            currTime = event.NewData;
            if isa(event, 'matlab.ui.eventdata.CellEditData')
                [startLim, endLim] = obj.Timeline.getTimeLimits();
                if obj.Timeline.getIsViewElapseTime
                    endLim = endLim - startLim;
                    startLim = 0;
                end
                % Startime
                if event.DisplayIndices(2) == 2 && (~((currTime >= startLim) && (currTime <= endLim)) || isnan(event.NewData))
                    %throw an error and reset to previous value
                    errmsg.message = getString(message("ros:visualizationapp:view:InvalidStartTime", ...
                        event.EditData, num2str(startLim), num2str(endLim)));
                    throwError(obj, errmsg);
                    obj.BookmarkPanelObj.TableHandle.Data(event.DisplayIndices(1), event.DisplayIndices(2)) = {event.PreviousData};
                    return;
                    % Duration
                elseif event.DisplayIndices(2) == 3 && (((currTime <0)|| (currTime >endLim) || ~(currTime <= endLim- currTime))|| isnan(event.NewData))
                    %throw an error and reset to previous value
                    
                    %g3286214 Allowed duration is always between 0 and
                    %(endLim - startTime).
                    endlimitforError = endLim - obj.BookmarkPanelObj.TableHandle.Data(event.DisplayIndices(1), event.DisplayIndices(2)-1).Starttime;
                    
                    errmsg.message = getString(message("ros:visualizationapp:view:InvalidDuration", ...
                        event.EditData, num2str(endlimitforError)));
                    throwError(obj, errmsg);
                    obj.BookmarkPanelObj.TableHandle.Data(event.DisplayIndices(1), event.DisplayIndices(2)) = {event.PreviousData};
                    return;
                end
            end
            if event.DisplayIndices(2) == 2
                if obj.Timeline.getIsViewElapseTime
                    [s,~] = obj.Timeline.getTimeLimits;
                    % currTime = currTime +s;
                end
                setCurrentTime(obj.Timeline, currTime + s);
                if ~isempty(obj.TopicTree)
                    requestDataForTime(obj, currTime + s);
                end
            end
            % g3289646 bookmark table always stores the relative time
            % format i.e it's a always between 0 to duration.
            obj.BookmarkTabObj.updateBookmarkTable(event.DisplayIndices(1), event.DisplayIndices(2), currTime);
        end

        function bmTableClickedFcn(objWeakHndl, ~, event)
            %BmTableDoubleClickedFcn is called when user double click on
            %the bookmarktable , if it is double clicked on the cell 5 the
            %highlighted item in the table should get deleted.

            obj = objWeakHndl.get;
            if isa(event, 'matlab.ui.eventdata.ClickedData')
                if event.InteractionInformation.DisplayColumn == 4 ...
                        && ~isempty( event.InteractionInformation.DisplayRow)
                    answer = ros.internal.view.UIConfirm.run(obj.AppContainer, ...
                        getString(message("ros:visualizationapp:view:ConfirmDeleteBookmark")), ...  % message
                        getString(message("ros:visualizationapp:view:DeleteLabel")), ... % title
                        'Icon', 'question');
                    if strcmp(answer, 'OK')
                        obj.BookmarkTabObj.removeFromBookmarkTable(event.InteractionInformation.DisplayRow);
                        obj.BookmarkPanelObj.updateBookmarkTable(obj.BookmarkTabObj.BookmarkTableList);
                        obj.updateSaveAppStateFile();
                    end

                end
                if ~isempty(event.Source.Selection)
                    currTime = event.Source.Data(event.Source.Selection,:).Starttime;
                    if obj.Timeline.getIsViewElapseTime
                        [s,~] = obj.Timeline.getTimeLimits;
                        currTime = event.Source.Data(event.Source.Selection,:).Starttime +s;
                    end
                    setCurrentTime(obj.Timeline, currTime);
                    if ~isempty(obj.TopicTree)
                        requestDataForTime(obj, currTime);
                    end
                end
            end
        end

        function threeDFrameIdUpdated(objWeakHndl, ~, event)
            obj = objWeakHndl.get;
            newFrameID = event.Value;

            tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
            matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
            whichVis = matchingIndexes;

            vizID = obj.VisualizerMapping(whichVis).Handle.DataSourcesID;
            obj.SourceManager.updateFrameID(vizID, newFrameID);

            tNow = getCurrentTime(obj.Timeline);
            obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();
            requestDataForTime(obj, tNow);
        end

        function threeDTtableSelect(objWeakHndl, src, event)
            obj = objWeakHndl.get;
            %Handle edge case for g3528747
        
            if numel(event.Indices) < 2
                return % Return early if event object is unexpected.
            end
            row = event.Indices(1);
            col = event.Indices(2);

            % Only handle for the last column
            if col == 4
                %Reset selection so users can click again to change color
                src.Selection = [];
                source_prop = struct('ColorMode', getString(message("ros:visualizationapp:view:ThreeDSettingsModeDefault")), 'Color', []);
                if obj.ThreeDSettingsObj.isFlatColor(row) 
                    source_prop.ColorMode = 'Flat Color';

                    c = uisetcolor([], "3D Settings color"); % TODO: Better Title
                    obj.ThreeDSettingsObj.setColor(row, c);
                    source_prop.Color = c; 
                end

                tags = arrayfun(@(x) x.Handle.Document.Tag, obj.VisualizerMapping, 'UniformOutput', false);
                matchingIndexes = find(strcmp(cellstr(tags), obj.VisualizerDocGroup.LastSelected.tag));
                whichVis = matchingIndexes;
    
                vizID = obj.VisualizerMapping(whichVis).Handle.DataSourcesID;
                source = obj.ThreeDSettingsObj.getTopicNameAt(row);
                obj.SourceManager.updateSource(vizID, source, source_prop.ColorMode, source_prop.Color);
                
                % Refresh visualizers
                tNow = getCurrentTime(obj.Timeline);
                obj.AutomaticTopic = obj.getReferenceTopicForAutomatic();
                requestDataForTime(obj, tNow);
            end
        end

        function showBookmarkOnTimeline(objWeakHndl)
            %showBookmarkOnTimeline
            obj = objWeakHndl.get;
            % TO DO once the slider is ready
            %disp("from viewerPresenter line 1072 - TO DO");
        end

        % Tag Panel Callbacks
        function tagsAddCallback(objWeakHndl, source, event)
            % tagsAddCallback callback to editfield in the tags panel
            obj = objWeakHndl.get;
            % do not add empty value
            newVal = strrep(event.Value, ' ', '');
            if isempty(newVal)
                return;
            end
            % duplicate tags check
            if ~isempty(obj.AddTagsPanelObj.TagsHandleTab) && ~isempty(ros.internal.utilities.findElement(obj.AddTagsPanelObj.TagsHandleTab.TagValue', newVal))
                errmsg.message = getString(message("ros:visualizationapp:view:DuplicateTag", newVal));
                throwError(obj, errmsg);
            else
                obj.AddTagsPanelObj.createTagComponent(newVal)
            end
            % reset the editfield
            source.Value = '';
            obj.updateSaveAppStateFile();
        end

         function exportFromBookmark(objWeakHandle)
            obj = objWeakHandle.get;
            tree = obj.TopicTree;

            % if bag not loaded throw message and return
            if isempty(obj.TopicTree)
                errmsg.message = getString(message("ros:visualizationapp:view:LoadRosbagToExport"));
                obj.throwError(errmsg);
                return;
            end
            % stop playback
            if obj.PlaybackState
                %If playback is in progress stop the playback
                stopPlayBack(obj);
            end
            if isa(obj.TopicTree.Rosbag, 'rosbagreader')
                rosVersion = "ROS";
            else
                rosVersion = "ROS2";
            end

            obj.ExportFromBookmarkAppObj = ros.internal.view.UIExportFromBookmark(obj.BookmarkTabObj.BookmarkTableList, rosVersion);
            obj.ExportFromBookmarkAppObj.ExportButtonClickedFcn = @(src, event) ros.internal.ViewerPresenter.exportRosbagCallback(objWeakHandle, tree.Rosbag, obj.ExportFromBookmarkAppObj, rosVersion);
            obj.ExportFromBookmarkAppObj.showApp();
         end

        
             
        function exportFromTopic(objWeakHandle)
            obj = objWeakHandle.get;
            tree = obj.TopicTree;
            
            % if bag not loaded throw message and return
            if isempty(obj.TopicTree)
                errmsg.message = getString(message("ros:visualizationapp:view:LoadRosbagToExport"));
                obj.throwError(errmsg);
                return;
            end
            % stop playback
            if obj.PlaybackState
                %If playback is in progress stop the playback
                stopPlayBack(obj);
            end

            if isa(tree.Rosbag, "rosbagreader")
                rosVersion = "ROS";
            else
                rosVersion = "ROS2";
            end
            duration = tree.Rosbag.EndTime - tree.Rosbag.StartTime;
            obj.ExportFromTopicAppObj = ros.internal.view.UIExportFromTopic(tree.Topics, duration, rosVersion);
            obj.ExportFromTopicAppObj.ExportButtonClickedFcn = @(src, event) ros.internal.ViewerPresenter.exportRosbagCallback(objWeakHandle, tree.Rosbag, obj.ExportFromTopicAppObj, rosVersion);
            obj.ExportFromTopicAppObj.showApp();
            
        end
        
        function exportRosbagCallback(objWeakHndl, bagReader, exportAppObj, rosVersion)
            %exportRosbagCallback callback for export button on
            %ExportFromTopic and ExportFromBookmarks app

            obj = objWeakHndl.get;

            
            try
                [timeIntervals, topics] = exportAppObj.getBagFilter();
            catch ME
                obj.throwError(ME);
                return;
            end
            selection = exportAppObj.getStorageFormat();
            
            if isequal(rosVersion, "ROS")
                filter = {'*.bag'};
            else
                filter = {'*'};
            end
            
            [outFilename, outFilepath] = uiputfile(filter, ...
                getString(message('ros:visualizationapp:view:ExportAppFilePicker')));
            if ~isequal(outFilepath, 0) && ~isequal(outFilename, 0)
                % Get the selected StorageFormat.
                if isequal(rosVersion, "ROS")
                    storageFormat = "";
                else
                    if isequal(selection, '.db3')
                        storageFormat = "sqlite3";
                    else
                        storageFormat = "mcap";
                    end
                end
                 

                fileName = fullfile(outFilepath, outFilename);
                
                % In case of ROS2 we need to get the folder name. Check if
                % file already exists then we need to use the filepath.
                if isequal(rosVersion, "ROS2") && exist(fileName, "file")
                    rmdir(outFilepath, 's');
                    fileName = outFilepath;
                end

                exportAppObj.closeApp();
                
                bringToFront(obj.AppContainer);
                d = obj.UIProgress.run(obj.AppContainer, 'Message', ...
                    getString(message('ros:visualizationapp:view:WriteRosbagFile', ...
                    fileName)));
                c = onCleanup(@() delete(d));      
                % closeAppCleanup = onCleanup(@() exportAppObj.closeApp());
                try
                    ros.internal.utils.exportRosbag(bagReader, timeIntervals, topics, fileName, rosVersion, storageFormat);
                catch ME
                    obj.throwError(ME);
                end
            end
        end
    end

   
    
    methods (Access = ?ros.internal.mixin.ROSInternalAccess) % Helper functions
        function stopPlayBack(obj)
            %stopPlayBack stop the playback

            obj.PlaybackState = false;
            obj.PlaybackTimer.stop();

            if isequal(obj.AppMode,obj.RosbagVisualization)
                stopPlayback(obj.Timeline);
            else
                stopPlayback(obj.Toolstrip);
            end
        end

        function startPlayBack(obj)
            %startPlayBack start the playback
            if isequal(obj.AppMode,obj.RosbagVisualization)
                startPlayback(obj.Timeline);

                %startPlayback(obj.Toolstrip);

                %Continue playback until stopped by user or reached end
                [tStart, tEnd] = getTimeLimits(obj.Timeline);
                t = getCurrentTime(obj.Timeline);
                if obj.PlaybackState && ...
                        ((t < tEnd && isequal(obj.PlaybackDirection,obj.ForwardPlayback)) || ...
                        (t > tStart && isequal(obj.PlaybackDirection,obj.ReversePlayback)))

                    obj.PlaybackTimer.start();
                else
                    stopPlayBack(obj)
                    % After reaching end of the bag file, reset time slider to start position
                    requestDataForTime(obj, tStart)
                end
            else

                startPlayback(obj.Toolstrip);
                obj.PlaybackTimer.start();
            end
        end
    end
end

function [topic, fieldPath] = splitTopicFieldPath(fullPath)
%splitTopicFieldPath Split the topic from the path to the data field

% TODO: Make into a shared utility
splitPath = strsplit(fullPath, ".");
topic = splitPath{1};
fieldPath = {};
if numel(splitPath) > 1
    fieldPath = splitPath(2:end);
end
end

function out = isVisualizerLoadedWithTopicForPlayback(obj)
%isVisualizerLoadedWithTopicForPlayback verifies if the visualizer
% is open and datasource is not selected

out = ~(isempty(obj.VisualizerMapping) || ...
    isequal(obj.VisualizerMapping(:).DataSource, ""));
end

function newDataContainer = filterRepeatedTopics(dataContainer)
topics = string.empty(numel(dataContainer),0);

for idx = 1:numel(dataContainer)
    topics(idx) = strcat(dataContainer(idx).Topic, "/", dataContainer(idx).DataType);
end

[~,idx] = unique(topics);

newDataContainer = dataContainer(idx);
end

function setrestoring(obj, property, value)
obj.(property) = value;
end

% LocalWords:  bagfile pointcloud laserscan HHmmss SSSS dlgs appcontainer datasource dropdown Lim
% LocalWords:  referesh visulizier exisitng mcap yaml textarea defaultlayout starttime bookmarkpanel
% LocalWords:  eventdata Startime bookmarktable editfield rosbagreader sqlite filepath curr DSetting
% LocalWords:  DVisualizer DModel DSettings
