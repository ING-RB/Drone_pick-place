classdef ViewerToolstrip < handle
    %This class is for internal use only. It may be removed in the future.

    %ViewerToolstrip Toolstrip UI for the ROS Data Analyzer app
    %   TOOLSTRIP = ros.internal.ViewerToolstrip(APPCONTAINER)
    %      Create the rosDataAnalyzer toolstrip in the provided app container.
    %      The toolstrip will have buttons for loading in the rosbag, creating
    %      visualizers, and assisting with layout of visualizers.
    %
    %   Properties:
    %       Callback functions for toolstrip buttons, able to be customized by
    %       the app presenter class:
    %          OpenFileCallback
    %          DefaultLayoutCallback
    %          GridLayoutCallback
    %          ImageViewerCallback
    %          PointCloudViewerCallback
    %          LaserScanViewerCallback
    %          OdometryViewerCallback
    %          XYPlotViewerCallback
    %          TimePlotViewerCallback
    %          RawMessageViewerCallback
    %          ExportFromTopicCallback
    %          ExportFromBookmarkCallback
    %          MarkerViewerCallback

    %   Copyright 2022-2024 The MathWorks, Inc.

    % Callbacks
    properties % Access will be restricted to Presenter/tests, when created
        % Activate on OpenButton push
        OpenFileCallback = function_handle.empty
        OpenROSMasterURICallback = function_handle.empty
        OpenROS2DomainIDCallback = function_handle.empty
        SearchCallback = function_handle.empty

        % Activate on specified layout button push
        DefaultLayoutCallback = function_handle.empty
        GridLayoutCallback = function_handle.empty

        % Activate on specified viewer gallery button push
        ImageViewerCallback = function_handle.empty
        PointCloudViewerCallback = function_handle.empty
        LaserScanViewerCallback = function_handle.empty
        OdometryViewerCallback = function_handle.empty
        XYPlotViewerCallback = function_handle.empty
        TimePlotViewerCallback = function_handle.empty
        MessageViewerCallback = function_handle.empty
        MapViewerCallback = function_handle.empty
        ThreeDViewerCallback = function_handle.empty

        % bookmark callbacks
        ManageBookmarkCallback = function_handle.empty
        AddBookmarkCallback = function_handle.empty

        % Add tag callbacks
        AddTagCallback = function_handle.empty

        PlayCallback = function_handle.empty

        % Export Callbacks
        ExportFromTopicCallback = function_handle.empty
        ExportFromBookmarkCallback = function_handle.empty
        MarkerViewerCallback = function_handle.empty
        ViewToggleCallback = function_handle.empty
        MeasureDistanceCallback = function_handle.empty

    end

    % UI Objects
    properties (Access = ?matlab.unittest.TestCase)
        % Primary container for all items in toolstrip
        TabGroup

        % Tabs within the toolstrip
        ApplicationTab

        % Toolstrip sections
        FileSection
        VisualizeSection
        LayoutSection
        BMSection
        PlayBackSection
        TagRosBagSection
        ExportRosBagSection

        % Buttons on the toolstrip (outside of the gallery)
        OpenFileButton
        DefaultLayoutButton
        GridLayoutButton
        PlayButton

        % List items
        OpenPopupList
        OpenFileItem
        OpenNetworkItem
        OpenROS1NetworkItem
        OpenROS2NetworkItem
        SearchROSBagItem

        % Visualizer gallery buttons
        VisualizeCategory
        ImageViewerButton
        PointCloudViewerButton
        LaserScanViewerButton
        OdometryViewerButton
        XYPlotViewerButton
        TimePlotViewerButton
        MessageViewerButton
        MapViewerButton
        MarkerViewerButton
        ThreeDViewerButton

        % QAB Buttons
        QABHelpButton

        % Bookmark buttons
        ManageBookmarkButton
        AddBookmarkButton

        % Tag Rosbag buttons
        AddTagButton

        % Export Rosbag buttons
        ExportPopupListButton
        ExportFromTopicItem
        ExportFromBookmarksItem
        % Tools Section
        ToolsSection
        % buttons under tools section
        AddViewToggleButton
        AddMeasureDistanceButton

    end

    % Values needed for testing
    properties (Constant, Access = ?matlab.unittest.TestCase)
        % Tags for all widgets on Toolstrip
        TagTabGroup = 'RosbagTabGroup'
        TagTabMain = 'ApplicationTab'
        TagSectionFile = 'RosbagFileSection'
        TagSectionVisualize = 'RosbagVisualizeSection'
        TagSectionPlayBack = 'RosbagPlayBackSection'
        TagSectionLayout = 'RosbagLayoutSection'
        TagButtonOpen = 'ButtonOpen'

        TagAddTagSection = 'RosbagViewerAddTagSection'

        TagExportRosBagSection = 'RosbagViewerExportRosBagSection'

        TagListOpenBagFile = 'RosbagOpenFileList'
        TagListOpenNetwork = 'RosNetworkOpenList'
        TagListOpenROS1Network = 'Ros1NetworkOpenList'
        TagListOpenROS2Network = 'Ros2NetworkOpenList'
        TagListSearchROSBag  = 'RosbagViewerSearchROSBag'
        TagButtonLayoutDefault = 'RosbagDefaultLayoutButton'
        TagButtonLayoutGrid = 'RosbagGridLayoutButton'
        TagGalleryVisualizer = 'RosbagVisualizerGallery'
        TagButtonViewerImage = 'RosbagImageViewerButton'
        TagButtonViewerPointCloud = 'RosbagPointCloudViewerButton'
        TagButtonViewerLaserScan = 'RosbagLaserScanViewerButton'
        TagButtonViewerOdometry = 'RosbagOdometryViewerButton'
        TagButtonViewerXYPlot = 'RosbagXYPlotViewerButton'
        TagButtonViewerTimePlot = 'RosbagTimePlotViewerButton'
        TagButtonViewerMessage = 'RosbagMessageViewerButton'
        TagButtonViewerMap = 'RosbagMapViewerButton'
        TagButtonViewerThreeD = 'Rosbag3DViewerButton'
        TagQABHelpButton = 'RosbagViewerQABHelpButton'
        TagAddBookmarkButton = 'RosbagViewerAddBookmarkButton'
        TagManageBookmarkButton = 'RosbagViewerManageBookmarkButton'
        TagBookmarkSection = 'RosbagViewerBookmarkSection'
        TagAddTagButton = 'RosbagViewerAddTagButton'
        TagButtonPlay = 'RosbagViewerPlayButton'
        TagExportButtonOpen = 'RosbagViewerExportButton'
        TagListExportTopic = 'RosbagViewerExportListTopic'
        TagListExportBookmark = 'RosbagViewerExportListBookmark'
        TagButtonViewerMarker = 'RosbagMarkerViewerButton'

        %
        TagToolsSection = 'RosbagViewerViewToolsSection'
        TagViewToggleButton = 'RosbagViewerViewToggleButton'
        TagMeasureDistanceButton = 'RosbagViewerMeasureDistanceButton'


        % Button Icon IDs
        ImageIconID = 'imageViewerPlot';
        LaserScanPlotIconID = 'laserScanPlot';
        OdometryPlotIconID = 'odometryPlot';
        PointCloudPlotIconID = 'pointCloudPlot';
        RawMessagePlotIconID = 'rawMessagePlot';
        TimeSeriesPlotIconID = 'timeSeriesPlot';
        XYPlotIconID = 'xyPlot';
        MapPlotIconID = 'geoPlot';
        MarkerPlotIconID = 'markerVisualizerWide';
        ThreeDPlotIconID = 'gridZPlot'

        SingleTileIconID = 'singleTile';
        CustomTileIconID = 'customTile';
        OpenFolderIconID = 'openFolder';

        OpenBagFileIconID = 'import_rosbag'
        OpenNetworkIconID = 'live_rosNetwork'
        OpenROS1NetworkIconID = 'singleTile'
        OpenROS2NetworkIconID = 'singleTile'
    end

    methods
        function obj = ViewerToolstrip(appContainer)
            %ViewerToolstrip Construct Rosbag Viewer toolstrip on provided app

            % Create the app-relevant tab group and contents
            buildGlobalTabGroup(obj);
            add(appContainer, obj.TabGroup);
            % Quick Access Bar
            buildQAB(obj);
            add(appContainer, obj.QABHelpButton );
        end

        % All callback properties validate and set the same way
        function set.OpenFileCallback(obj, val)
            obj.OpenFileCallback = validateCallback(val, "OpenFileCallback");
        end

        function set.OpenROSMasterURICallback(obj, val)
            obj.OpenROSMasterURICallback = validateCallback(val, "OpenROSMasterURICallback");
        end

        function set.OpenROS2DomainIDCallback(obj, val)
            obj.OpenROS2DomainIDCallback = validateCallback(val, "OpenROS2DomainIDCallback");
        end

        function set.SearchCallback(obj, val)
            obj.SearchCallback = validateCallback(val, "SearchCallback");
        end

        function set.DefaultLayoutCallback(obj, val)
            obj.DefaultLayoutCallback = validateCallback(val, "DefaultLayoutCallback");
        end

        function set.GridLayoutCallback(obj, val)
            obj.GridLayoutCallback = validateCallback(val, "GridLayoutCallback");
        end

        function set.ImageViewerCallback(obj, val)
            obj.ImageViewerCallback = validateCallback(val, "ImageViewerCallback");
        end

        function set.PointCloudViewerCallback(obj, val)
            obj.PointCloudViewerCallback = validateCallback(val, "PointCloudViewerCallback");
        end

        function set.LaserScanViewerCallback(obj, val)
            obj.LaserScanViewerCallback = validateCallback(val, "LaserScanViewerCallback");
        end

        function set.OdometryViewerCallback(obj, val)
            obj.OdometryViewerCallback = validateCallback(val, "OdometryViewerCallback");
        end

        function set.XYPlotViewerCallback(obj, val)
            obj.XYPlotViewerCallback = validateCallback(val, "XYPlotViewerCallback");
        end

        function set.TimePlotViewerCallback(obj, val)
            obj.TimePlotViewerCallback = validateCallback(val, "TimePlotViewerCallback");
        end

        function set.MessageViewerCallback(obj, val)
            obj.MessageViewerCallback = validateCallback(val, "RawMessageViewerCallback");
        end

        function set.MapViewerCallback(obj, val)
            obj.MapViewerCallback = validateCallback(val, "MapViewerCallback");
        end
        function set.ManageBookmarkCallback(obj, val)
            obj.ManageBookmarkCallback = validateCallback(val, "ManageBookmarkCallback");
        end

        function set.AddBookmarkCallback(obj, val)
            obj.AddBookmarkCallback = validateCallback(val, "AddBookmarkCallback");
        end

        function set.AddTagCallback(obj, val)
            obj.AddTagCallback = validateCallback(val, "AddTagCallback");
        end

        function set.ExportFromTopicCallback(obj, val)
            obj.ExportFromTopicCallback = validateCallback(val, "ExportFromTopicCallback");
        end

        function set.ExportFromBookmarkCallback(obj, val)
            obj.ExportFromBookmarkCallback = validateCallback(val, "ExportFromBookmarkCallback");
        end

        function set.PlayCallback(obj, val)
            obj.PlayCallback = validateCallback(val, "PlayCallback");
        end

        function set.ThreeDViewerCallback(obj, val)
            obj.ThreeDViewerCallback = validateCallback(val, "ThreeDCallback");
        end

        % TO-DO: Add Marker Viewer Callback
        function set.MarkerViewerCallback(obj, val)
            obj.MarkerViewerCallback = validateCallback(val, "MarkerViewerCallback");
        end
        % END

        % TO-DO: Add View Toggle Callback
        function set.ViewToggleCallback(obj, val)
            obj.ViewToggleCallback = validateCallback(val, "ViewToggleCallback");
        end
        % END

        % TO-DO: Add Measure Distance Tool Callback
        function set.MeasureDistanceCallback(obj, val)
            obj.MeasureDistanceCallback = validateCallback(val, "MeasureDistanceCallback");
        end
        % END

        % set the widgetproperties
        function setGridLayoutButtonProperties(obj, property, val)
            obj.GridLayoutButton.(property) = val;
        end

        function enableBookmarkSection(obj)
            obj.AddBookmarkButton.Enabled = matlab.lang.OnOffSwitchState.on;
            obj.ManageBookmarkButton.Enabled = matlab.lang.OnOffSwitchState.on;
        end

        function enableToolsSection(obj)
            obj.AddMeasureDistanceButton.Enabled = matlab.lang.OnOffSwitchState.on;
            obj.AddViewToggleButton.Enabled = matlab.lang.OnOffSwitchState.on;
        end

        function enableOnlyViewTool(obj)
            obj.AddViewToggleButton.Enabled = matlab.lang.OnOffSwitchState.on;
        end

        function disableToolsSection(obj)
            obj.AddMeasureDistanceButton.Enabled = matlab.lang.OnOffSwitchState.off;
            obj.AddViewToggleButton.Enabled = matlab.lang.OnOffSwitchState.off;
        end

        function startPlayback(obj)
            %startPlayback Do required changes to start the playback

            %icon = matlab.ui.internal.toolstrip.Icon('PAUSE_24', 'Pause_24');
            obj.PlayButton.Icon = "stopMono";
            obj.PlayButton.Description = getString(message('ros:visualizationapp:view:StopVisualizationTooltip'));
            obj.PlayButton.Text = getString(message('ros:visualizationapp:view:StopVisualizationLabel'));
        end

        function stopPlayback(obj)
            %stopPlayback Do required changes to stop the playback

            %icon = matlab.ui.internal.toolstrip.Icon('RUN_24', 'Run_24');
            obj.PlayButton.Icon = "playMono";
            obj.PlayButton.Description = getString(message('ros:visualizationapp:view:StartVisualizationTooltip'));
            obj.PlayButton.Text = getString(message('ros:visualizationapp:view:StartVisualizationLabel'));
        end

        function setAppMode(obj,appMode)
            %setAppMode sets the app mode (bag file / live network data visualization)
            %and makes necessary UI changes

            if appMode == ros.internal.ViewerPresenter.RosbagVisualization
                obj.addSectionFromTab(obj.BMSection,obj.ApplicationTab)
                obj.addSectionFromTab(obj.TagRosBagSection,obj.ApplicationTab)
                obj.addSectionFromTab(obj.ExportRosBagSection, obj.ApplicationTab)
                obj.addSectionFromTab(obj.ToolsSection,obj.ApplicationTab)
                obj.removeSectionFromTab(obj.PlayBackSection,obj.ApplicationTab)
                
            else
                obj.removeSectionFromTab(obj.BMSection,obj.ApplicationTab)
                obj.removeSectionFromTab(obj.TagRosBagSection,obj.ApplicationTab)
                obj.removeSectionFromTab(obj.ExportRosBagSection, obj.ApplicationTab)
                obj.removeSectionFromTab(obj.ToolsSection,obj.ApplicationTab)
                obj.addSectionFromTab(obj.PlayBackSection,obj.ApplicationTab)
              
            end
        end
    end

    methods (Access = protected)
        function addSectionFromTab(~,section,tab)
            if isempty(tab.find(section.Tag))
                tab.add(section)
            end
        end

        function removeSectionFromTab(~,section,tab)
            if ~isempty(tab.find(section.Tag))
                tab.remove(section)
            end
        end

        function buildGlobalTabGroup(obj)
            %buildGlobalTabGroup Construct the primary toolstrip tab group

            % Toolstrip and tabs
            obj.TabGroup = matlab.ui.internal.toolstrip.TabGroup;
            obj.TabGroup.Tag = obj.TagTabGroup;

            text = getString(message('ros:visualizationapp:view:RosbagLabel'));
            obj.ApplicationTab = matlab.ui.internal.toolstrip.Tab(text);
            obj.ApplicationTab.Tag = obj.TagTabMain;
            add(obj.TabGroup, obj.ApplicationTab)

            % File functionality
            text = getString(message('ros:visualizationapp:view:FileLabel'));
            obj.FileSection = addSection(obj.ApplicationTab, text);
            obj.FileSection.Tag = obj.TagSectionFile;
            bmColumn = addColumn(obj.FileSection);

            text = getString(message('ros:visualizationapp:view:OpenLabel'));

            import matlab.ui.internal.toolstrip.*
            hPopup = PopupList();
            item = ListItem(getString(message('ros:visualizationapp:view:OpenBagFile')), obj.OpenBagFileIconID);
            item.Description = getString(message('ros:visualizationapp:view:OpenBagFileTooltip'));
            item.ShowDescription = true;
            item.Tag = obj.TagListOpenBagFile;
            item.ItemPushedFcn = @(src, event) buttonCallback(obj.OpenFileCallback, src, event);
            hPopup.add(item);
            obj.OpenFileItem = item;

            % list item with popup
            item = ListItemWithPopup(getString(message('ros:visualizationapp:view:OpenLiveData')),obj.OpenNetworkIconID);
            item.Description = getString(message('ros:visualizationapp:view:OpenLiveDataTooltip'));
            item.ShowDescription = true;
            item.Tag = obj.TagListOpenNetwork;
            hPopup.add(item);
            obj.OpenNetworkItem = item;

            % Sub-popup
            hSubPopup = PopupList();
            item.Popup = hSubPopup;
            % sub list item #1
            sub_item1 = ListItem(getString(message('ros:visualizationapp:view:OpenLiveROS1Data')));
            sub_item1.Description = getString(message('ros:visualizationapp:view:OpenLiveROS1DataTooltip'));
            sub_item1.ShowDescription = true;
            sub_item1.ItemPushedFcn = @(src, event) buttonCallback(obj.OpenROSMasterURICallback, src, event);
            sub_item1.Tag = obj.TagListOpenROS1Network;
            hSubPopup.add(sub_item1);
            obj.OpenROS1NetworkItem = sub_item1;

            % sub list item #2
            sub_item2 = ListItem(getString(message('ros:visualizationapp:view:OpenLiveROS2Data')));
            sub_item2.Description = getString(message('ros:visualizationapp:view:OpenLiveROS2DataTooltip'));
            sub_item2.ShowDescription = true;
            sub_item2.ItemPushedFcn = @(src, event) buttonCallback(obj.OpenROS2DomainIDCallback, src, event);
            sub_item2.Tag = obj.TagListOpenROS2Network;
            hSubPopup.add(sub_item2);
            obj.OpenROS2NetworkItem = sub_item2;
            obj.OpenFileButton = DropDownButton(text, 'openFolder');
            obj.OpenFileButton.Popup = hPopup;
            obj.OpenPopupList = hPopup;

            obj.OpenFileButton.Tag = obj.TagButtonOpen;
            obj.OpenFileButton.Description = ...
                getString(message('ros:visualizationapp:view:OpenDescription'));

            add(bmColumn, obj.OpenFileButton)

            % Add Search Button
            text = getString(message('ros:visualizationapp:view:SearchROSBag'));
            sub_item3 = ListItem(text, matlab.ui.internal.toolstrip.Icon('find_rosbag'));
            sub_item3.Description = getString(message('ros:visualizationapp:view:SearchROSBagTooltip'));
            sub_item3.ShowDescription = true;
            sub_item3.Tag = obj.TagListSearchROSBag;
            sub_item3.ItemPushedFcn = @(src, event) buttonCallback(obj.SearchCallback, src, event);
            hPopup.add(sub_item3);
            obj.SearchROSBagItem = sub_item3;

            % Visualizer functionality
            text = getString(message('ros:visualizationapp:view:VisualizeLabel'));
            obj.VisualizeSection = addSection(obj.ApplicationTab, text);
            obj.VisualizeSection.Tag = obj.TagSectionVisualize;
            visualizeColumn = addColumn(obj.VisualizeSection);

            text = getString(message('ros:visualizationapp:view:VisualizersLabel'));
            obj.VisualizeCategory = matlab.ui.internal.toolstrip.GalleryCategory(text);
            % Add Image Visualizer
            text = getString(message('ros:visualizationapp:view:ImageLabel'));
            obj.ImageViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.ImageIconID));
            obj.ImageViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:ImageTooltip'));
            obj.ImageViewerButton.Tag = obj.TagButtonViewerImage;
            obj.ImageViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.ImageViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.ImageViewerButton);

            % Add Point Cloud Visualizer
            text = getString(message('ros:visualizationapp:view:PointCloudLabel'));
            obj.PointCloudViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.PointCloudPlotIconID));
            obj.PointCloudViewerButton.Tag = obj.TagButtonViewerPointCloud;
            obj.PointCloudViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:PointCloudTooltip'));
            obj.PointCloudViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.PointCloudViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.PointCloudViewerButton);

            % Add LaserScan Visualizer
            text = getString(message('ros:visualizationapp:view:LaserScanLabel'));
            obj.LaserScanViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.LaserScanPlotIconID));
            obj.LaserScanViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:LaserScanTooltip'));
            obj.LaserScanViewerButton.Tag = obj.TagButtonViewerLaserScan;
            obj.LaserScanViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.LaserScanViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.LaserScanViewerButton);

            % Add Odometry Visualizer
            text = getString(message('ros:visualizationapp:view:OdometryLabel'));
            obj.OdometryViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.OdometryPlotIconID));
            obj.OdometryViewerButton.Tag = obj.TagButtonViewerOdometry;
            obj.OdometryViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:OdometryTooltip'));
            obj.OdometryViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.OdometryViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.OdometryViewerButton);

            % Add XYPlot Visualizer
            text = getString(message('ros:visualizationapp:view:XYPlotLabel'));
            obj.XYPlotViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.XYPlotIconID));
            obj.XYPlotViewerButton.Tag = obj.TagButtonViewerXYPlot;
            obj.XYPlotViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:XYPlotTooltip'));
            obj.XYPlotViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.XYPlotViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.XYPlotViewerButton);

            % Add TimePlot Visualizer
            text = getString(message('ros:visualizationapp:view:TimePlotLabel'));
            obj.TimePlotViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.TimeSeriesPlotIconID));
            obj.TimePlotViewerButton.Tag = obj.TagButtonViewerTimePlot;
            obj.TimePlotViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:TimePlotTooltip'));
            obj.TimePlotViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.TimePlotViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.TimePlotViewerButton);

            % Add Message Visualizer
            text = getString(message('ros:visualizationapp:view:MessageLabel'));
            obj.MessageViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.RawMessagePlotIconID));
            obj.MessageViewerButton.Tag = obj.TagButtonViewerMessage;
            obj.MessageViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:MessageTooltip'));
            obj.MessageViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.MessageViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.MessageViewerButton);
            % Add Map Visualizer
            text = getString(message('ros:visualizationapp:view:MapLabel'));
            obj.MapViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.MapPlotIconID));
            obj.MapViewerButton.Tag = obj.TagButtonViewerMap;
            obj.MapViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:MapTooltip'));
            obj.MapViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.MapViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.MapViewerButton);


            % Add 3D Visualizer
            text = getString(message('ros:visualizationapp:view:ThreeDLabel'));
            obj.ThreeDViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.ThreeDPlotIconID));
            obj.ThreeDViewerButton.Tag = obj.TagButtonViewerThreeD;
            obj.ThreeDViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:ThreeDTooltip'));
            obj.ThreeDViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.ThreeDViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.ThreeDViewerButton);


            % Add Layout Buttons
            visualizePopup = matlab.ui.internal.toolstrip.GalleryPopup(...
                'IconSize', 40, 'GalleryItemTextLineCount', 1);
            add(visualizePopup, obj.VisualizeCategory);

            visualizeGallery = matlab.ui.internal.toolstrip.Gallery(visualizePopup, ...
                'MaxColumnCount', 6, ...
                'MinColumnCount', 3);
            visualizeGallery.Tag = obj.TagGalleryVisualizer;
            add(visualizeColumn, visualizeGallery)

            % Layout arrangement functionality
            text = getString(message('ros:visualizationapp:view:LayoutLabel'));
            obj.LayoutSection = addSection(obj.ApplicationTab, text);
            obj.LayoutSection.Tag = obj.TagSectionLayout;
            layoutDefaultColumn = addColumn(obj.LayoutSection);
            layoutGridColumn = addColumn(obj.LayoutSection);

            text = getString(message('ros:visualizationapp:view:DefaultLayoutLabel'));
            obj.DefaultLayoutButton = ...
                matlab.ui.internal.toolstrip.Button(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.SingleTileIconID));
            obj.DefaultLayoutButton.Tag = obj.TagButtonLayoutDefault;
            obj.DefaultLayoutButton.Description = ...
                getString(message('ros:visualizationapp:view:DefaultLayoutDescription'));
            obj.DefaultLayoutButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.DefaultLayoutCallback, src, event);
            add(layoutDefaultColumn, obj.DefaultLayoutButton)

            text = getString(message('ros:visualizationapp:view:GridLayoutLabel'));
            obj.GridLayoutButton = ...
                matlab.ui.internal.toolstrip.GridPickerButton(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.CustomTileIconID));
            obj.GridLayoutButton.Tag = obj.TagButtonLayoutGrid;
            obj.GridLayoutButton.Description = ...
                getString(message('ros:visualizationapp:view:GridLayoutDescription'));
            obj.GridLayoutButton.ValueChangedFcn = ...
                @(src, event) buttonCallback(obj.GridLayoutCallback, src, event);
            add(layoutGridColumn, obj.GridLayoutButton)

            % Add Bookmark
            % Layout arrangement functionality
            text = getString(message('ros:visualizationapp:view:BookmarkLabel'));
            obj.BMSection = addSection(obj.ApplicationTab, text);
            obj.BMSection.Tag = obj.TagBookmarkSection;
            bmAddColumn = addColumn(obj.BMSection);
            bmManageColumn = addColumn(obj.BMSection);
            %initially remove BM section from view
            obj.ApplicationTab.remove(obj.BMSection)

            % Add
            text = getString(message('ros:visualizationapp:view:AddBookmarkLabel'));
            obj.AddBookmarkButton = ...
                matlab.ui.internal.toolstrip.Button(text, ...
                matlab.ui.internal.toolstrip.Icon('add_bookmark'));
            obj.AddBookmarkButton.Tag = obj.TagAddBookmarkButton;
            obj.AddBookmarkButton.Description = getString(message('ros:visualizationapp:view:AddBookmarkTooltip'));
            add(bmAddColumn, obj.AddBookmarkButton);
            obj.AddBookmarkButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.AddBookmarkCallback, src, event);
            %obj.AddBookmarkButton.Enabled = matlab.lang.OnOffSwitchState.off;

            % Manage
            text =  getString(message('ros:visualizationapp:view:ManageBookmarkLabel'));
            obj.ManageBookmarkButton = ...
                matlab.ui.internal.toolstrip.Button(text, ...
                matlab.ui.internal.toolstrip.Icon('edit_bookmark'));
            obj.ManageBookmarkButton.Tag = obj.TagManageBookmarkButton;
            obj.ManageBookmarkButton.Description = getString(message('ros:visualizationapp:view:ManageBookmarkTooltip'));
            %obj.ManageBookmarkButton.Enabled = matlab.lang.OnOffSwitchState.off;
            add(bmManageColumn, obj.ManageBookmarkButton);
            obj.ManageBookmarkButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.ManageBookmarkCallback, src, event);


            % Tag rosbag section
            % Layout arrangement functionality
            text = getString(message('ros:visualizationapp:view:TagSection'));
            obj.TagRosBagSection = addSection(obj.ApplicationTab, text);
            obj.TagRosBagSection.Tag = obj.TagAddTagSection;
            tagAddColumn = addColumn(obj.TagRosBagSection);
            %initially remove BM section from view
            obj.ApplicationTab.remove(obj.TagRosBagSection)

            % Add
            text = getString(message('ros:visualizationapp:view:AddTag'));
            obj.AddTagButton = ...
                matlab.ui.internal.toolstrip.Button(text, ...
                matlab.ui.internal.toolstrip.Icon('label_rosbag'));
            obj.AddTagButton.Tag = obj.TagAddTagButton;
            obj.AddTagButton.Description = getString(message('ros:visualizationapp:view:AddTagTooltip'));
            add(tagAddColumn, obj.AddTagButton);
            obj.AddTagButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.AddTagCallback, src, event);


            text = getString(message('ros:visualizationapp:view:StartStopSectionLabel'));
            obj.PlayBackSection = addSection(obj.ApplicationTab, text);
            obj.PlayBackSection.Tag = obj.TagSectionPlayBack;
            pbColumn = addColumn(obj.PlayBackSection);
            obj.ApplicationTab.remove(obj.PlayBackSection)
            text = getString(message('ros:visualizationapp:view:StartVisualizationLabel'));
            obj.PlayButton = ...
                matlab.ui.internal.toolstrip.Button(text, "playMono");
            obj.PlayButton.Tag = obj.TagButtonPlay;
            obj.PlayButton.Description = getString(message('ros:visualizationapp:view:StartVisualizationTooltip'));
            obj.PlayButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.PlayCallback, src, event);
            add(pbColumn, obj.PlayButton)

            % Export section
            text = getString(message('ros:visualizationapp:view:ExportSectionLabel'));
            obj.ExportRosBagSection = addSection(obj.ApplicationTab, text);
            obj.ExportRosBagSection.Tag = obj.TagExportRosBagSection;
            exportColumn = addColumn(obj.ExportRosBagSection);

            %Export Popup
            ePopup = PopupList();

            % Export from Topic
            item = ListItem(getString(message('ros:visualizationapp:view:ExportFromTopicTitle')), ...
                matlab.ui.internal.toolstrip.Icon('export_rosbag'));
            item.Description = getString(message('ros:visualizationapp:view:ExportFromTopicDescription'));
            item.ShowDescription = true;
            item.Tag = obj.TagListExportTopic;
            item.ItemPushedFcn = @(src, event) buttonCallback(obj.ExportFromTopicCallback, src, event);
            ePopup.add(item);
            obj.ExportFromTopicItem = item;

            %Export from Bookmark
            item = ListItem(getString(message('ros:visualizationapp:view:ExportFromBookmarkTitle')), ...
                matlab.ui.internal.toolstrip.Icon('export_bookmark'));
            item.Description = getString(message('ros:visualizationapp:view:ExportFromBookmarkDescription'));
            item.ItemPushedFcn = @(src, event) buttonCallback(obj.ExportFromBookmarkCallback, src, event);
            item.Tag = obj.TagListExportBookmark;
            ePopup.add(item);
            obj.ExportFromBookmarksItem = item;

            text = getString(message('ros:visualizationapp:view:ExportSectionLabel'));
            obj.ExportPopupListButton = DropDownButton(text, ...
                matlab.ui.internal.toolstrip.Icon('export'));
            obj.ExportPopupListButton.Tag = obj.TagExportButtonOpen;
            obj.ExportPopupListButton.Popup = ePopup;
            obj.ExportPopupListButton.Description = getString(message('ros:visualizationapp:view:ExportButtonDescription'));
            add(exportColumn, obj.ExportPopupListButton);

            obj.ApplicationTab.remove(obj.ExportRosBagSection);
            % Add Marker Visualizer
            text = getString(message('ros:visualizationapp:view:MarkerLabel'));
            obj.MarkerViewerButton = ...
                matlab.ui.internal.toolstrip.GalleryItem(text, ...
                matlab.ui.internal.toolstrip.Icon(obj.MarkerPlotIconID));
            obj.MarkerViewerButton.Tag = obj.TagButtonViewerMarker;
            obj.MarkerViewerButton.Description = ...
                getString(message('ros:visualizationapp:view:MarkerTooltip'));
            obj.MarkerViewerButton.ItemPushedFcn = ...
                @(src, event) buttonCallback(obj.MarkerViewerCallback, src, event);
            add(obj.VisualizeCategory, obj.MarkerViewerButton);
            % remove(obj.VisualizeCategory, obj.MarkerViewerButton);

            % Tools Section
            text = getString(message('ros:visualizationapp:view:ToolsLabel'));
            obj.ToolsSection = addSection(obj.ApplicationTab, text);
            obj.ToolsSection.Tag = obj.TagToolsSection;
            tagAddColumn = addColumn(obj.ToolsSection);

            %initially remove tools section from view
            obj.ApplicationTab.remove(obj.ToolsSection);

            % Add
            text = getString(message('ros:visualizationapp:view:ViewToggle'));
            obj.AddViewToggleButton = matlab.ui.internal.toolstrip.Button(text, ...
                                        matlab.ui.internal.toolstrip.Icon('2d'));
            obj.AddViewToggleButton.Tag = obj.TagViewToggleButton;
            obj.AddViewToggleButton.Description = getString(message('ros:visualizationapp:view:AddViewToggleTooltip'));
            add(tagAddColumn, obj.AddViewToggleButton);

            obj.AddViewToggleButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.ViewToggleCallback, src, event);

            % Add Distance Measuring Tool
            text = getString(message('ros:visualizationapp:view:MeasureDistance'));
            obj.AddMeasureDistanceButton = ...
                matlab.ui.internal.toolstrip.Button(text, ...
                matlab.ui.internal.toolstrip.Icon('distanceMeasurement'));
            obj.AddMeasureDistanceButton.Tag = obj.TagMeasureDistanceButton;
            obj.AddMeasureDistanceButton.Description = getString(message('ros:visualizationapp:view:AddMeasureDistanceTooltip'));
            add(tagAddColumn, obj.AddMeasureDistanceButton);
            obj.AddMeasureDistanceButton.ButtonPushedFcn = ...
                @(src, event) buttonCallback(obj.MeasureDistanceCallback, src, event);
            obj.disableToolsSection(); % disable this by default
        end

        function buildQAB(obj)
            % buildQAB used to build Quick Access Bar
            % add Help button to QAB

            obj.QABHelpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            obj.QABHelpButton.DocName = 'rosbagViewer';
            obj.QABHelpButton.Tag = obj.TagQABHelpButton;

            %g3288704 Add 'helpview' callback to help button
            obj.QABHelpButton.ButtonPushedFcn = @(h, e) helpview('ros', 'rosbagViewer');
        end
    end
end

% Helper functions that have no need for class access

function buttonCallback(fcn, varargin)
%buttonCallback Evaluate specified function with arguments if not empty

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
        "ViewerToolstrip", ...
        propertyName)
end
end

% LocalWords:  APPCONTAINER QAB widgetproperties lang DViewer DCallback DLabel DTooltip ZPlot
