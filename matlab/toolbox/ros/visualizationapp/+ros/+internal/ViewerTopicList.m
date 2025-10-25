classdef ViewerTopicList < handle
%This class is for internal use only. It may be removed in the future.

%ViewerTopicList Rosbag topic contents UI for the Rosbag Viewer app
%   TOPICLIST = ros.internal.ViewerTopicList(APPCONTAINER)
%      Create the RosbagViewer topic list in the provided app container.
%      Each topic will be expandable to see which fields are contained
%      within that topic's messages.

%   Copyright 2022-2023 The MathWorks, Inc.

% UI objects
    properties (Access = ?matlab.unittest.TestCase)
        % Figure panel containing all topic details
        TopicPanel
        
        % Figure panel containing all source details
        SourcePanel

        % Contains all UI objects for source details
        SourceDetails

        % Tree containing topics and message field information
        UIHTMLTopicListData

        % Topic List Data
        TopicListData

        % Bag tree
        BagTree

        % RefreshButton to refresh the topic list
        RefreshButton

        % Grid that holds the UI elements
        Grid
    end

    properties
        RefreshCallback = function_handle.empty
        TagButtonRefresh = 'TopicListRefreshButton'
    end

    % Values needed for testing
    properties (Constant, Access = ?matlab.unittest.TestCase)
        TagTopicPanel = 'RosbagViewerTopicListPanel'
        TagTopicTree = 'RosbagViewerTopicListTree'

        TagSourcePanel = 'RosbagViewerSourcePanel'
        TagSourceDetails = 'RosbagViewerSourceDetails'

        % PreferredWidth factor of the panel
        WindowSize = ros.internal.utils.getWindowBounds;
        PreferredWidthFactor = 0.20 % 20% of the window size
    end

    methods (Static, Access = ?ros.internal.mixin.ROSInternalAccess)
        function onThemeChanged(objWeakHndl)
            obj = objWeakHndl.get();
            reloadViewer(obj);
        end
    end

    methods
        function obj = ViewerTopicList(appContainer)
        %ViewerTopicList Construct a topic list panel on the provided app

            buildTopicListPanel(obj)
            add(appContainer, obj.TopicPanel)

            buildSourceDetailsPanel(obj)
            add(appContainer, obj.SourcePanel)

            htmlData.mlMode = getTheme(obj);
            htmlData.id = 'mlMode';
            obj.SourceDetails.Data = htmlData;
            obj.UIHTMLTopicListData.Data = htmlData;

            wObj = matlab.internal.WeakHandle(obj);
            addlistener(obj.TopicPanel.Figure, "ThemeChanged",@(~,~)ros.internal.ViewerTopicList.onThemeChanged(wObj));
        end
        
        function set.RefreshCallback(obj, val)
            % Set callback to refresh the topic list

            obj.RefreshCallback = validateCallback(val, "RefreshCallback");
        end

        function setAppMode(obj,appMode)
            % Set app mode and make necessary UI changes

            if appMode == ros.internal.ViewerPresenter.RosbagVisualization
                obj.Grid.RowHeight{1} = 0;
            else
                obj.Grid.RowHeight{1} = 30;
            end
        end

        function createTopicTreeForLive(obj, topicDeatils)
            %Creates the topic tree on UI
            
            % Send source info to html
            htmlData.id = 'sourceInfo';

            htmlData.sourceInfo = struct('sourceName', topicDeatils.rosNetworkInput);
            if topicDeatils.rosVer == "ros1"
                htmlData.labels = struct('sourceName', 'ROS MasterURI');
            else
                htmlData.labels = struct('sourceName', 'ROS Domain ID');
            end
            htmlData.mlMode = getTheme(obj);
            % Send data to html page
            obj.SourceDetails.Data = htmlData;

            topicInfo = struct('topic', '', 'type', '');
            for k = 1:numel(topicDeatils.topic)
                topicName = topicDeatils.topic{k};
                topicType = topicDeatils.type{k};
                topicInfo(k) = struct('topic', topicName, 'type', topicType);
            end

            obj.TopicListData = topicInfo;

            htmlData = [];
            % Send topic info to html
            htmlData.id = 'topicInfo';
            htmlData.topicInfo = obj.TopicListData;
            htmlData.mlMode = getTheme(obj);

            % Send data to html page
            obj.UIHTMLTopicListData.Data = htmlData;
        end

        function createTopicTree(obj, bagTree)
        %createTopicTree Replace topic list with new topic-field tree
            obj.BagTree = bagTree;
            validateattributes(bagTree, "ros.internal.RosbagTree", ...
                               "scalar", "createTopicTree", "bagTree")
            % 
            obj.TopicListData = obj.parseBagTreeForTopicDetails(bagTree);
            % Send source info to html
            htmlData.id = 'sourceInfo';
            startTime = string(datetime(bagTree.Rosbag.StartTime, "ConvertFrom","posixtime",...
                                "TimeZone","local","Format","dd-MMM-uuuu HH:mm:ss.SSS"));
            endTime = string(datetime(bagTree.Rosbag.EndTime, "ConvertFrom","posixtime",...
                                "TimeZone","local","Format","dd-MMM-uuuu HH:mm:ss.SSS"));
            
            bagSize = char(string(bagTree.Rosbag.getBagSize/(1024*1024)));
            
            [~, fName, fExt] = fileparts(bagTree.Rosbag.FilePath);
            htmlData.sourceInfo = struct('sourceName', [fName fExt ' (' bagSize ' MB)'],...
                                        'startTime', startTime,'endTime',endTime,...
                                        'duration', bagTree.Rosbag.EndTime - bagTree.Rosbag.StartTime, ...
                                        'messageCount', bagTree.Rosbag.NumMessages);
            htmlData.labels = struct('sourceName', getString(message("ros:visualizationapp:view:SourceNameLabel")),...
                                        'startTime', getString(message("ros:visualizationapp:view:StartTimeLabel")),...
                                        'endTime', getString(message("ros:visualizationapp:view:EndTimeLabel")),...
                                        'duration', getString(message("ros:visualizationapp:view:DurationLabel")), ...
                                        'messageCount', getString(message("ros:visualizationapp:view:MessageCountLabel")));
            htmlData.mlMode = getTheme(obj);
            
            % Send data to html page
            obj.SourceDetails.Data = htmlData;
            
            htmlData = [];
            % Send topic info to html
            htmlData.id = 'topicInfo';
            htmlData.topicInfo = obj.TopicListData;
            htmlData.mlMode = getTheme(obj);

            % Send data to html page
            obj.UIHTMLTopicListData.Data = htmlData;
        end

        function theme = getTheme(obj)
            % getTheme returns if the current theme is light or dark

            theme = 'light';
            if ~isempty(obj.TopicPanel.Figure.Theme)
                theme = lower(obj.TopicPanel.Figure.Theme.BaseColorStyle);
            end
        end
        
        function reloadViewer(obj)
            if ~isempty(obj.BagTree) && isvalid(obj.BagTree)
                createTopicTree(obj, obj.BagTree);
            else
                htmlData.mlMode = getTheme(obj);
                htmlData.id = 'mlMode';
                obj.SourceDetails.Data = htmlData;
                obj.UIHTMLTopicListData.Data = htmlData;
            end
        end

        function out = getTopicListData(obj)
            % getter for TopicListData

            out = obj.TopicListData;
        end

        function out = getFrequencyForTopic(obj, topics)
            % getFrequencyForTopic

            out = struct("Topic", "", "Frequency", 0);
            for indx = 1: numel(topics)
                out(indx).Topic = topics(indx);
                fhdl = @(x)obj.TopicListData(x).topic == topics(indx);
                tf = arrayfun(fhdl, 1:numel(obj.TopicListData));
                out(indx).Frequency = obj.TopicListData(find(tf)).frequency;
            end
        end
    end

    methods (Access = protected)

        function buildTopicListPanel(obj)
        %buildTopicListPanel Create topic panel and initialize contents

        % Add the topic tree panel to the left
            panelOptions = struct(...
                "Title", getString(message("ros:visualizationapp:view:TopicListLabel")), ...
                "Region", "left");
            obj.TopicPanel = matlab.ui.internal.FigurePanel(panelOptions);
            obj.TopicPanel.Tag = obj.TagTopicPanel;
            obj.TopicPanel.PreferredWidth = obj.WindowSize(3) * obj.PreferredWidthFactor;

            % Setup grid layout
            grid = uigridlayout(obj.TopicPanel.Figure, [2 1], ...
                                "Padding", [0 0 0 0]);
            
            text = getString(message("ros:visualizationapp:view:RefreshBtnTxt"));
            obj.RefreshButton = ...
                uibutton(grid, "Text",text,  "Tag", obj.TagButtonRefresh, ... 
                "Tooltip",getString(message("ros:visualizationapp:view:RefreshBtnTooltip")));
            obj.RefreshButton.Layout.Row = 1;
            obj.RefreshButton.Layout.Column = 1;
            matlab.ui.control.internal.specifyIconID(obj.RefreshButton, 'refresh', 16);
            obj.RefreshButton.ButtonPushedFcn = ...
                @(src, event) makeCallback(obj.RefreshCallback, src, event);
            grid.RowHeight{1} = 0;
            
            obj.Grid = grid;

            % Add empty topic tree
            obj.UIHTMLTopicListData = uihtml(grid);
            obj.UIHTMLTopicListData.Layout.Row = 2;
            obj.UIHTMLTopicListData.Layout.Column = 1;
            obj.UIHTMLTopicListData.Tag = obj.TagTopicTree;
            obj.UIHTMLTopicListData.HTMLSource = fullfile(matlabroot,'toolbox','ros','visualizationapp','html','topiclist.html'); 
        end

        function buildSourceDetailsPanel(obj)
        %buildTopicListPanel Create topic panel and initialize contents

        % Add the topic tree panel to the left
            panelOptions = struct(...
                "Title", getString(message("ros:visualizationapp:view:SourceDetailsLabel")), ...
                "Region", "left","PreferredHeight", 186);
            obj.SourcePanel = matlab.ui.internal.FigurePanel(panelOptions);
            obj.SourcePanel.Tag = obj.TagSourcePanel;
            obj.SourcePanel.PreferredWidth = obj.WindowSize(3) * obj.PreferredWidthFactor;

            % Setup grid layout
            grid = uigridlayout(obj.SourcePanel.Figure, [1 1], ...
                                "Padding", [0 0 0 0]);
            obj.SourceDetails = uihtml(grid);
            obj.SourceDetails.Tag = obj.TagSourceDetails;
            obj.SourceDetails.HTMLSource=fullfile(matlabroot,'toolbox','ros','visualizationapp','html','topiclist.html');
        end

        function topicInfo = parseBagTreeForTopicDetails(~, bagTree)
            %parseBagTreeForTopicDetails

            topicTable = bagTree.Rosbag.AvailableTopics;
            topicInfo = struct('topic', '', 'type', '', ...
                               'numMsgs', 0, 'frequency', 0);
            for k = 1:numel(topicTable.Row)
                topicName = topicTable.Row{k};
                topicType = char(topicTable.MessageType(k));
                numMessages = topicTable.NumMessages(k);
                frequency = ceil(numMessages/(bagTree.Rosbag.EndTime - bagTree.Rosbag.StartTime));
                topicInfo(k) = struct('topic', topicName, 'type', topicType, ...
                    'numMsgs', numMessages, 'frequency', frequency);
            end
        end

        function topicInfo = parseTopiclistForLive(topicNames, topicTypes)
            topicInfo = struct('topic', '', 'type', '');
            
            for k = 1:numel(topicNames)
                topicName = char(topicNames{k});
                topicType = char(topicTypes{k});
                topicInfo(k) = struct('topic', topicName, 'type', topicType);
            end
        end
    end
end

function fillInMessageFields(parentNode, bagTree, type)
%fillInMessageFields Recursively create tree nodes for message fields

    msgInfo = getInfoFromType(bagTree, type);
    for k = 1:numel(msgInfo.Names)
        treeNode = uitreenode(parentNode, "Text", msgInfo.Names{k});
        if msgInfo.IsMessage(k)
            fillInMessageFields(treeNode, bagTree, msgInfo.Types{k})
        end
    end
end

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
            "ViewerTimeline", ...
            propertyName)
    end
end