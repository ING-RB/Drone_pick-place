classdef (Hidden) TimeScopeMessageHandler < matlabshared.scopes.WebScopeMessageHandler
    %TIMESCOPEMESSAGEHANDLER The message handler of the TimeScope. It
    %manages messages between MATLAB interface and the frontend JS scope.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Transient, SetObservable)
        %Title Display title
        %   Specify the display title as a string. The default value is ''.
        Title (1, 1) string = "";
        
        %XLabel X-axis label
        %   Specify the x-axis label as a string. The default value is ''.
        XLabel (1, 1) string = "";
        
        %YLabel Y-axis label
        %   Specify the y-axis label as a string. The default value is ''.
        YLabel (1, 1) string = "";
        
        %XLimits X-axis limits
        %   Specify the x-axis limits as a two-element numeric vector:
        %   [xmin xmax]. The default is [0 10].
        XLimits (1, 2) double {matlab.hwmgr.internal.util.mustBeIncreasing(XLimits)} = [0, 10];
        
        %YLimits Y-axis limits
        %   Specify the y-axis limits as a two-element numeric vector:
        %   [ymin ymax]. The default is [0 10].
        YLimits (1, 2) double {matlab.hwmgr.internal.util.mustBeIncreasing(YLimits)} = [0, 10];
        
        %TimeSpan Time window width
        %   Specify the range of the XLimits
        TimeSpan (1, 1) double {mustBeInteger, mustBePositive} = 10;
        
        %YLimitsMode auto or manual y limits
        %   Specify whether the y limits automatically change with input
        %   data. When set to "auto", y limits automatically adjust to
        %   include the full range of data. When set to "manual", it
        %   remains the value provided to YLimits. The default is "auto".
        YLimitsMode (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YLimitsMode, ["manual", "auto"])} = "auto";
        
        %Grid Show or hide grid
        %   Specify whether the grid is displayed. The default is "on".
        Grid (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on;

        %MultipleYAxis Single or multiple Y-axis
        % Specify whether to have multiple Y-axis stacked on the left side
        % of the scope
        MultipleYAxis (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
        
        %LegendVisible State of legend visibility
        %   Options: "on" and "off". The default is "on".
        LegendVisible (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on;
        
        %ColorTheme Color theme of the scope
        %   Options: "light", "dark" and "auto". The default is "auto"
        ColorTheme (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(ColorTheme, ["light", "dark", "auto"])} = "auto";
    
        %ScrollStarted
        %   Flag to check if auto scroll has been started
        ScrollStarted = false
        
        %PlayButtonEnabled
        %   Flag to indicate if play/pause button is enabled
        PlayButtonEnabled (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on;
    end
    
    properties (Transient, SetObservable, AbortSet)
        %State Current state of the scope.
        %   Options: "stopped", "paused" and "running"
        State (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(State, ["stopped", "running", "paused"])} = "stopped";
        
        %BufferSize Size of data storage buffer
        %   Specify the maximum number of data points stored for each
        %   signal
        BufferSize (1, 1) double {mustBeInteger, mustBePositive} = 50000;
    end        

    
    properties (SetAccess = private)
        %SerializedPropertyChangeListener
        %   Listener for changes of serialized properties
        SerializedPropertyChangeListener
                
        %FrontEndPropertyChangeReceived
        %   Flag to track if we have handled the current state change from
        %   front-end
        FrontEndPropertyChangeHandled = true
        
        %CachedDefaultProperties
        %   Cache scope properties that's provided in constructor or before
        %   the scope is shown for reset.
        CachedDefaultProperties
        
        %TimeAtPause Time at pause in time-driven mode
        %   Time on internal timer on pause in time-driven mode. It is used
        %   to check timestamp of incoming data.
        TimeAtPause (1, 1) double
    end
    
    properties
        %OnDemandPropertyRequested
        % Flag to track if we have requested on-demand property from
        % front-end. This is used to make sure the property set by received
        % front-end value does not trigger the setter again. We only need
        % one requested tracker as MATLAB will only handle one at a time
        OnDemandPropertyRequested = false
        
        %OnDemandPropertyReceived
        % Flag to track if we have received requested on-demand property
        % from front-end. We only need one received tracker as MATLAB will
        % only handle one at a time
        OnDemandPropertyReceived = false
        
        %ResetStarted
        %   Flag to track if user requested to start reset process. During
        %   reset, write will not work, property set request from MATLAB
        %   will not be handled
        ResetStarted = false
        
        %TimeAtPauseFlag
        %   Flag to track arrival of timeAtPause from front-end. We do not
        %   care about the exact value of this flag. We only care about
        %   its change. It is flipped whenever a timeAtPause is received.
        TimeAtPauseFlag = false
    end
    
    events
        % SignalCreated event used to notify listeners that front-end
        % signal has been crated
        SignalCreated
        
        % SignalOnDemandPropertyReceived event used to notify listeners
        % that requested on-demand properties from front-end have been
        % received
        SignalOnDemandPropertyReceived
        
        % FlushBuffer event used to notify listeners that socpe state
        % resumed to running from front-end. Need to flush data buffered
        % while paused.
        FlushBuffer
    end
    
    methods
        function obj = TimeScopeMessageHandler()
            serializedProperties = obj.getSerializedPropertyNames();
            serializedPropertyObjects = cellfun(@(x) findprop(obj, x), serializedProperties);
            % Add listener to handle change of serialized properties
            obj.SerializedPropertyChangeListener = event.proplistener(obj, serializedPropertyObjects,'PostSet', @obj.handleSerializedPropertiesChange);
            
        end
        
        % State set
        function set.State(obj, value)
            obj.State = value;
            % If the set request is from front-end change, don't send
            % request to front-end again
            if obj.FrontEndPropertyChangeHandled
                obj.setStateOnFrontEnd(value);
            end
        end
        
        function delete(obj)
           delete(obj.SerializedPropertyChangeListener); 
        end
        
                
        % Callbacks from Front-end
        % --------------------------- Start ------------------------------
        function requestSerializedSettings(obj, varargin)
            % Override superclass method
            % Front end request serialized properties to be sent.
            % These properties are set when scope is rendered.
            obj.CachedDefaultProperties = struct(...
                'title', obj.Title, ...
                'xLabel', obj.XLabel, ...
                'yLabel', obj.YLabel, ...
                'xLimits', obj.XLimits, ...
                'yLimits', obj.YLimits, ...
                'timeSpan', obj.TimeSpan, ...
                'yLimitsMode', obj.YLimitsMode, ...
                'grid', obj.Grid, ...
                'multipleYAxis', obj.MultipleYAxis, ...
                'legendVisible', obj.LegendVisible, ...
                'colorTheme', obj.ColorTheme, ...
                'bufferSize', obj.BufferSize, ...
                'playButtonEnabled', obj.PlayButtonEnabled);
            
            obj.sendToClient('setSerializedSettings', obj.CachedDefaultProperties);
        end
        
        function handleOnDemandPropertyFromFrontEnd(obj, msg)
            % msg should have property name, identifier and value
            if isempty(msg.identifier)
                obj.(msg.property) = msg.value;
            else
                % Notify signal of property value received
                data = matlab.hwmgr.scopes.internal.SignalPropertyReceivedEventData(msg);
                notify(obj, "SignalOnDemandPropertyReceived", data);
            end
            obj.OnDemandPropertyRequested = false;
            obj.OnDemandPropertyReceived = true;
        end
        
        function handleSignalCreatedFromFrontEnd(obj, ~)
            notify(obj, "SignalCreated");
        end
        
        function handleStateChangeFromFrontEnd(obj, newState)
            % Handle front-end message on state change. Notify front-end
            % message received
            obj.FrontEndPropertyChangeHandled = false;
            obj.State = newState;
            obj.FrontEndPropertyChangeHandled = true;
            obj.sendToClient('handleServerStateChangeReceived', strcat(newState, 'Received'));
            if strcmp(newState, "running")
                % Notify TimeScope to flush data buffered while paused
                notify(obj, "FlushBuffer");
            end
        end
        
        function handleTimeAtPauseFromFrontEnd(obj, timeAtPause)
            % Handle time at pause update from front-end
            obj.TimeAtPause = timeAtPause;
            
            % Flip TimeAtPauseFlag to change its value
            obj.TimeAtPauseFlag = ~obj.TimeAtPauseFlag;
        end

        % Callbacks from Front-end
        % ---------------------------- End -------------------------------
        
        % Override superclass method
        function onStart(this)
            message = struct('TimeBased', true, 'numChannels', 1);
            this.sendToClient('onStart', message);            
        end
    end    
    
    methods (Access = {?matlab.hwmgr.scopes.TimeScope})
        % Action requests to front-end
        % --------------------------- Start ------------------------------        
        function requestOnDemandPropertyOnFrontEnd(obj, property, varargin)
            % property is the name of the MATLAB property
            % proeprty value
            
            % identifier is the id of signal for signal properties
            identifier = [];
            if ~isempty(varargin)
                identifier = varargin{1};
            end
            msg = struct('property', property, 'identifier', identifier);
            obj.OnDemandPropertyRequested = true;
            obj.sendToClient('requestOnDemandProperty', msg);
            waitfor(obj, "OnDemandPropertyReceived", true);
            obj.OnDemandPropertyReceived = false;
        end
        
        function setScopePropertyOnFrontEnd(obj, propName, value)
            % General method for setting property and publish to front end.
            
            if ~obj.OpenComplete
                % Don't set property indivisually before the scope is
                % rendered. Setting is done by serializedSetting.
                return;
            end
            if obj.ResetStarted
                % Don't send any request to front-end when it is resetting
                % the scope
                return;
            end
            
            obj.sendToClient(strcat('set', propName), value);
        end
        
        function setSignalPropertyOnFrontEnd(obj, signal, propName, value)
            msg.identifier = signal.ID;
            msg.property = propName;
            msg.value = value;
            obj.sendToClient('setSignalProperty', msg);
        end
        
        function setStateOnFrontEnd(obj, newState)
            % Cache the current value of flag to see if it has any change
            temp = obj.TimeAtPauseFlag;
            
            obj.sendToClient('setFrontEndState', newState);
            
            % In time-driven mode, if paused, the TimeAtPause will be
            % updated by front-end. We check value change of
            % TimeAtPauseFlag on MATLAB side to indicate arrival of
            % TimeAtPause. We flip it whenever a timeAtPause is received.
            % Do not use value of TimeAtPause for the check since it may
            % not change. Example: pause is called right after
            % startAutoScroll.
            if obj.ScrollStarted && newState == "paused"
                % Wait for TimeAtPause value change
                waitfor(obj, "TimeAtPauseFlag", ~temp);
            end
        end
        
        function startAutoScrollOnFrontEnd(obj, timeAtStart)
            obj.sendToClient('startAutoScroll', timeAtStart);
        end        
        
        function clearDataOnFrontEnd(obj)
            obj.sendToClient('clearData', {});
        end
        
        function createSignalOnFrontEnd(obj, id, tag)
            msg.uuid = id;
            msg.tag = tag;
            obj.sendToClient('createSignal', msg);
        end
        
        function removeSignalOnFrontEnd(obj, id)
            obj.sendToClient('removeSignalOnFrontEnd', id);
        end
        
        function setBufferSize(obj, bufferSize)
            obj.sendToClient('setBufferSize', bufferSize);
        end
        
        % Action requests to front-end
        % ---------------------------- End -------------------------------  
        
        
        % Callbacks from MATLAB API
        % --------------------------- Start ------------------------------
        function handleSerializedPropertiesChange(obj, src, ~)
            % Handle changes of serialized properties
            if obj.OnDemandPropertyRequested
                return;
            end
            obj.setScopePropertyOnFrontEnd(src.Name, obj.(src.Name));
        end
        
        function handleSignalPropertiesChange(obj, signal, propertyName, value)
            obj.setSignalPropertyOnFrontEnd(signal, propertyName, value);
        end
                
        % Callbacks from MATLAB API
        % ---------------------------- End -------------------------------
        
                
        
        % ------------------- Utility functions -------------------------
        function propList = getSerializedPropertyNames(~)
            % Get properties that can be serialized to JS before rendering
            propList = {'Title', 'XLabel', 'YLabel', 'XLimits', 'YLimits',...
                'TimeSpan', 'YLimitsMode', 'Grid', 'MultipleYAxis', ...
                'LegendVisible', 'ColorTheme', 'PlayButtonEnabled'};
        end
    end     
end
