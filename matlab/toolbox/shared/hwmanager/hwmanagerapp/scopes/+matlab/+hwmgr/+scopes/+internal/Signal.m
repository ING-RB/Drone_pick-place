classdef Signal < handle
%Signal Signal class representing trace in TimeScope
%
%   Signal properties:
%       LineProperties - Visual properties of signal trace
%       Name - Name on scope for signal
%       PlotType - Type of plot for signal
%       Tag - Object identifier
%       Visible - State of signal trace visibility
%       YLabel - Label for signal on Y-axis
%       YLimits - Y-axis limits
%       DataCursor - Data cursor for signal
%
%   Signal methods:
%       addData - Add new data to time scope

% Copyright 2020 The MathWorks, Inc.
    
    properties (Access = {?matlab.hwmgr.scopes.TimeScope, ...
        ?matlab.hwmgr.scopes.TimeScopeMessageHandler, ?matlab.unittest.TestCase})
        %Parent The TimeScope this signal belongs to.
        Parent (1, 1) matlab.hwmgr.scopes.TimeScope
        
        %ID The unique identifier of the signal provided by back-end
        ID
        
        %MultipleYAxis Flag for current multiple Y-axis mode of parent
        MultipleYAxis = false;
        
        %AddComplete
        %   A flag used to track if the signal has been added to the
        %   front-end.
        AddComplete = false;
    end
    
    properties (Access = private)        
        %StroredYLimits
        %   This is the property that YLimits depends on.
        StoredYLimits (1, 2) {matlab.hwmgr.internal.util.mustBeDoubleVector(StoredYLimits), ...
            matlab.hwmgr.internal.util.mustBeIncreasing(StoredYLimits)} = [0, 10]
        
        %StoredVisible
        %   This is the property that Visible depends on.
        StoredVisible (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on
        
        %RegularPropertyChangeListener
        %   PostSet listeners for regular property change of signal
        RegularPropertyChangeListener
        
        %OnDemandPropertyReceivedListener
        %   Event listener for SignalOnDemandPropertyReceived event for
        %   on-demand property receiving.
        OnDemandPropertyReceivedListener
    end
    
    properties (SetObservable = true, Dependent)
        %Visible - State of signal trace visibility
        %   Specify signal trace visibility as "on" or "off". The default
        %   is "on".
        Visible (1, 1) matlab.lang.OnOffSwitchState

        %YLimits - Y-axis limits
        %   Y-axis limits, specified as a two-element numeric vector, [ymin
        %   ymax]. The default is [0 10].
        YLimits (1, 2) {matlab.hwmgr.internal.util.mustBeDoubleVector(YLimits), ...
            matlab.hwmgr.internal.util.mustBeIncreasing(YLimits)}
    end
    
    properties (SetObservable = true)
        %Tag - Object identifier
        %   Signal object identifier, specified as a character vector or
        %   string. Specify a unique Tag value to serve as an identifier
        %   for the signal.
        Tag (1, 1) string
        
        %Name - Name on the scope for the signal
        %   Name of the signal shown in the scope legend, specified as a
        %   character vector or string.
        Name (1, 1) string
        
        %YLabel - Label for signal on Y-axis
        %   Label on the Y-axis associated with the signal in multiple
        %   y-axes mode, specified as a character vector or string.
        YLabel (1, 1) string
        
        %LineProperties - Visual properties of signal trace
        %   See also matlab.hwmgr.scopes.LineProperties
        LineProperties (1, 1) matlab.hwmgr.scopes.LineProperties
        
        %PlotType - Type of plot for signal
        %   Type of plot for the signal, specified as 'Line', 'Stairs', or
        %   'Stem'.
        PlotType (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(PlotType, ["line", "stem", "stairs"])} = "line";
    
        %DataCurosr - Data cursor for signal
        %   Display data cursor for signal, specified as 'none', 'single'
        %   or 'delta'.
        DataCursor (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(DataCursor, ["none", "single", "delta"])} = "none";
    end
    
    methods (Access = {?matlab.hwmgr.scopes.TimeScope})
        function obj = Signal(parent, tag)
            obj.Parent = parent;
            obj.Tag = tag;
            obj.Name = tag;
            obj.addPropertySetListener();
            obj.OnDemandPropertyReceivedListener = obj.registerSignalOnDemandPropertyReceivedListener();
        end
    end
    
    methods
        function addData(obj, time, value)
            %addData Add new data to signal
            %   addData(obj, time, value) streams and displays new data to
            %   the signal. time is a vector of timestamps of the data, and
            %   value is a vector of data values. Both time and value are
            %   vectors of double.
            %
            %   Example:
            %   time = [1, 2, 3, 4, 5];
            %   value = [5, 10, 2, 6.5, 12];
            %   addData(scope, time, value);
            
            arguments
                obj (1, 1) matlab.hwmgr.scopes.internal.Signal
                time {matlab.hwmgr.internal.util.mustBeDoubleVector, ...
                    matlab.hwmgr.internal.util.mustBeIncreasing, mustBeNonnegative}
                value {matlab.hwmgr.internal.util.mustBeDoubleVector}
            end
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
            obj.Parent.write(obj, [time, value]);            
        end

        function delete(obj)
            delete(obj.RegularPropertyChangeListener);
            delete(obj.OnDemandPropertyReceivedListener);
        end
        
        function set.Visible(obj, value)
            obj.StoredVisible = value;
        end
        function value = get.Visible(obj)
            if obj.AddComplete
                obj.handleSignalOnDemandPropertyRequest("Visible");
            end
            value = obj.StoredVisible;
        end
        
        function set.YLimits(obj, value)
            obj.StoredYLimits = value;
        end
        function value = get.YLimits(obj)
            if obj.AddComplete && obj.MultipleYAxis
                obj.handleSignalOnDemandPropertyRequest("YLimits");
            end
            value = obj.StoredYLimits;
        end
        
        function set.LineProperties(obj, newLine)
            oldLine = obj.LineProperties;
            props = properties(newLine);
            % Find the line property that's changed and send to parent
            for i = 1:length(props)
                if ~isequal(oldLine.(props{i}), newLine.(props{i}))
                    obj.sendNewPropertyToParent(props{i}, newLine.(props{i}));
                end
            end
            obj.LineProperties = newLine;
        end
    end
    
    methods (Access = private)
        function propList = getSignalPropertyNames(~)
            % Get properties that can be set to affect front-end
            propList = {'Name', 'Visible', 'YLimits', 'YLabel', 'PlotType', 'DataCursor'};
        end
        
        % Listener for property set
        % ---------------------- Start -----------------------------
        
        % Add property set listener for regular writable properties
        function addPropertySetListener(obj)
            regularProperties = obj.getSignalPropertyNames();
            regularPropertyObjects = cellfun(@(x) findprop(obj, x), regularProperties);
            % Add listener to handle change of front-end writable properties
            obj.RegularPropertyChangeListener = event.proplistener(obj, regularPropertyObjects,'PostSet', @obj.handleSignalPropertiesChange);
        end
        
        % Handle regular writable property set from MATLAB
        function handleSignalPropertiesChange(obj, src, ~)
            % Pass in signal object, property name, and value
            
            % YLimits and Visible are on-demand. Their properties are
            % dependent, need to set the real one.
            if strcmp(src.Name, "YLimits") || strcmp(src.Name, "Visible")
                value = obj.(strcat("Stored", src.Name));
            else
                value = obj.(src.Name);
            end
            obj.sendNewPropertyToParent(src.Name, value);
        end
        
        % Listener for property set
        % ----------------------- End ------------------------------
        
        
        % Listener and handler for on-demand property get
        % ---------------------- Start -----------------------------
        
        % Handle signal on-demand property get from MATLAB
        function handleSignalOnDemandPropertyRequest(obj, property)
            obj.Parent.handleSignalOnDemandPropertyRequest(property, obj.ID);
        end
        
        % Handle property received message for on-demand properties
        function handleSignalOnDemandPropertyReceived(obj, ~, eventData)
            obj.(strcat("Stored", eventData.Property)) = eventData.Value;
        end
        
        % Register a listener on the MessageHandler for on-demand property
        % received event
        function listener = registerSignalOnDemandPropertyReceivedListener(obj)
            eventName = 'SignalOnDemandPropertyReceived';
            listener = obj.Parent.registerListenerOnMessageHandler(...
                eventName, @obj.handleSignalOnDemandPropertyReceived);
        end
        
        % Listener and handler for on-demand property get
        % ----------------------- End ------------------------------        
    end
    
    methods (Access = {?matlab.hwmgr.scopes.TimeScope})
        function sendNewPropertyToParent(obj, propertyName, value)
            obj.Parent.handleSignalPropertiesChange(obj, propertyName, value);
        end
    end
end