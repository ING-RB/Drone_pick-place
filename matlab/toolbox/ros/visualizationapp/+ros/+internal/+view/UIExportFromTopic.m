classdef UIExportFromTopic < handle
    %This class is for internal use only. It may be removed in the future.

    %UIExportFromTopic App is used to create the app for exporting messages
    %to new bag file based on selected topics
    %   uiapphndl = ros.internal.view.UIExportFromTopic()
    %   uiapphndl.showApp()

    %   Copyright 2024 The MathWorks, Inc.
    
    % UI Objects
    properties
        FigureHandle
        MainGridLayout 
        TitleLabelObj
        DescriptionLabelObj 

        TopicListBoxObj 

        TimestampLabelObj

        DurationSliderObj 
        
        SubGrid1Obj

        StartTimeLabelObj
        StartTimePanelObj 
        

        DurationLabelObj
        DurationTimePanelObj

        StorageTypeDropDownObj 
        
        SubGrid2Obj 
        Hid1Obj
        Hid2Obj
        CancelButtonObj 
        ExportButtonObj
    end
    
    properties (Constant, Access = ?matlab.unittest.TestCase)
        % definition of all the tags for the widgets
        AppTag = 'ExportFromTopicUITag';
        AppMainGridTag = 'ExportFromTopicUIMainGridTag';
        
        TitleLabelTag = 'ExportFromTopicUITitleLabelTag';
        DescriptionLabelTag = 'ExportFromTopicUIDescriptionTag';

        TopicListBoxTag = 'ExportFromTopicUITopicListBoxTag';

        TimestampLabelTag = 'ExportFromTopicUITimestampLabelTag';

        DurationSliderTag = 'ExportFromTopicUIDurationSliderTag'; 
        
        SubGrid1Tag = 'ExportFromTopicUISubGrid1Tag';

        StartTimeLabelTag = 'ExportFromTopicUIStartTimeLabelTag';
        StartTimePanelTag = 'ExportFromTopicUIStartTimePanelTag';
        

        DurationLabelTag = 'ExportFromTopicUIDurationLabelTag';
        DurationTimePanelTag = 'ExportFromTopicUIDurationTimePanelTag';

        StorageTypeDropDownTag = 'ExportFromTopicUIStorageTypeDropDownTag';
        
        SubGrid2Tag = 'ExportFromTopicUISubGrid2Tag';
        Hid1Tag = 'ExportFromTopicUIHid1labelTag';
        Hid2Tag = 'ExportFromTopicUIHid2labelTag';
        CancelButtonTag = 'ExportFromTopicUICancelButtonTag';
        ExportButtonTag = 'ExportFromTopicUIExportButtonTag'

    end

    properties
        % Function callbacks
        ExportButtonClickedFcn = function_handle.empty;
    end

    properties(Access=private)
        MaxDuration
    end

    methods
        function obj = UIExportFromTopic(topicList, duration, rosVersion)
            obj.MaxDuration = duration;
            obj.buildUI(topicList, duration, rosVersion);
        end

        function showApp(obj)
            obj.FigureHandle.Visible = matlab.lang.OnOffSwitchState.on;
        end

        function set.ExportButtonClickedFcn(obj, val)
            % setter to ExportButtonClickedFcn
            obj.ExportButtonClickedFcn = validateCallback(val, "ExportFromTopicUIExportButtonTag");
        end

        function closeApp(obj)
            close(obj.FigureHandle);
        end

        function [timeIntervals, topics] = getBagFilter(obj)
            startTime = obj.StartTimePanelObj.Value;
            endTime = startTime + obj.DurationTimePanelObj.Value;
            topics = obj.TopicListBoxObj.Value;

            if isempty(topics)
                error(message("ros:visualizationapp:view:ExportAppTopicNoSelect"));
            end
            timeIntervals = [startTime endTime];
        end

        function storageFormat = getStorageFormat(obj)
            storageFormat = obj.StorageTypeDropDownObj.Value;
        end
    end

    methods(Access=private)
        function buildUI(obj,topicList, duration, rosVersion)
            % Main Figure
            obj.FigureHandle = uifigure("Position", obj.getWindowSize, ...
                                        "Resize", matlab.lang.OnOffSwitchState.on, ...
                                        "Name", getString(message("ros:visualizationapp:view:ExportAppTopicWindowTitle")), ...
                                        "Tag", obj.AppTag, ...
                                        "Visible", "off" , ...
                                        "WindowStyle", "modal");
            matlab.graphics.internal.themes.figureUseDesktopTheme(obj.FigureHandle);
            
            % Main Grid
            obj.MainGridLayout = uigridlayout(obj.FigureHandle, "Tag", obj.AppMainGridTag);
            obj.MainGridLayout.RowHeight = {'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit'};
            obj.MainGridLayout.ColumnWidth = {'fit'};

            obj.MainGridLayout.Scrollable = matlab.lang.OnOffSwitchState.on;

            % Title
            obj.TitleLabelObj = uilabel(obj.MainGridLayout, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicDescription")), ...
                "FontWeight", "Bold", ...
                "FontSize", 16, ...
                "Tag", obj.TitleLabelTag);
            
            % Description
            obj.DescriptionLabelObj = uilabel(obj.MainGridLayout, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicSelectLabel")), ...
                "Tag", obj.TitleLabelTag);

            % Topic list box
            obj.TopicListBoxObj = uilistbox(obj.MainGridLayout, "Tag", obj.TopicListBoxTag);
            
            if ~isempty(topicList)
                obj.TopicListBoxObj.Items = ["All Topics" topicList'];
            else
                obj.TopicListBoxObj.Items = {};
            end
            
            obj.TopicListBoxObj.Multiselect = matlab.lang.OnOffSwitchState.on;

            % Select timestamp label
            obj.TimestampLabelObj = uilabel(obj.MainGridLayout, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicTimestampLabel")), ...
                "Tag", obj.TimestampLabelTag);

            % Slider
            tStart = 0;
            tEnd = duration;

            % uislider expect tEnd > tStart. range doesn't work
            % with limits [tStart eps(tStart)]
            if (tStart == tEnd)
                tEnd = tStart + eps(tStart);
                obj.DurationSliderObj = uislider(obj.MainGridLayout, "Tag", obj.DurationSliderTag);
                obj.DurationSliderObj.Value = 0;
                obj.DurationSliderObj.MajorTickLabels = {'0', '0'};
            else
                % Need to manually set Step for RangeSlider. Check
                % g3231452. As a workaround, setting it to closest power of
                % 2. Normal value for step is (End - Start)/1000.
                
                sliderStep = 2^round(log2((duration) * 1e-3));
                obj.DurationSliderObj = uislider(obj.MainGridLayout, "range", ...
                "Tag", obj.DurationSliderTag, "Step", sliderStep);

                % Explicitly setting the Slider value for longer ranges.
                obj.DurationSliderObj.Limits = [tStart tEnd];
                obj.DurationSliderObj.Value = [tStart tEnd];
                obj.DurationSliderObj.ValueChangingFcn = @(src, event) obj.sliderCallback(event);
            end

            obj.DurationSliderObj.Limits = [tStart tEnd];
            
            obj.DurationSliderObj.MajorTicks = linspace(tStart, tEnd, 5);
            % obj.DurationSliderObj.Step = (tEnd - tStart) / 1000;
            % obj.DurationSliderObj.MinorTicks = linspace(tStart, tEnd, 20);
            
            % Sub Grid
            obj.SubGrid1Obj = uigridlayout(obj.MainGridLayout, ...
                "Tag", obj.SubGrid1Tag);
            obj.SubGrid1Obj.RowHeight = {'fit'};
            obj.SubGrid1Obj.ColumnWidth = {'1x' '1x' '1x' '1x'};
            obj.SubGrid1Obj.Padding = [0 10 0 10];

            % Start Time selection
            obj.StartTimeLabelObj = uilabel(obj.SubGrid1Obj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicStartTimeLabel")), ...
                "Tag", obj.StartTimeLabelTag);
            obj.StartTimePanelObj = uieditfield(obj.SubGrid1Obj, "numeric", ...
                "Tag", obj.StartTimePanelTag);
            obj.StartTimePanelObj.Limits = [0 duration];
           
            if duration ~= 0
                obj.StartTimePanelObj.ValueChangedFcn = @(src, event) obj.inputPanelCallback();
            end
            

            % Duration Selection
            obj.DurationLabelObj = uilabel(obj.SubGrid1Obj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicDurationLabel")), ...
                "Tag", obj.DurationLabelTag);
            obj.DurationTimePanelObj = uieditfield(obj.SubGrid1Obj, "numeric", ...
                "Tag", obj.DurationTimePanelTag);
            obj.DurationTimePanelObj.Limits = [0 duration];
            obj.DurationTimePanelObj.Value = duration;
            
            if duration ~= 0
                obj.DurationTimePanelObj.ValueChangedFcn = @(src, event) obj.inputPanelCallback();
            end

           
            % Drop Down to select output file type
            obj.StorageTypeDropDownObj = uidropdown(obj.MainGridLayout, ...
                "Tag", obj.StorageTypeDropDownTag);
            if isequal(rosVersion, "ROS")
                obj.StorageTypeDropDownObj.Items = ".bag";
            else
                obj.StorageTypeDropDownObj.Items = [".db3" ".mcap"];
            end
            
            % Sub Grid that contains button
            obj.SubGrid2Obj = uigridlayout(obj.MainGridLayout, ...
                "Tag", obj.SubGrid2Tag);
            obj.SubGrid2Obj.RowHeight = {'fit'};
            obj.SubGrid2Obj.ColumnWidth = {'1x' '1x' '1x' '1x'};
            obj.SubGrid2Obj.Padding = [0 10 0 10];

            obj.Hid1Obj = uilabel(obj.SubGrid2Obj, "Text", "", ...
                "Tag", obj.Hid1Tag);
            obj.Hid1Obj.Visible = matlab.lang.OnOffSwitchState.off;

            obj.Hid2Obj = uilabel(obj.SubGrid2Obj, "Text", "", ...
                "Tag", obj.Hid2Tag);
            obj.Hid2Obj.Visible = matlab.lang.OnOffSwitchState.off;
            

            % Cancel and Export button
            obj.CancelButtonObj = uibutton(obj.SubGrid2Obj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicCancelButtonLabel")), ...
                "Tag", obj.CancelButtonTag);
            obj.ExportButtonObj = uibutton(obj.SubGrid2Obj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppTopicExportButtonLabel")), ...
                "Tag", obj.ExportButtonTag);

            obj.CancelButtonObj.ButtonPushedFcn = @(src, event) obj.closeApp();
            obj.ExportButtonObj.ButtonPushedFcn = @(src, event) obj.ExportButtonClickedFcn(src, event);
        end
    
        function inputPanelCallback(obj)
            startTime = obj.StartTimePanelObj.Value;
            duration = obj.DurationTimePanelObj.Value;

            endTime = min(obj.MaxDuration, startTime + duration);

            obj.DurationSliderObj.Value = [startTime endTime];
            obj.DurationTimePanelObj.Value = endTime - startTime;
        end

        function sliderCallback(obj, event)
            val = event.Value;
            startTime = val(1);
            endTime = val(2);
            obj.StartTimePanelObj.Value = startTime;

            obj.DurationTimePanelObj.Limits = [0 obj.MaxDuration - startTime];
            obj.DurationTimePanelObj.Value = endTime - startTime;
            
        end
    end

    methods(Access=private, Static)

        function setSlider(sliderObj, startPanelObj, durationPanelObj)
            sliderObj.Value = [startPanelObj.Value ...
            startPanelObj.Value + durationPanelObj.Value];
        end

        function bounds = getWindowSize()
            %getWindowSize get the target window size based on screen
            %resoultion. uifigure doesn't automatically resize based on
            %content.
            screenSize = get(groot, 'ScreenSize');
            if isequal(screenSize, [1 1 1920 1080]) % 1080p (HD) display
                bounds = (ros.internal.utils.getWindowBounds).*[2.5 2 0.35 0.5];
            else
                bounds = (ros.internal.utils.getWindowBounds).*[2.5 2 0.28 0.4];
            end

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
        propertyName)
end
end

% LocalWords:  uiapphndl mcap
