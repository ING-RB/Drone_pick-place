classdef (Hidden) BasicScopeMessageHandler < matlabshared.scopes.WebScopeMessageHandler
    %BASICSCOPEMESSAGEHANDLER The message handler of the BasicScope. It
    %manages messages between MATLAB interface and the frontend JS scope.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Transient, SetObservable)
        %NumberOfChannels Number of channels
        %   Specify the number of lines to draw. The default is 1.
        NumberOfChannels (1, 1) double {mustBeInteger, mustBePositive} = 1
        
        %XScale X-axis scale
        %   Specify the X-axis scale as one of 'linear' or 'log'. The
        %   default is 'Linear'. You cannot set the X-axis scale to 'Log'
        %   when the XOffset property is set to a negative value.
        XScale (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(XScale, ["linear", "log"])} = "linear";
        
        %YScale Y-axis scale
        %   Specify the Y-axis scale as one of 'linear' or 'log'. The
        %   default is 'Linear'.
        YScale (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YScale, ["linear", "log"])} = "linear";
        
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
        %   [xmin xmax]. The default is [0 1].
        XLimits (1, 2) double = [0, 1];
        
        %YLimits Y-axis limits
        %   Specify the y-axis limits as a two-element numeric vector:
        %   [ymin ymax]. The default is [0 1].
        YLimits (1, 2) double = [0, 1];
        
        %YLimMode auto or manual y limits
        %   Specify whether the y limits automatically change with input
        %   data. When set to "auto", y limits automatically adjust to
        %   include the full range of data. When set to "manual", it
        %   remains the value provided to YLimits. The default is "manual".
        YLimMode (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YLimMode, ["manual", "auto"])} = "auto";
        
        %Grid Show or hide grid
        %   Specify whether the grid is displayed. The default is "on".
        Grid (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(Grid, ["on", "off"])} = "on";
    
        %ColorTheme light or dark color theme
        %   Specify the color theme of scope. The default is "auto".
        ColorTheme (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(ColorTheme, ["light", "dark", "auto"])} = "auto";

        %MultipleYAxis Single or multiple Y-axes
        % Specify whether to have multiple Y-axes stacked on the left side
        % of the scope
        MultipleYAxis (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off

        %LineProperties
        %   Array of LineProperties.
        LineProperties (1, :) matlab.hwmgr.scopes.LineProperties

        %YAxesInfo
        % Array of YAxisInfo
        YAxesInfo (1, :) matlab.hwmgr.scopes.YAxisInfo
    end
    
    properties (SetObservable, SetAccess = private)
        %ReadyToCache Status for caching line and legend
        %   Specify whether the scope is ready to cache line and legend
        %   properties.
        ReadyToCache = false;
    end
    
    properties (Access = private)
        %JSBroadcastChannelPrefix
        %   Prefix of JSBroadcastChannel cliendId
        JSBroadcastChannelPrefix = '/HWF/basicScope'
        
        %JSBroadcastChannel
        %   Connector channel for front end broadcasting axis limit and
        %   legend position change.
        JSBroadcastChannel
        
        %BroadcastSubscriber
        %   Subscriber to the JSBroadcastChannel
        BroadcastSubscriber = ''
        
        %NewLimitsReceived
        %   Status of if new axis limits are received from JS
        NewLimitsReceived = false;
        
        %NewYLimModeReceived
        %   Status of if new ylim mode is received from JS
        NewYLimModeReceived = false;
               
        %SerializedPropertyChangeListener
        %   Listener for changes of serialized properties
        SerializedPropertyChangeListener
    end
    
    properties (Access = {?matlab.hwmgr.scopes.BasicScope})
        %ReceivedLegendLocation
        %   Cache legend location/position changed by front-end
        ReceivedLegendLocation
    end
    
    events
        %NewLegendLocationReceived
        %   Event of received new legend location from front-end
        NewLegendLocationReceived
        %   Event of data written on the front end
        NewDataWritten
        %   Event of Minor Y Limit received
        MinorAutoYLimChanged
    end
    
    methods
        function obj = BasicScopeMessageHandler()
            obj.PlotType = 'line';
            serializedProperties = obj.getSerializedPropertyNames();
            serializedPropertyObjects = cellfun(@(x) findprop(obj, x), serializedProperties);
            % Add listener to handle change of serialized properties
            obj.SerializedPropertyChangeListener = event.proplistener(obj, serializedPropertyObjects,'PostSet', @obj.handleSerializedPropertiesChange);
        end
        
        function openComplete(obj, message)
            % Callback when the scope is opened and rendered.
            openComplete@matlabshared.scopes.WebScopeMessageHandler(obj, message);
            obj.ReadyToCache = true;
        end
        
        function attachToJSBroadcastChannel(obj)
            % Subscribes to the web application communication channel
            if isempty(obj.BroadcastSubscriber)
                obj.BroadcastSubscriber = message.subscribe(obj.JSBroadcastChannel, @(msg)obj.handleJSBroadcastMessage(msg));
            else
                warning('Scope broadcast channel is already attached');
            end
        end
        
        function detachFromJSBroadcastChannel(obj)
            message.unsubscribe(obj.BroadcastSubscriber);
            obj.BroadcastSubscriber = '';
        end
        
        function clearDisplay(obj)
            % Clear the current scope display including lines and legend.
            obj.publish('clearDisplay', []);
        end
        
        function requestFitToView(obj)
            % Request front end to fit to view
            obj.publish('fitToView', []);
        end
        
        function setLineProperties(obj, linePropName, value)
            obj.setJSProperty(linePropName, value);
        end
        
        function setLegendProperties(obj, lgdPropName, value)
            obj.setJSProperty(strcat('Legend', lgdPropName), value);
        end
        
        function setJSProperty(obj, propName, value)
            % General method for setting property and publish to front end.
            
            if ~obj.OpenComplete
                % Don't set property indivisually before the scope is
                % rendered. Setting is done by serializedSetting.
                return;
            end
            if strcmp(propName, 'XLimits') || strcmp(propName, 'YLimits')
                if obj.NewLimitsReceived
                    % If changes are on x,y limits, and the change request
                    % is from user changes at front end, we do not need to
                    % notify the front end again.
                    return;
                end
            end
            if strcmp(propName, 'YLimMode') && obj.NewYLimModeReceived
                % If front end changes YLimMode, don't notify front end
                % again.
                return;
            end
            obj.publish(strcat('set', propName), value);
        end
        
        function cacheLineProperties(obj, lineProps)
            % Send LineProperties to front end to cache it.
            linePropsStruct = matlab.hwmgr.scopes.BasicScopeMessageHandler.convertObjectToStruct(lineProps);
            if isscalar(linePropsStruct)
                linePropsStruct = {linePropsStruct};
            end
            obj.publish('cacheLineProperties', linePropsStruct);
        end
        
        function cacheLegend(obj, legend)
            % Send Legend to front end to cache it.
            legendPropsStruct = matlab.hwmgr.scopes.BasicScopeMessageHandler.convertObjectToStruct(legend);
            obj.publish('cacheLegend', legendPropsStruct);
        end
        
        function deleteLegend(obj)
            obj.publish('deleteLegend', '');
        end

        function setChannelProperty(obj, message)
            obj.publish('setChannelProperty', message);
        end
        
        function requestSerializedSettings(this, varargin)
            % Front end request serialized properties to be sent.
            % These properties are set when scope is rendered.
            
            this.publish('setSerializedSettings', struct(...
                'plotType', this.PlotType, ...
                'numChannels', this.NumberOfChannels, ...
                'xScale', this.XScale, ...
                'yScale', this.YScale, ...
                'title', this.Title, ...
                'xLabel', this.XLabel, ...
                'yLabel', this.YLabel, ...
                'xLimits', this.XLimits, ...
                'yLimits', this.YLimits, ...
                'yLimMode', this.YLimMode, ...
                'grid', this.Grid, ...
                'colorTheme', this.ColorTheme, ...
                'multipleYAxis', this.MultipleYAxis));
        end
        
        function updateClientId(obj, value)
            % Override updateClientId method of WebMessageHandler to also
            % update our broadcast channel
            updateClientId@matlabshared.scopes.WebMessageHandler(obj, value);
            obj.updateJSBroadcastChannel();
        end
        
        function delete(obj)
            obj.detachFromJSBroadcastChannel();
            delete(obj.SerializedPropertyChangeListener);
        end
    end
    
    methods
        % Setters
        function set.XLimits(obj, value)
            validateattributes(value, {'double'}, {'increasing'});
            obj.XLimits = value;
        end
        
        function set.YLimits(obj, value)
            validateattributes(value, {'double'}, {'increasing'});
            obj.YLimits = value;
        end
    end
    
    methods (Access = {?matlab.hwmgr.scopes.BasicScope})
        function updateJSBroadcastChannel(obj)
            % Update the channel when clientId is updated
            obj.JSBroadcastChannel = strcat(obj.JSBroadcastChannelPrefix, obj.ClientId);
        end
    end
    
    methods (Access = private)
        function propList = getSerializedPropertyNames(~)
            % Get properties that can be serialized to JS before rendering
            propList = {'NumberOfChannels', 'XScale', 'YScale', 'Title', 'XLabel', 'YLabel', ...
                'XLimits', 'YLimits', 'YLimMode', 'Grid', 'ColorTheme', 'MultipleYAxis'};
        end
        
        function handleJSBroadcastMessage(obj, msg)
            % This method is called when a new message is received on the
            % JSBroadcastChannel from front end.
            switch msg.msgID
                case "LimitChanged"
                    obj.handleLimitChange(msg.data);
                case "YLimModeChanged"
                    obj.handleYLimModeChange(msg.data);
                case "LegendLocationChanged"
                    obj.handleLegendLocationChange(msg.data);
                case "NewDataWritten"
                    obj.handleNewDataWritten();
                case "MinorAutoYLimChanged"
                    obj.handleMinorAutoYLimChanged(msg.data);
            end
        end
        
        function handleNewDataWritten(obj)
            notify(obj, "NewDataWritten")
        end

        function handleMinorAutoYLimChanged(obj, data)
            % Update YAxesInfo with the recieved limits
            if obj.YAxesInfo(data.key+1).YLimMode == "auto"
                obj.YAxesInfo(data.key+1).YLimits = data.yAutoLimits;
            end
        end

        function handleSerializedPropertiesChange(obj, src, ~)
            % Handle changes of serialized properties
            obj.setJSProperty(src.Name, obj.(src.Name));
        end
        
        function handleLimitChange(obj, data)
            % This method handles updated axis limits from front end.
            
            % Setting NewLimitsReceived to true to signify the change is
            % from the front end. So the limit setters will avoid notifying
            % front end of changes again.
            obj.NewLimitsReceived = true;
            obj.XLimits = data.x';
            obj.YLimits = data.y';
            obj.NewLimitsReceived = false;
        end
        
        function handleYLimModeChange(obj, data)
            % This method handles ylimmode change from front end
            
            % Setting NewLimitsReceived to true to signify the change is
            % from the front end. So the limit setters will avoid notifying
            % front end of changes again.
            obj.NewYLimModeReceived = true;
            obj.YLimMode = data;
            obj.NewYLimModeReceived = false;
        end
        
        function handleLegendLocationChange(obj, data)
            % This method handles legend position/location change from front-end
            % Notify BasicScope of the change
            obj.ReceivedLegendLocation = data;
            notify(obj, "NewLegendLocationReceived");
        end
    end
    
    methods (Static, Access = private)
        function outStruct = convertObjectToStruct(inputObject)
            % Convert objects to structs for connector.
            props = properties(inputObject);
            outStruct = repmat(struct, 1, length(inputObject));
            for i = 1:length(inputObject)
                for j = 1:length(props)
                    value = inputObject(i).(props{j});
                    if isa(inputObject, 'matlab.hwmgr.scopes.Legend') && ...
                            strcmp(props{j}, "String") && isscalar(value)
                        value = {value};
                    end
                    outStruct(i).(props{j}) = value;
                end
            end
        end
    end    
end
