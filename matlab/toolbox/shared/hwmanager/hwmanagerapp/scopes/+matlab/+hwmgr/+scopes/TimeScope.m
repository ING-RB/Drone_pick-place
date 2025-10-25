classdef TimeScope < handle
%TimeScope   Hardware Manager time series scope
%   TimeScope is a time-based strip chart that supports streaming and
%   displaying data in Hardware Manager.
%
%   scope = matlab.hwmgr.scopes.TimeScope(parent) creates a Hardware
%   Manager time series scope in the specified parent uipanel and returns
%   the TimeScope object.
%
%   scope = matlab.hwmgr.scopes.TimeScope(parent, <Name>, <Value>) creates
%   a Hardware Manager time series scope in the specified parent uipanel
%   and returns the TimeScope object. It also specifies TimeScope property
%   values using one or more optional name-value argument pairs.
%
%   TimeScope properties:
%       BufferSize - Size of data storage buffer
%       ColorTheme - Color theme of scope
%       Grid - Display grid lines
%       LegendVisible - Display legend
%       MultipleYAxis - Single or multiple Y-axis
%       State - Current state of the scope
%       Signals - Array of signals
%       TimeSpan - Time width of visible window
%       Title - Display title
%       XLabel - X-axis label
%       XLimits - X-axis limits
%       YLabel - Y-axis label
%       YLimits - Y-axis limits
%       YLimitsMode - Selection mode for Y-axis limits
%       PlayButtonEnabled - Enable or disable play/pause button
%
%   TimeScope methods:
%       addData - Add new data to time scope
%       clearData - Clear all signal data
%       createSignal - Create new signal on time scope
%       pause - Pause streaming to time scope
%       removeSignal - Remove signal from time scope
%       reset - Reset time scope
%       resume - Resume streaming to time scope
%       startAutoScroll - Start scrolling X ruler automatically   

%   Copyright 2020-2023 The MathWorks, Inc.
       
    properties (Access = {?matlab.unittest.TestCase})
        %TimeScopeImplementation
        %   The underlying implementation for scope rendering and streaming
        TimeScopeImplementation
        
        %MessageHandler
        %   Handler of all connector messages with front end.
        MessageHandler
        
        %Parent
        %   Handle to the optional uipanel hosting the scope
        Parent matlab.ui.container.Panel
        
        %GridLayout
        %   Handle to uigridlayout inside Parent to manage auto resizing
        GridLayout matlab.ui.container.GridLayout
        
        %UiHtml
        %   Handle to the uihtml widget in which the scope URL is loaded
        UiHtml matlab.ui.control.HTML
        
        %SignalCreatedListener
        %   Event listener for SignalCreated event from MessageHandler
        SignalCreatedListener
        
        %BufferStruct
        %   A struct to buffer data when scope is paused
        BufferStruct (1, 1) struct
        
        %FlushBufferListener
        %   Event listener for FlushBuffer event from MessageHandler
        FlushBufferListener
                
        %StateChangeListener
        %   State property change event from MessageHandler 
        StateChangeListener
        
        %LastDataTimestamp
        %   Last data timestamp in data-driven mode
        LastDataTimestamp = 0
    end
    
    properties (Hidden, Dependent)
        %DebugLevel Defined by webscope system object
        %   This should be set before calling show to specify debug level.
        %   1 - debug/chrome
        %   2 - release/chrome
        %   3 - release/CEF (default)
        %   4 - debug/CEF
        DebugLevel
    end
    
    properties (Hidden, SetAccess = private, Dependent)
        %ScrollStarted
        %   Flag to check if auto scroll has been started
        ScrollStarted
    end
    
    properties (Hidden)
        %SignalCreated
        %   Flag to track if front-end has created the last signal
        SignalCreated = false        
    end
    
    properties (Dependent) 
        %Title - Display title
        %   Display title, specified as a string. The default value is ''.
        Title (1, 1) string
        
        %XLabel - X-axis label
        %   X-axis label, specified as a string. The default value is ''.
        XLabel (1, 1) string
        
        %YLabel - Y-axis label
        %   Y-axis label, specified as a string. The default value is ''.
        YLabel (1, 1) string
        
        %XLimits - X-axis limits
        %   X-axis limits, specified as a two-element numeric vector, [xmin
        %   xmax]. The default is [0 10].
        XLimits (1, 2) {matlab.hwmgr.internal.util.mustBeA(XLimits, 'double'), ...
        matlab.hwmgr.internal.util.mustBeIncreasing(XLimits)}
        
        %YLimits - Y-axis limits
        %   Y-axis limits, specified as a two-element numeric vector, [ymin
        %   ymax]. The default is [0 10].
        YLimits (1, 2) {matlab.hwmgr.internal.util.mustBeA(YLimits, 'double'), ...
            matlab.hwmgr.internal.util.mustBeIncreasing(YLimits)}
        
        %TimeSpan - Time width of visible window
        %   Time width of visible window, specified as an integer number of
        %   seconds.
        TimeSpan (1, 1) {matlab.hwmgr.internal.util.mustBeA(TimeSpan, 'double'), ...
            mustBeInteger, mustBePositive}
        
        %YLimitsMode - Selection mode for Y-axis limits
        %   Y-axis limits mode, specified as a string. When set to "auto",
        %   Y-axis limits automatically adjust to include the full range of
        %   data. When set to "manual", Y-axis limits observe the values
        %   provided in the YLimits property. The default is "auto".
        YLimitsMode (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YLimitsMode, ["manual", "auto"])}
        
        %Grid - Display grid lines
        %   Specify grid display as "on" or "off". The default is "on".
        Grid (1, 1) matlab.lang.OnOffSwitchState
        
        %MultipleYAxis - Single or multiple Y-axis
        % Specify display of multiple Y-axes stacked on the left side of
        % the scope, as "on" or "off". The default is "off".
        MultipleYAxis (1, 1) matlab.lang.OnOffSwitchState
        
        %LegendVisible - Display legend
        %   Specify legend display as "on" or "off". The default is "on".
        LegendVisible (1, 1) matlab.lang.OnOffSwitchState
        
        %ColorTheme - Color theme of scope
        %   Color theme of scope, specified as "light" or "dark". The
        %   default is "light".
        ColorTheme (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(ColorTheme, ["light", "dark", "auto"])}
    
        %PlayButtonEnabled - Enable or disable play/pause button
        %   Specify if play/pause button is enabled. The default is "on".
        PlayButtonEnabled (1, 1) matlab.lang.OnOffSwitchState
    end
    
    properties (Dependent, GetAccess = public, SetAccess = private)
        %State - Current state of the scope
        %   Current state of scope, indicated as "stopped", "paused" or
        %   "running".
        State (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(State, ["stopped", "running", "paused"])}
        
        %BufferSize - Size of data storage buffer
        %   Size of data storage buffer, indicating the maximum number of
        %   data points stored for each signal.
        BufferSize (1, 1) {matlab.hwmgr.internal.util.mustBeA(BufferSize, 'double'), ...
            mustBeInteger, mustBePositive, mustBeFinite}
    end
    
    properties (GetAccess = public, SetAccess = private)
        %Signals - Array of signals
        %   Array of all signals created on the current scope.
        Signals (1, :) matlab.hwmgr.scopes.internal.Signal = matlab.hwmgr.scopes.internal.Signal.empty()
    end
    
    properties (Access = private, Constant)
        %URL url of the web app
        Url = 'toolbox/shared/hwmanager/hwmanagerapp/scopes/timescope/timescope'
    end
    
    events
        %StateChanged
        %   Time scope state change event
        StateChanged        
    end
    
    methods
        function obj = TimeScope(varargin)
            obj.TimeScopeImplementation = matlab.hwmgr.scopes.TimeScopeImplementation(obj.Url);
            obj.MessageHandler = obj.TimeScopeImplementation.MessageHandler;
            
            obj.SignalCreatedListener = obj.registerListenerOnMessageHandler("SignalCreated", @obj.handleSignalCreated);
            obj.FlushBufferListener = obj.registerListenerOnMessageHandler("FlushBuffer", @obj.handleFlushBuffer);
            msgHandlerStateProperty = findprop(obj.MessageHandler, "State");
            obj.StateChangeListener = event.proplistener(obj.MessageHandler, msgHandlerStateProperty, "PostSet", @(src, evt)notify(obj, "StateChanged"));
            
            if isempty(varargin)
                return;
            end
            
            p = inputParser;
            hasParent = ~isStringScalar(varargin{1}) && ...
                ~(ischar(varargin{1}) && isrow(varargin{1}));
            
            % Check if the first input is a uipanel
            if hasParent
                % First input should be parent
                addRequired(p, "Parent", @(x) obj.validateParent(x));
            end
            addParameter(p, "Title", "");
            addParameter(p, "XLabel", "");
            addParameter(p, "YLabel", "");
            addParameter(p, "XLimits", [0, 10]);
            addParameter(p, "YLimits", [0, 10]);
            addParameter(p, "TimeSpan", 10);
            addParameter(p, "YLimitsMode", "auto");
            addParameter(p, "Grid", "on");
            addParameter(p, "MultipleYAxis", "off");
            addParameter(p, "LegendVisible", "on");
            addParameter(p, "ColorTheme", "auto");
            addParameter(p, "BufferSize", 50000);
            addParameter(p, "PlayButtonEnabled", "on");
            
            parse(p, varargin{:});           
                        
            obj.Title = p.Results.Title;
            obj.XLabel = p.Results.XLabel;
            obj.YLabel = p.Results.YLabel;
            obj.XLimits = p.Results.XLimits;
            obj.YLimits = p.Results.YLimits;
            obj.TimeSpan = p.Results.TimeSpan;
            obj.YLimitsMode = p.Results.YLimitsMode;
            obj.Grid = p.Results.Grid;
            obj.MultipleYAxis = p.Results.MultipleYAxis;
            obj.LegendVisible = p.Results.LegendVisible;
            obj.ColorTheme = p.Results.ColorTheme;
            obj.BufferSize = p.Results.BufferSize;
            obj.PlayButtonEnabled = p.Results.PlayButtonEnabled;
            
            if hasParent
                obj.Parent = p.Results.Parent;
                obj.GridLayout = uigridlayout(obj.Parent, [1, 1], 'Padding', [0, 0, 0, 0]);
                obj.UiHtml = uihtml(obj.GridLayout, 'HTMLSource', obj.TimeScopeImplementation.getFullUrl());
                
                % When the scope is embedded in uipanel, it is shown
                % automatically without calling "show", so we need to wait
                % for the open to complete.
                obj.TimeScopeImplementation.waitForOpen();
                obj.MessageHandler.onStart();
            end
        end
        
        function pause(obj)
            %pause    Pause streaming to time scope
            %   pause(scope) pauses streaming on the scope. Data written to
            %   the scope when it is paused will be cached, and flushed on
            %   resume.
            obj.State = "paused";
        end
        
        function resume(obj)
            %resume    Resume streaming to time scope
            %   resume(scope) resumes streaming on the scope. Data written
            %   to the scope when it is paused will be flushed on resume.
            obj.flushBuffer();
            obj.State = "running";
        end
        
        function reset(obj)
            %reset    Reset time scope
            %   reset(scope) resets the time scope to the newly constructed
            %   state. All signals are removed.
            
            % Set state to stopped will automatically notify frond-end
            obj.State = "stopped";
            
            % Turn on ResetStarted flag so temporarily disable write
            obj.MessageHandler.ResetStarted = true;
            
            % Remove all signals
            signals = obj.Signals;
            for i = 1:length(signals)
                obj.removeSignal(signals(i));
            end
            
            % Reset auto scroll flag
            obj.ScrollStarted = false;
            
            % Reset last data timestamp
            obj.LastDataTimestamp = 0;
            
            % Clean up MATLAB buffer
            obj.BufferStruct = struct;
            
            % Set all properties to default except on-demand properties
            obj.Title = obj.MessageHandler.CachedDefaultProperties.title;
            obj.XLabel = obj.MessageHandler.CachedDefaultProperties.xLabel;
            obj.YLabel = obj.MessageHandler.CachedDefaultProperties.yLabel;
            obj.TimeSpan = obj.MessageHandler.CachedDefaultProperties.timeSpan;
            obj.Grid = obj.MessageHandler.CachedDefaultProperties.grid;
            obj.MultipleYAxis = obj.MessageHandler.CachedDefaultProperties.multipleYAxis;
            obj.LegendVisible = obj.MessageHandler.CachedDefaultProperties.legendVisible;          
            obj.ColorTheme = obj.MessageHandler.CachedDefaultProperties.colorTheme;
            obj.PlayButtonEnabled = obj.MessageHandler.CachedDefaultProperties.playButtonEnabled;
            
            % Flip ResetStarted back to false
            obj.MessageHandler.ResetStarted = false;
        end
        
        function clearData(obj)
            %clearData    Clear all signal data
            %   clearData(scope) clears all the data of all signals while
            %   keeping all the signals.
            
            % Clear last data timestamp since all data are cleared
            obj.LastDataTimestamp = 0;
            
            % Remove all data cursors and set DataCursor to "none" as no
            % lines are displayed
            for i = 1:length(obj.Signals)
                obj.Signals(i).DataCursor = "none";
            end
            
            % Tell front-end to clear data while keeping signals
            obj.MessageHandler.clearDataOnFrontEnd();
            
            % Clear data on the back-end.
            obj.TimeScopeImplementation.clearDataOnBackend();
        end
        
        function startAutoScroll(obj, timeAtStart)
            %startAutoScroll    Start scrolling X ruler automatically
            %   startAutoScroll(scope, timeAtStart) starts scrolling the X
            %   ruler automatically in real time. The max value of XLimits
            %   will be set to timeAtStart.
            
            arguments
                obj (1, 1) matlab.hwmgr.scopes.TimeScope
                timeAtStart (1, 1) double {mustBeNonnegative}
            end
            obj.State = "running";
            obj.ScrollStarted = true;
            obj.MessageHandler.startAutoScrollOnFrontEnd(timeAtStart);
        end
        
        function signal = createSignal(obj, tag, time, value)
            %createSignal    Create new signal on time scope
            %   signal = createSignal(scope, tag) creates a new signal on
            %   the time scope and sets its Tag property to the specified
            %   string.

            arguments
                obj (1, 1) matlab.hwmgr.scopes.TimeScope
                tag (1, 1) string
                time {matlab.hwmgr.internal.util.mustBeDoubleVector, ...
                    matlab.hwmgr.internal.util.mustBeIncreasing, mustBeNonnegative} = 0
                value {matlab.hwmgr.internal.util.mustBeDoubleVector} = 0
            end

            % Throw a warning if this is called before the window is open
            % and connector is ready
            if ~obj.MessageHandler.OpenComplete
                msgID = 'hwmanagerapp:scopes:WindowNotOpen';
                error(message(msgID));
            end
            
            % Create signal first to validate tag. If we error out at
            % signal construction, no uuid will be requested from back-end
            signal = matlab.hwmgr.scopes.internal.Signal(obj, tag);
            
            uuid = obj.TimeScopeImplementation.addSignal(1);
            signal.ID = uuid{1};
            obj.Signals(end + 1) = signal;
            
            % Ask front-end to create signal
            obj.MessageHandler.createSignalOnFrontEnd(signal.ID, tag);

            % Wait for signal creation to complete
            waitfor(obj, 'SignalCreated', true);
            signal.AddComplete = true;
            obj.SignalCreated = false;

            % Early return if time and value are not provided as inputs
            if nargin == 2
                return;
            end

            % Flush optional signal data
            if ~iscolumn(time)
                time = time';
            end
            if ~iscolumn(value)
                value = value';
            end
            if length(time) ~= length(value)
                msgID = 'hwmanagerapp:scopes:InvalidAddDataSizeOnSignal';
                error(message(msgID));
            end
            obj.TimeScopeImplementation.write(uuid, [time, value]);
        end

        function removeSignal(obj, signal)
            %removeSignal    Remove signal from time scope
            %   removeSignal(scope, signal) removes the specified signal
            %   from the time scope.
            
            arguments
                obj (1, 1) matlab.hwmgr.scopes.TimeScope
                signal (1, 1) matlab.hwmgr.scopes.internal.Signal
            end
            if ~any(obj.Signals == signal)
                msgID = 'hwmanagerapp:scopes:InvalidSignalRemoval';
                error(message(msgID));
            end
            
            obj.Signals(obj.Signals == signal) = [];
            
            % Ask front-end to remove signal
            obj.MessageHandler.removeSignalOnFrontEnd(signal.ID);
            
            % Ask back-end to remove signal
            obj.TimeScopeImplementation.removeSignal({signal.ID});
            
            % Delete signal. We don't want orphan signals
            delete(signal);
        end
        
        function addData(obj, signal, time, value)
            %addData - Add new data to time scope
            %   addData(scope, signal, time, value) streams and displays
            %   new data to the specified signal on the time scope. signal
            %   is a signal object. time is a vector for timestamps of the
            %   data, and value is a vector for values of the data. Both
            %   time and value are vectors of double. The signal, time, and
            %   value arguments can be repeated as a group for multiple
            %   signals.
            %
            %   Examples: 
            %   Write data to a signal on a scope. 
            %   time = 1:5; 
            %   value = rand(1,5); 
            %   addData(scope, sig, time, value);
            %
            %   Write data to two signals.
            %   time1 = 1:5;
            %   value1 = rand(1, 5);
            %   time2 = 2:7;
            %   value2 = rand(1, 6);
            %   addData(scope, sig1, time1, value1, sig2, time2, value2);          
            
            arguments
                obj (1, 1) matlab.hwmgr.scopes.TimeScope
            end
            arguments (Repeating)
                signal (1, 1) matlab.hwmgr.scopes.internal.Signal
                time {matlab.hwmgr.internal.util.mustBeDoubleVector, ...
                    matlab.hwmgr.internal.util.mustBeIncreasing, mustBeNonnegative}
                value {matlab.hwmgr.internal.util.mustBeDoubleVector}
            end
            
            % Combine time and value to cells of Nx2 arrays
            data = cell(1, length(time));
            for i = 1:length(time)
                if ~iscolumn(time{i})
                    time{i} = time{i}';
                end
                if ~iscolumn(value{i})
                    value{i} = value{i}';
                end
                if length(time{i}) ~= length(value{i})
                    msgID = 'hwmanagerapp:scopes:InvalidAddDataSizeOnScope';
                    error(message(msgID, num2str(i)));
                end
                data{i} = [time{i}, value{i}];
            end
            obj.write(signal, data{:});
        end
        
        function delete(obj)
            delete(obj.SignalCreatedListener);
            delete(obj.FlushBufferListener);
            delete(obj.GridLayout);
        end
    end
    
    methods (Hidden)
        function show(obj)
            % Show scope if it is not embedded in a uipanel
            if isempty(obj.Parent)
                obj.TimeScopeImplementation.show();
            end
        end
        
        function write(obj, signals, varargin)
            % write is the interanl method that scope and signal addData
            % internally invoke.
            
            % User started reset process, do not write any data until the
            % flag is set back to false
            if obj.MessageHandler.ResetStarted
                return;
            end
            
            if ~iscell(signals)
                signals = {signals};
            end
            
            % uuids are in cells
            uuids = cellfun(@(x) x.ID, signals, 'UniformOutput', false);
                        
            if isequal(obj.State, "stopped")
                % When stopped, change to running
                obj.State = "running";
            end
            
            % In data driven mode, keep track of last data timestamp when
            % the scope is running
            if ~obj.ScrollStarted && obj.State == "running"
                for i = 1:length(varargin)
                    obj.LastDataTimestamp = max(obj.LastDataTimestamp, varargin{i}(end, 1));
                end                
            end
                        
            if isequal(obj.State, "paused")
                obj.saveDataToBuffer(uuids, varargin{:});

                % Early return since all data have been sent to
                % back-end or bufferer.
                return;
            end
            obj.TimeScopeImplementation.write(uuids, varargin{:});
        end
        
        % Handle signal on-demand property get from MATLAB
        function handleSignalOnDemandPropertyRequest(obj, property, identifier)
            obj.MessageHandler.requestOnDemandPropertyOnFrontEnd(property, identifier);
        end
        
        % Handle signal regular writable property set from MATLAB
        function handleSignalPropertiesChange(obj, signal, propertyName, value)
            if strcmp(propertyName, "YLimits")
                obj.YLimitsMode = "manual";
            end
            obj.MessageHandler.handleSignalPropertiesChange(signal, ...
                propertyName, value);
        end
        
        % Utility function to register listener on MessageHandler events
        function listener = registerListenerOnMessageHandler(obj, eventName, callbackFcn)
            listener =  event.listener(obj.MessageHandler, eventName, callbackFcn);
        end
        
        % Internal method to get the timestamp when pause is invoked
        function timeAtPause = getTimeAtPause(obj)
            if obj.ScrollStarted
                % In time-driven mode, it is from the front-end internal
                % timer
                timeAtPause = obj.MessageHandler.TimeAtPause;
            else
                % In data-driven mode, it is from last data timestamp
                timeAtPause = obj.LastDataTimestamp;
            end
        end        
    end
    
    % getters and setters
    methods
        % State set
        function set.State(obj, value)
            obj.MessageHandler.State = value;
        end
        
        % DebugLevel set/get
        function set.DebugLevel(obj, value)
            obj.TimeScopeImplementation.setDebugLevel(value);
        end
        function value = get.DebugLevel(obj)
            value = obj.TimeScopeImplementation.getDebugLevel();
        end
        
        % ScrollStarted set/get
        function set.ScrollStarted(obj, value)
            obj.MessageHandler.ScrollStarted = value;
        end
        function value = get.ScrollStarted(obj)
           value =  obj.MessageHandler.ScrollStarted;
        end
        
        % Title set/get
        function set.Title(obj, value)
            obj.MessageHandler.Title = value;
        end
        function value = get.Title(obj)
            value = obj.MessageHandler.Title;
        end
        
        % XLabel set/get
        function set.XLabel(obj, value)
            obj.MessageHandler.XLabel = value;
        end
        function value = get.XLabel(obj)
            value = obj.MessageHandler.XLabel;
        end
        
        % YLabel set/get
        function set.YLabel(obj, value)
            obj.MessageHandler.YLabel = value;
        end
        function value = get.YLabel(obj)
            value = obj.MessageHandler.YLabel;
        end
        
        % XLimits set/get
        function set.XLimits(obj, value)
            if strcmp(obj.State, "running")
                msgID = 'hwmanagerapp:scopes:XLimitsSetOnRunning';
                warning(message(msgID));
                return;
            end
            obj.MessageHandler.XLimits = value;
        end
        function value = get.XLimits(obj)
            if obj.MessageHandler.OpenComplete
                obj.MessageHandler.requestOnDemandPropertyOnFrontEnd("XLimits");
            end
            value = obj.MessageHandler.XLimits;
        end
        
        % YLimits set/get
        function set.YLimits(obj, value)
            obj.MessageHandler.YLimits = value;
            obj.YLimitsMode = "manual";
        end
        function value = get.YLimits(obj)
            if obj.MessageHandler.OpenComplete && obj.MultipleYAxis == "off"
                obj.MessageHandler.requestOnDemandPropertyOnFrontEnd("YLimits");
            end
            value = obj.MessageHandler.YLimits;
        end
        
        % TimeSpan set/get
        function set.TimeSpan(obj, value)
            obj.MessageHandler.TimeSpan = value;
        end
        function value = get.TimeSpan(obj)
            value = obj.MessageHandler.TimeSpan;
        end
        
        % YLimitsMode set/get
        function set.YLimitsMode(obj, value)
            obj.MessageHandler.YLimitsMode = lower(value);
        end
        function value = get.YLimitsMode(obj)
            if obj.MessageHandler.OpenComplete
                obj.MessageHandler.requestOnDemandPropertyOnFrontEnd("YLimitsMode");
            end
            value = obj.MessageHandler.YLimitsMode;
        end
        
        % Grid set/get
        function set.Grid(obj, value)
            obj.MessageHandler.Grid = lower(value);
        end
        function value = get.Grid(obj)
            value = obj.MessageHandler.Grid;
        end
        
        % MultipleYAxis set/get
        function set.MultipleYAxis(obj, value)
            if isequal(obj.MessageHandler.MultipleYAxis, value)
                % No change to current value
                return;
            end
            
            obj.MessageHandler.MultipleYAxis = lower(value);
            
            % With change of multiY mode, also change YLimitsMode to "auto"
            obj.YLimitsMode = "auto";
            
            signals = obj.Signals;
            flag = value == "on";
            
            % Update multiY mode on all child signals
            for i = 1:length(signals)
                signals(i).MultipleYAxis = flag;
                if flag
                    % Sent previously set signal YLabel
                    signals(i).sendNewPropertyToParent('YLabel', signals(i).YLabel);
                end
            end           
            
        end
        function value = get.MultipleYAxis(obj)
            value = obj.MessageHandler.MultipleYAxis;
        end
        
        % LegendVisible set/get
        function set.LegendVisible(obj, value)
            obj.MessageHandler.LegendVisible = lower(value);
        end
        function value = get.LegendVisible(obj)
            value = obj.MessageHandler.LegendVisible;
        end
        
        % ColorTheme set/get
        function set.ColorTheme(obj, value)
            obj.MessageHandler.ColorTheme = lower(value);
        end
        function value = get.ColorTheme(obj)
            value = obj.MessageHandler.ColorTheme;
        end
        
        % BufferSize
        function set.BufferSize(obj, value)
            obj.MessageHandler.BufferSize = value;
        end
        function value = get.BufferSize(obj)
            value = obj.MessageHandler.BufferSize;
        end
        
        % PlayButtonEnabled set/get
        function set.PlayButtonEnabled(obj, value)
            obj.MessageHandler.PlayButtonEnabled = lower(value);
        end
        function value = get.PlayButtonEnabled(obj)
            value = obj.MessageHandler.PlayButtonEnabled;
        end
        
        % State getter
        function value = get.State(obj)
            value = obj.MessageHandler.State;
        end
        
    end
    
    methods (Access = private)
        function release(obj)
            obj.TimeScopeImplementation.release();
        end
        
        function handleSignalCreated(obj, ~, ~)
            % Handle SignalCreated event from message handler
            obj.SignalCreated = true;
        end
        
        function handleFlushBuffer(obj, ~, ~)
            % Handle FlushBuffer event from message handler
            obj.flushBuffer();
        end
        
        function validateParent(~, parent)
            validateattributes(parent, {'matlab.ui.container.Panel'}, ...
                {'scalar'}, 'TimeScope', 'Parent', 1);
            if ~isempty(parent.Children)
                msgID = 'hwmanagerapp:scopes:NonEmptyPanel';
                error(message(msgID));
            end
        end
        
        function saveDataToBuffer(obj, uuids, varargin)
            % Save data to buffer when data are written when paused
            
            % uuids are in a row of cells
            for i = 1:length(uuids)
                newData = varargin{i};
                % Concatenate "s" in front of uuid to avoid having a number
                % at the beginning of the field name
                fieldName = strcat("s", uuids{i});
                if isfield(obj.BufferStruct, fieldName)
                    obj.BufferStruct.(fieldName) = [obj.BufferStruct.(fieldName); newData];
                else
                    obj.BufferStruct.(fieldName) = newData;
                end
                % Make sure BufferStruct data do not exist BufferSize
                if size(obj.BufferStruct.(fieldName), 1) > obj.BufferSize
                    obj.BufferStruct.(fieldName) = ...
                        obj.BufferStruct.(fieldName)(end - obj.BufferSize + 1 : end, :);
                end
            end
        end
        
        function flushBuffer(obj)
            % Write buffered data after scope changes from pause to running
            
            if ~isempty(fieldnames(obj.BufferStruct))
                fieldNames = fieldnames(obj.BufferStruct)';
                data = cellfun(@(x) obj.BufferStruct.(x), fieldNames, 'UniformOutput', false);
                uuids = cellfun(@(x) x(2:end), fieldNames, 'UniformOutput', false);
                
                % Directly write to the streaming engine
                obj.TimeScopeImplementation.write(uuids, data{:});
                
                % Clean up MATLAB buffer
                obj.BufferStruct = struct;
            end
        end  
    end
end
