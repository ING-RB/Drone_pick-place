classdef ViewerTimeline < handle
    %This class is for internal use only. It may be removed in the future.

    %ViewerTimeline Time slider and playback UI for the Rosbag Viewer app
    %   TIMELINE = ros.internal.ViewerTimeline(APPCONTAINER)
    %      Create the RosbagViewer playback control in the provided appcontainer.
    %      The UI will contain controls for play, pause, playback rate, and
    %      frame skipping forward and backward.

    %   Copyright 2022-2025 The MathWorks, Inc.

    % Callbacks
    properties % Access will be restricted to Presenter/tests, when created
        % Activate on timeline slider new position
        SliderValueChangedCallback = function_handle.empty
        SliderValueChangingCallback = function_handle.empty

        % Activate on playback control button push
        PlayCallback = function_handle.empty
        NextCallback = function_handle.empty
        PreviousCallback = function_handle.empty

        % Activate on new selection for playback rate control
        RateValueChangedCallback = function_handle.empty

        % Activate on new value entered in current time field
        TimeFieldValueChangedCallback = function_handle.empty
        TimeTypeValueChangedCallback = function_handle.empty

        % Activate on new selection for main signal
        MainSignalValueChangedCallback = function_handle.empty

        % Activate on new selection for main signal
        ShowBookmarkValueChangedFcn = function_handle.empty
    end

    % UI objects
    properties (Access = ?matlab.unittest.TestCase)
        % Figure panel containing all objects
        TimelinePanel
        % Grid containing all objects
        TimelineGrid

        % Slider for controlling current time
        TimelineSlider

        % Playback controls
        PlayButton
        NextButton
        PreviousButton
        RateDropDown
        CurrentTimeField
        TimeLabelDropDown
        MainSignalDropDown

        % By default Timestamp data is set to view
        IsViewElapseTime(1,1) logical = false
        
        % Show Bookmark On Timeline
        ShowBookmarkCheckbox

        % Holds a weak handle to app container
        AppContainerWeakHndl

        %Stores the actual limits, as the uislider limits will be modified
        Limits
    end

    % Values needed for testing
    properties (Constant, Access = ?matlab.unittest.TestCase)
        TagPanelTimeline = 'RosbagViewerTimelinePanel'
        TagTimelineGrid = 'RosbagViewerTimelineGrid'
        TagSliderTimeline = 'RosbagViewerTimelineSlider'
        TagButtonPlay = 'RosbagViewerTimelinePlayButton'
        TagButtonNext = 'RosbagViewerTimelineNextButton'
        TagButtonPrevious = 'RosbagViewerTimelinePreviousButton'
        TagDropDownRate = 'RosbagViewerTimelineRateDropDown'
        TagFieldCurrentTime = 'RosbagViewerTimelineCurrentTimeField'
        TagDropDownMainSignal = 'RosbagViewerTimelineMainSignalDropDown'
        TagTimeLabelDropDown = 'RosbagViewerTimeLabelDropDown'
        TagShowBookmarkCheckbox = 'RosbagViewerShowBookmarkCheckbox'

        RateOptionsLabels = ["0.01x";"0.02x";"0.05x";"0.1x";"0.2x";"0.5x";"0.75x"; "1x";"1.25x"; "1.5x";"1.75x"; "2x";"5x";"10x"; "20x"]
        RateOptionsValues = [ 0.01;   0.02;   0.05;   0.1;   0.2;   0.5;    0.75 ;    1;   1.25;  1.5;    1.75;   2;   5;   10;    20]
        RateOptionsDefault = 1

        ButtonSize = 36     % Pixels

        TimelineTicksNum = 10
        TimelineTicksFormat = "HH:mm:ss.SS"
    end

    methods
        function setAppMode(obj,appMode)
        %setAppMode sets the app mode(live topic data / rosbag data) and
        %makes necessary UI changes

            appContainer = obj.AppContainerWeakHndl.get;
            if appMode == ros.internal.ViewerPresenter.RosbagVisualization
                if isempty(obj.TimelinePanel) || ~isvalid(obj.TimelinePanel)
                    buildTimelinePanel(obj)
                    add(appContainer, obj.TimelinePanel)
                end
            elseif ~isempty(obj.TimelinePanel) && isvalid(obj.TimelinePanel)
                removePanel(appContainer, obj.TimelinePanel.Tag);
            end
        end

        function obj = ViewerTimeline(appContainer)
            %ViewerTimeline Construct a timeline panel on the provided app
            
            %Store a weak handle of the app container
            obj.AppContainerWeakHndl = matlab.internal.WeakHandle(appContainer);
        end

        % All callback properties validate and set the same way
        function set.SliderValueChangedCallback(obj, val)
            obj.SliderValueChangedCallback = validateCallback(val, "SliderValueChangedCallback");
        end
        function set.SliderValueChangingCallback(obj, val)
            obj.SliderValueChangingCallback = validateCallback(val, "SliderValueChangingCallback");
        end
        function set.PlayCallback(obj, val)
            obj.PlayCallback = validateCallback(val, "PlayCallback");
        end
        function set.NextCallback(obj, val)
            obj.NextCallback = validateCallback(val, "NextCallback");
        end
        function set.PreviousCallback(obj, val)
            obj.PreviousCallback = validateCallback(val, "PreviousCallback");
        end
        function set.RateValueChangedCallback(obj, val)
            obj.RateValueChangedCallback = validateCallback(val, "RateValueChangedCallback");
        end
        function set.TimeFieldValueChangedCallback(obj, val)
            obj.TimeFieldValueChangedCallback = validateCallback(val, "TimeFieldValueChangedCallback");
        end
        function set.TimeTypeValueChangedCallback(obj, val)
            obj.TimeTypeValueChangedCallback = validateCallback(val, "TimeTypeValueChangedCallback");
        end
        function set.MainSignalValueChangedCallback(obj, val)
            obj.MainSignalValueChangedCallback = validateCallback(val, "MainSignalValueChangedCallback");
        end
        function set.ShowBookmarkValueChangedFcn(obj, val)
            obj.ShowBookmarkValueChangedFcn = validateCallback(val, "ShowBookmarkValueChangedFcn");
        end
        
        function [index, name] = getSelectedSignal(obj)
            %getSelectedSignal Get index and name of selected main signal
            %   Returned INDEX of 0 indicates the default automatic signal.

            index = obj.MainSignalDropDown.Value;
            name = obj.MainSignalDropDown.Items{index+1};
        end

        function updateSignalOptions(obj, items)
            %updateSignalOptions Set contents of main signal drop down
            %    Provide all options besides the default (Automatic) in the
            %    string array ITEMS. The selected signal will be reset to
            %    default.

            validateattributes(items, {'cell', 'string'}, {}, ...
                "updateSignalOptions", "items")
            items = convertStringsToChars(items);

            autoText = getString(message('ros:visualizationapp:view:AutomaticLabel'));
            if iscell(items)
                itemsPlusDefault = vertcat(autoText, items(:));
            else
                itemsPlusDefault = {autoText; items};
            end
            obj.MainSignalDropDown.Value = 0;
            obj.MainSignalDropDown.Items = itemsPlusDefault;
            obj.MainSignalDropDown.ItemsData = (0:numel(items)).';
        end

        function [tStart, tEnd] = getTimeLimits(obj)
            %getTimeLimits Return time slider range numeric values

            tStart = obj.Limits(1);
            tEnd = obj.Limits(2);
        end

        function setTimeLimits(obj, tStart, tEnd, tCurrent)
            %setTimeLimits Set time slider range and tick labels
            %   tEnd must be greater than tStart. Current time will be reset to
            %   the start.

            validateattributes(tStart, {'numeric'}, ...
                {'scalar', 'real', 'finite'}, ...
                'setTimeLimits', 'tStart')
            validateattributes(tEnd, {'numeric'}, ...
                {'scalar', 'real', 'finite', '>=', tStart}, ...
                'setTimeLimits', 'tEnd')
            if isequal(tStart, tEnd) % to handle cases where there is single data
                                     % i.e. when tStart == tEnd.
                                     % currently uislider expects tEnd > TStart
                tEnd = tEnd + eps(tEnd);
                obj.Limits = [tStart tEnd];
            else
                obj.Limits = [tStart tEnd];
                %Workaround for g3446494
                tStart = roundToMaxDigits(tStart, 15, true);
                tEnd = roundToMaxDigits(tEnd, 15, false);

            end

            
            obj.TimelineSlider.Limits = [tStart tEnd];
            obj.TimelineSlider.Step = 1e-14; %Sensible default.
            % This Step would if and only if a topic comes at a frequency
            % of 1e14 Hz. Most modern sensors work at frequency of GHz
            % (1e9). Whereas the fastest known sensor work at THz (1e12)
            % range. So,this step value should work for conceivable future.

            ticks = linspace(tStart, tEnd, obj.TimelineTicksNum);
            obj.TimelineSlider.MajorTicks = ticks;
            if obj.IsViewElapseTime
                tickLabels = ticks - tStart;
                obj.TimelineSlider.MajorTickLabels = string(num2cell(tickLabels));
            else
                tickLabels = datetime(ticks, ...
                "ConvertFrom", "posixtime", "TimeZone","local", ...
                "Format", obj.TimelineTicksFormat);
                obj.TimelineSlider.MajorTickLabels = cellstr(tickLabels);
            end

            if nargin > 3
                setCurrentTime(obj, tCurrent)
            else
                setCurrentTime(obj, tStart)
            end
        end
        
        function ticks = getTimeTicks(obj)
            %getTimeTicks Get the ticks from time line
            
            ticks = obj.TimelineSlider.MajorTickLabels;
        end

        function t = getCurrentTime(obj)
            %getCurrentTime Get current numeric time value
            t = obj.TimelineSlider.Value;
        end

        function updateTimeSettings(obj)
            %updateTimeSettings  updates the CurrentTimeField to show the 
            % time format selected from the dropdown i.e. either elapse 
            % time or timestamp

            if strcmp(obj.TimeLabelDropDown.Value, ...
                    getString(message('ros:visualizationapp:view:TimeStampLabel')))
                obj.setIsViewElapseTime(false);
                obj.setCurrentTimeField();
            elseif strcmp(obj.TimeLabelDropDown.Value, ...
                    getString(message('ros:visualizationapp:view:ElapseTimeLabel')))
                obj.setIsViewElapseTime(true);
                obj.setCurrentTimeField();
            end

            [tStart, tEnd] = getTimeLimits(obj);
            setTimeLimits(obj, tStart, tEnd, getCurrentTime(obj))
        end

        function  setCurrentTimeField(obj)
            % setCurrentTimeField is used to set the CurrentTimeField to
            % the slider value, and based on the IsViewElapseTime

            [tStart, ~] = getTimeLimits(obj);
            t = obj.TimelineSlider.Value;
            if obj.getIsViewElapseTime
                obj.CurrentTimeField.Value = sprintf('%9.9f', t - tStart);
            else
                obj.CurrentTimeField.Value = sprintf('%9.9f', t);
            end
        end
        
        function  out = getCurrentTimeField(obj)
            % getCurrentTimeField returns currentTime in the editbox

            out = obj.CurrentTimeField.Value;
        end

        function setIsViewElapseTime(obj, val)
            % setIsViewElapseTime is used to set a temporary
            % IsViewElapseTime flag based on the TimeLabel dropdown.
            % It is false for Timestamp and True for Elapse time.

            obj.IsViewElapseTime = val;
        end

        function out = getIsViewElapseTime(obj)
            % getIsViewElapseTime is used to get the current value for
            % IsViewElapseTime flag

            out = obj.IsViewElapseTime;
        end
        
        function out = getTimeLabel(obj)
            %getTimeLabel returns current value in TimeLabelDropDown

            out = obj.TimeLabelDropDown.Value;
        end

        function setCurrentTime(obj, t)
            %setCurrentTime Set time slider position and current time box value
            %   Coerce input time to be within timeline limits.

            tStart = obj.Limits(1);
            tEnd = obj.Limits(2);
            t = min(max(t, tStart), tEnd);

            obj.TimelineSlider.Value = t;
            obj.setCurrentTimeField();
        end

        function rate = getRate(obj)
            %getRate Get numeric value of rate multiplier

            rate = obj.RateDropDown.Value;
        end

        function startPlayback(obj)
            %startPlayback Do required changes to start the playback

            matlab.ui.control.internal.specifyIconID(obj.PlayButton, 'pauseUI', 16);
            obj.PlayButton.Tooltip = getString(message('ros:visualizationapp:view:PauseTooltip'));
            matlab.ui.control.internal.specifyIconID(obj.NextButton, 'fastForwardUI', 16);
            obj.NextButton.Tooltip = getString(message('ros:visualizationapp:view:PlayForwardTooltip'));
            matlab.ui.control.internal.specifyIconID(obj.PreviousButton, 'fastBackwardUI', 16);
            obj.PreviousButton.Tooltip = getString(message('ros:visualizationapp:view:PlayBackwardTooltip'));
            obj.PlayButton.UserData = true;
        end

        function stopPlayback(obj)
            %stopPlayback Do required changes to stop the playback

            matlab.ui.control.internal.specifyIconID(obj.PlayButton, 'playUI', 16);
            obj.PreviousButton.Tooltip = getString(message('ros:visualizationapp:view:PlayTooltip'));
            matlab.ui.control.internal.specifyIconID(obj.NextButton, 'skipForwardUI', 16);
            obj.NextButton.Tooltip = getString(message('ros:visualizationapp:view:PlayStepForwardTooltip'));
            matlab.ui.control.internal.specifyIconID(obj.PreviousButton, 'skipBackwardUI', 16);
            obj.PreviousButton.Tooltip = getString(message('ros:visualizationapp:view:PlayStepBackwardTooltip'));
            obj.PlayButton.UserData = false;
        end
    end

    methods (Access = protected)
        function buildTimelinePanel(obj)
            %buildTimelinePanel Create timeline panel and contained elements

            % Add the timeline panel to the bottom
            panelOptions = struct(...
                "Title", getString(message("ros:visualizationapp:view:TimelineLabel")), ...
                "Region", "bottom");
            obj.TimelinePanel = matlab.ui.internal.FigurePanel(panelOptions);
            obj.TimelinePanel.Tag = obj.TagPanelTimeline;
            obj.TimelinePanel.PreferredHeight = 240;

            % Set up outer grid layout
            obj.TimelineGrid = uigridlayout(obj.TimelinePanel.Figure, ...
                "Padding", [15 0 15 30]);
            obj.TimelineGrid.Tag = obj.TagTimelineGrid;
            obj.TimelineGrid.RowHeight = {'fit', 'fit', 'fit'};
            obj.TimelineGrid.ColumnWidth = {'fit', ... % Timestamp Dropdown
                                            'fit', ... % Timestamp Editfield
                                             '0.5x', ... % Empty space for bigger screens
                                            'fit', ... % playbackspeed label
                                            'fit', ...    % playbackspeed dropdown
                                            35, ...    % stepbackward button
                                            35, ...    % play button
                                            35, ...    % stepforward button
                                            '0.5x', ... % Empty space for bigger screens
                                            'fit', ... % Main Signal Label
                                            'fit'};   % Main Signal Dropdown
            obj.TimelineGrid.RowSpacing = 25;
            obj.TimelineGrid.Scrollable = 'on';
          

            % Add time slider
            obj.Limits = [0 1];
            obj.TimelineSlider = uislider(obj.TimelineGrid, ...
                "Limits", [0 1], ...
                "MajorTicks", 0:0.1:1, ...
                "MinorTicks", [], ...
                "Step", 0.01); %Needs to set step manually due to uislider issues. For more info: g3231452
            obj.TimelineSlider.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.SliderValueChangedCallback, source, event);
            obj.TimelineSlider.ValueChangingFcn = ...
                @(source, event) makeCallback(obj.SliderValueChangingCallback, source, event);
            obj.TimelineSlider.Layout.Row = 2;
            obj.TimelineSlider.Layout.Column = [1, 11];
            obj.TimelineSlider.Tag = obj.TagSliderTimeline;

            % Set up rate control
            % Add Current Time
            ItemsData = {getString(message('ros:visualizationapp:view:ElapseTimeLabel')), ...
                getString(message('ros:visualizationapp:view:TimeStampLabel'))};
            obj.TimeLabelDropDown = uidropdown(obj.TimelineGrid, ...
                "Tag", obj.TagTimeLabelDropDown, ...
                "Items", ItemsData, ...
                "Value", getString(message(...
                'ros:visualizationapp:view:ElapseTimeLabel')));
            obj.TimeLabelDropDown.ValueChangedFcn = @(source, event) ...
                makeCallback(obj.TimeTypeValueChangedCallback, source, event);
            obj.TimeLabelDropDown.Layout.Row = 3;
            obj.TimeLabelDropDown.Layout.Column = 1;

            % Add Current Time Edit
            obj.CurrentTimeField = uieditfield(obj.TimelineGrid, ...
                'Tag', obj.TagFieldCurrentTime, 'Value', sprintf('%9.9f', 0));
            obj.CurrentTimeField.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.TimeFieldValueChangedCallback, source, event);
            obj.CurrentTimeField.Layout.Row = 3;
            obj.CurrentTimeField.Layout.Column = 2;


            % Add Playback Speed Label
            rateLabel = uilabel(obj.TimelineGrid, ...
                "Text", getString(message('ros:visualizationapp:view:RateLabel')), ...
                "HorizontalAlignment", "right");
            rateLabel.Layout.Row = 3;
            rateLabel.Layout.Column = 4;

            % Add Rate
            obj.RateDropDown = uidropdown(obj.TimelineGrid, ...
                "Items", obj.RateOptionsLabels, ...
                "ItemsData", obj.RateOptionsValues, ...
                "Value", obj.RateOptionsDefault, ...
                "Tag", obj.TagDropDownRate);
            obj.RateDropDown.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.RateValueChangedCallback, source, event);
            obj.RateDropDown.Layout.Row = 3;
            obj.RateDropDown.Layout.Column = 5;

            % Set up buttons
            obj.PreviousButton = uibutton(obj.TimelineGrid, ...
                "Text", "", ...
                "Tag", obj.TagButtonPrevious,...
                "Tooltip", getString(message('ros:visualizationapp:view:PlayStepBackwardTooltip')));
            matlab.ui.control.internal.specifyIconID(obj.PreviousButton, 'skipBackwardUI', 16);
            obj.PreviousButton.ButtonPushedFcn = ...
                @(source, event) makeCallback(obj.PreviousCallback, source, event);
            obj.PreviousButton.Layout.Row = 3;
            obj.PreviousButton.Layout.Column = 6;
            obj.PreviousButton.UserData = true;

            obj.PlayButton = uibutton(obj.TimelineGrid, ...
                "Text", "", ...
                "Tag", obj.TagButtonPlay, ...
                 "Tooltip", getString(message('ros:visualizationapp:view:PlayTooltip')));
            matlab.ui.control.internal.specifyIconID(obj.PlayButton, 'playUI', 16);
            obj.PlayButton.ButtonPushedFcn = ...
                @(source, event) makeCallback(obj.PlayCallback, source, event);
            obj.PlayButton.Layout.Row = 3;
            obj.PlayButton.Layout.Column = 7;

            obj.NextButton = uibutton(obj.TimelineGrid, ...
                "Text", "", ...
                "Tag", obj.TagButtonNext, ...
                "Tooltip", getString(message('ros:visualizationapp:view:PlayStepForwardTooltip')));
            matlab.ui.control.internal.specifyIconID(obj.NextButton, 'skipForwardUI', 16);

            obj.NextButton.ButtonPushedFcn = ...
                @(source, event) makeCallback(obj.NextCallback, source, event);
            obj.NextButton.Layout.Row = 3;
            obj.NextButton.Layout.Column = 8;
            obj.NextButton.UserData = true;

            % Set up Reference Topic
            signalLabel = uilabel(obj.TimelineGrid, ...
                "Text", getString(message('ros:visualizationapp:view:ReferenceTopicLabel')), ...
                "HorizontalAlignment", "right");
            signalLabel.Tooltip = getString(message('ros:visualizationapp:view:ReferenceTopicTooltip'));

            signalLabel.Layout.Row = 3;
            signalLabel.Layout.Column = 10;

            % Add Automatic signal
            autoText = string(getString(message('ros:visualizationapp:view:AutomaticLabel')));
            obj.MainSignalDropDown = uidropdown(obj.TimelineGrid, ...
                "Items", autoText, ...
                "ItemsData", 0, ...
                "Value", 0, ...
                "Tag", obj.TagDropDownMainSignal);
            obj.MainSignalDropDown.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.MainSignalValueChangedCallback, source, event);
            obj.MainSignalDropDown.Layout.Row = 3;
            obj.MainSignalDropDown.Layout.Column = 11;
            
            checkboxstring = string(getString(message('ros:visualizationapp:view:ShowBookmarkOnTimeLine')));
            obj.ShowBookmarkCheckbox = uicheckbox(obj.TimelineGrid, ...
                                                "Text", checkboxstring, ...
                                                "Value", false, "Visible", "off");
            obj.ShowBookmarkCheckbox.Tag = obj.TagShowBookmarkCheckbox;
            obj.ShowBookmarkCheckbox.ValueChangedFcn = ...
                @(source, event) makeCallback(obj.ShowBookmarkValueChangedFcn, source, event);
            obj.ShowBookmarkCheckbox.Layout.Row = 4;
            obj.ShowBookmarkCheckbox.Layout.Column = 1;
        end
    end
end

% Helper functions that have no need for class access

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

function roundedNumber = roundToMaxDigits(number, maxDigits, roundDown)
    % roundToMaxDigits rounds a given decimal number such that the total
    % number of digits (integer and decimal combined) does not exceed
    % 'maxDigits'. The rounding direction is determined by the 'roundDown' flag.
    if number == 0
        roundedNumber = 0;
        return;
    end

    signNumber = sign(number);
    number = abs(number);
    
    integerPart = floor(number);
    integerDigits = floor(log10(integerPart)) + 1;
    
    decimalPlacesAllowed = maxDigits - integerDigits;
    
    if decimalPlacesAllowed <= 0
        if roundDown
            roundedNumber = signNumber * floor(number / 10^(integerDigits - maxDigits));
        else
            roundedNumber = signNumber * ceil(number / 10^(integerDigits - maxDigits));
        end
    else
        factor = 10^decimalPlacesAllowed;
        if roundDown
            roundedNumber = signNumber * floor(number * factor) / factor;
        else
            roundedNumber = signNumber * ceil(number * factor) / factor;
        end
    end
end

% LocalWords:  APPCONTAINER appcontainer HH uislider TStart posixtime dropdown editbox Editfield
% LocalWords:  playbackspeed stepbackward stepforward
