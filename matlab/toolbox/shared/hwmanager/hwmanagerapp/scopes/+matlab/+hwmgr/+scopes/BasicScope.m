classdef BasicScope < handle
    %BASICSCOPE The user facing interface for the BasicScope widget to
    %support basic streaming/plotting functions in Hardware Manager apps.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = {?matlab.unittest.TestCase})
        %BasicScopeImplementation
        %   The underlying implementation for scope rendering and streaming
        BasicScopeImplementation
        
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
    end
    
    properties (Access = private)        
        %LinesCreated
        %   Status of whether lines have been plotted in scope.
        LinesCreated = false
        
        %OldLineProperties
        %   LineProperties before the most recent change. Used to track
        %   which property of which line has been changed.
        OldLineProperties
        
        %LegendDeleteListener
        %   Listener for Legend delet event
        LegendDeleteListener
        
        %LegendPropertyChangeListener
        %   Listener for property changes of the scope "Legend"
        LegendPropertyChangeListener
        
        %LegendJSLocationChangeListener
        %   Listener to NewLegendLocationReceived event from message handler
        LegendJSLocationChangeListener
        
        %LegendJSLocationChanged
        %   Flag to indicate if legend location/position is changed by the
        %   front-end
        LegendJSLocationChanged = false;
        
        %ReadyToCacheListener Listener for ReadyToCache property of the
        %MessageHandler
        ReadyToCacheListener

        %DataUpdateListener
        %   Listener for when data write is complete 
        DataUpdateListener
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
    
    properties (AbortSet, Dependent)
        %Offset
        %   Initial value of sample points XData.
        Offset (1, 1) double {mustBeFinite}
        
        %StepSize
        %   Interval between two sample points.
        StepSize (1, 1) double {mustBePositive, mustBeFinite}
        
        %NumChannels Number of channels
        %   Specify the number of lines to draw. The default is 1.
        NumChannels (1, 1) double {mustBeInteger, mustBePositive}
    end
    
    properties (SetObservable, AbortSet, Dependent)
        %LineProperties
        %   Array of LineProperties.
        LineProperties (1, :) matlab.hwmgr.scopes.LineProperties

        % Array of YAxisInfo
        YAxesInfo (1, :) matlab.hwmgr.scopes.YAxisInfo
    end
    
    properties (SetObservable, AbortSet, SetAccess = private)
        %Legend
        %   Handle to scope legend.
        Legend matlab.hwmgr.scopes.Legend
    end
    
    properties (Dependent)
        %PlotType Option to control the type of plot
        %   Specify the type of plot to be used. Valid types are 'Line'
        %   'Stairs' and 'Stem'.
        PlotType (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(PlotType, ["line", "stem", "stairs"])}
        
        %XScale X-axis scale
        %   Specify the X-axis scale as one of 'linear' or 'log'. The
        %   default is 'linear'. You cannot set the X-axis scale to 'Log'
        %   when the XOffset property is set to a negative value.
        XScale;
        
        %YScale Y-axis scale
        %   Specify the Y-axis scale as one of 'linear' or 'log'. The
        %   default is 'linear'.
        YScale;
        
        %Title Display title
        %   Specify the display title as a string. The default value is ''.
        Title;
        
        %XLabel X-axis label
        %   Specify the x-axis label as a string. The default value is ''.
        XLabel;
        
        %YLabel Y-axis label
        %   Specify the y-axis label as a string. The default value is ''.
        YLabel;
        
        %XLimits X-axis limits
        %   Specify the x-axis limits as a two-element numeric vector:
        %   [xmin xmax]. The default is [0 1].
        XLimits;
        
        %YLimits Y-axis limits
        %   Specify the y-axis limits as a two-element numeric vector:
        %   [ymin ymax]. The default is [0 1].
        YLimits;
        
        %YLimMode auto or manual y limits
        %   Specify whether the y limits automatically change with input
        %   data. When set to "auto", y limits automatically adjust to
        %   include the full range of data. When set to "manual", it
        %   remains the value provided to YLimits. The default is "manual".
        YLimMode
        
        %Grid Show or hide grid
        %   Specify whether the grid is displayed. The default is "on".
        Grid;
        
        %ColorTheme light, dark or auto color theme
        %   Specify the color theme of scope. The default is "auto".
        ColorTheme

        %MultipleYAxis - Single or multiple Y-axes
        % Specify display of multiple Y-axes stacked on the left side of
        % the scope, as "on" or "off". The default is "off".
        MultipleYAxis (1, 1) matlab.lang.OnOffSwitchState
    end
    
    properties (Access = private, Constant)
        %URL url of the web app
        Url = 'toolbox/shared/hwmanager/hwmanagerapp/scopes/basicscope/index';
    end
    
    methods
        function obj = BasicScope(varargin)
            narginchk(0, 1);
            
            obj.BasicScopeImplementation = matlab.hwmgr.scopes.BasicScopeImplementation(obj.Url);
            
            obj.MessageHandler = obj.BasicScopeImplementation.MessageHandler;
            
            % MessageHandler subscribe the JSBroadcastChannel
            obj.MessageHandler.attachToJSBroadcastChannel();
            
            obj.LineProperties = matlab.hwmgr.scopes.LineProperties();
            obj.YAxesInfo = matlab.hwmgr.scopes.YAxisInfo();
            obj.OldLineProperties = obj.LineProperties;
            obj.Legend = matlab.hwmgr.scopes.Legend.empty();
            
            % Add listener to "ReadyToCache" from message handler
            obj.ReadyToCacheListener = event.proplistener(obj.MessageHandler, ...
                findprop(obj.MessageHandler, 'ReadyToCache'), 'PostSet', @(src, event)obj.handleReadyToCache());
            
            % Add listener to "NewLegendLocationReceived" from message
            % handler. This indicates legend location/positionchange from
            % front-end
            obj.LegendJSLocationChangeListener = event.listener(obj.MessageHandler, ...
                "NewLegendLocationReceived", @(src, event)obj.handleJSLegendLocationcChange());
            
            obj.LegendDeleteListener = event.listener(obj.Legend, "ScopeLegendDeleted", ...
                @(src, event)obj.notifyDeleteLegend());

            % Add listener to "NewDataWritten" from message
            % handler. This indicates new data was written and hence the
            % Y limits might need to be updated for the multiple Y-axes
            obj.DataUpdateListener = event.listener(obj.MessageHandler, ...
                "NewDataWritten", @(src, event)obj.updateChannelPropertyToParent());
            
            % A uipanel is provided as input to host the scope
            if nargin == 1
                validateattributes(varargin{1}, {'matlab.ui.container.Panel'}, {'scalar'}, 1);
                % Check if panel has other children                
                if ~isempty(varargin{1}.Children)
                    msgID = 'hwmanagerapp:scopes:NonEmptyPanel';
                    error(message(msgID));
                end     
                obj.Parent = varargin{1};
                obj.GridLayout = uigridlayout(obj.Parent, [1, 1], 'Padding', [0, 0, 0, 0]);
                obj.UiHtml = uihtml(obj.GridLayout, 'HTMLSource', obj.BasicScopeImplementation.getFullUrl());      
                
                % When the scope is embedded in uipanel, it is shown
                % automatically without calling "show", so we need to wait
                % for the open to complete.
                obj.BasicScopeImplementation.waitForOpen();
            end            
        end
        
        function delete(obj)
            delete(obj.LegendDeleteListener);
            delete(obj.LegendPropertyChangeListener);
            delete(obj.ReadyToCacheListener);
            delete(obj.DataUpdateListener);
            delete(obj.GridLayout);
        end
        
        function show(obj)
            % Show scope if it is not embedded in a uipanel
            if isempty(obj.Parent)
                obj.BasicScopeImplementation.show();
            end
        end
        
        function write(obj, data)
            % Transpose data if needed
            dataSize = size(data);
            if dataSize(2) == obj.NumChannels
                % Keep the data as it is
            elseif dataSize(1) == obj.NumChannels
                % Transpose data
                data = data';
            else
                msgID = 'hwmanagerapp:scopes:WriteDataSize';
                error(message(msgID));
            end
            
            % Render the scope if it is not embedded in a uipanel, and not
            % already visible for CEF, we do not render on write for chrome 
            % because we cannot get visibility from chrome.
            % isVisible is only applicable to CEF window.
            % DebugLevel > 2 means we are using CEF window.
            
            if isempty(obj.Parent) && ~obj.BasicScopeImplementation.isVisible ...
                    && obj.DebugLevel > 2
                obj.show();
            end
            
            obj.BasicScopeImplementation.write(data);
            obj.LinesCreated = true;
        end
        
        function release(obj)
            % Release system object resources
            % This will also reset all line and legend properties.
            obj.BasicScopeImplementation.release();
            obj.resetLines();
            obj.resetLegend();
        end
        
        function lgd = legend(obj, varargin)
            % This method construct a legend for the scope.
            obj.Legend = matlab.hwmgr.scopes.Legend(obj.NumChannels, varargin{:});
            
            % Add listener to legend properties.
            legendProperties = {'String', 'Location', 'Position', 'Visible'};
            legendPropertyObjects = cellfun(@(x) findprop(obj.Legend, x), legendProperties);
            obj.LegendPropertyChangeListener = event.proplistener(obj.Legend, legendPropertyObjects, 'PostSet', @obj.handleLegendPropertyChange);
            
            % Add listener to legend deletion event. Notify front end that
            % user deletes legend on MATLAB side.
            obj.LegendDeleteListener = event.listener(obj.Legend, "ScopeLegendDeleted", @(src, event)obj.notifyDeleteLegend());
            lgd = obj.Legend;
        end
        
        function clearDisplay(obj)
            % Clear all data from current display of the scope.
            obj.MessageHandler.clearDisplay();
            obj.release();
        end
        
        function fitViewToData(obj)
            obj.MessageHandler.requestFitToView();
            obj.YLimMode = "auto";
        end
    end
    
    methods (Access = private)
        function handleReadyToCache(obj)
            % Scope ReadyToCache callback
            % Send cached lines and legend to JS after scope is rendered
            obj.handleLinePropertiesChange();
            obj.handleLegendChange();
        end
        
        function handleLinePropertiesChange(obj)
            % LineProperties change callback
            
            % Only send lines when rendering is complete
            if obj.MessageHandler.ReadyToCache
                if obj.LinesCreated
                    obj.updateLineProperties(obj.OldLineProperties, obj.LineProperties);
                else
                    obj.MessageHandler.cacheLineProperties(obj.LineProperties);
                end
            end
            obj.OldLineProperties = obj.LineProperties;
        end
        
        function notifyDeleteLegend(obj)
            obj.MessageHandler.deleteLegend();
        end
        
        function handleJSLegendLocationcChange(obj)
            location = obj.MessageHandler.ReceivedLegendLocation;
            obj.LegendJSLocationChanged = true;
            if isa(location, 'double')
                % If JS location value is of type double, it is a 1x2 array for
                % legend position property
                obj.Legend.Position = location';
            else
                % JS location value is a string for legend location property
                obj.Legend.Location = location;
            end
            obj.LegendJSLocationChanged = false;
        end
        
        function handleLegendChange(obj)
            % Legend handle change callback
            
            if ~isempty(obj.Legend) && ~isvalid(obj.Legend)
                % This is the case when legend is deleted.
                return;
            end
            
            % Only send legend when rendering is complete and user
            % constructed legend
            if obj.MessageHandler.ReadyToCache
                obj.MessageHandler.cacheLegend(obj.Legend);
            end
        end
        
        function handleLegendPropertyChange(obj, prop, ~)
            % Legend property change callback
            
            if obj.LegendJSLocationChanged
                % No need to update front-end since the change is from
                % front-end
                return;
            end
            
            % Only send legend when rendering is complete and user
            % constructed legend
            if obj.MessageHandler.ReadyToCache
                if obj.LinesCreated
                    if ~strcmp(obj.Legend.(prop.Name), "none")
                        % Don't send "none" value of "Location" or "Position"
                        % They refer to the same "location" property at front end
                        obj.MessageHandler.setLegendProperties(prop.Name, obj.Legend.(prop.Name));
                    end
                else
                    obj.MessageHandler.cacheLegend(obj.Legend);
                end
            end
        end
        
        
        function updateLineProperties(obj, oldLines, newLines)
            % Identify changes to line properties, and update changes to
            % the front end.
            props = properties(newLines);
            for i = 1:length(newLines)
                for j = 1:length(props)
                    if ~isequal(oldLines(i).(props{j}), newLines(i).(props{j}))
                        obj.MessageHandler.setLineProperties(props{j}, {i-1, newLines(i).(props{j})});
                    end
                end
            end
        end
        
        function resetLines(obj)
            % Reset LineProperties to default
            obj.LinesCreated = false;
            obj.LineProperties = repmat(matlab.hwmgr.scopes.LineProperties(), 1, obj.NumChannels);
            obj.OldLineProperties = obj.LineProperties;
        end
        
        function resetLegend(obj)
            % Reset Legend to empty
            obj.Legend = matlab.hwmgr.scopes.Legend.empty();
        end
    end
    
    
    % getters and setters
    methods
        % DebugLevel set
        function set.DebugLevel(obj, value)
            obj.BasicScopeImplementation.setDebugLevel(value);
        end
        function value = get.DebugLevel(obj)
            value = obj.BasicScopeImplementation.getDebugLevel();
        end
        
        % NumChannels set
        function set.NumChannels(obj, value)
            obj.release();
            obj.MessageHandler.NumberOfChannels = value;
            obj.resetLines();
            obj.resetLegend();
            obj.YAxesInfo = repmat(matlab.hwmgr.scopes.YAxisInfo(), 1, obj.NumChannels);
        end
        function value = get.NumChannels(obj)
            value = obj.MessageHandler.NumberOfChannels;
        end
        
        % Offset set/get
        function set.Offset(obj, value)
            obj.release();
            obj.BasicScopeImplementation.Offset = value;
        end
        function value = get.Offset(obj)
            value = obj.BasicScopeImplementation.Offset;
        end
        
        % StepSize set/get
        function set.StepSize(obj, value)
            obj.release();
            obj.BasicScopeImplementation.SampleTime = value;
        end
        function value = get.StepSize(obj)
            value = obj.BasicScopeImplementation.SampleTime;
        end
        
        % LineProperties set/get
        function set.LineProperties(obj, value)
            if length (value) ~= obj.NumChannels
                msgID = 'hwmanagerapp:scopes:LinePropertiesPropertyLength';
                error(message(msgID));
            end
            obj.MessageHandler.LineProperties = value;
            obj.handleLinePropertiesChange();
        end
        function value = get.LineProperties(obj)
            value = obj.MessageHandler.LineProperties;
        end
        
        % Legend set
        function set.Legend(obj, value)
            obj.Legend = value;
            obj.handleLegendChange();
        end
        
        % PlotType set/get
        function set.PlotType(obj, value)
            obj.MessageHandler.PlotType = lower(value);
        end
        function value = get.PlotType(obj)
            value = obj.MessageHandler.PlotType;
            value = string(value);
        end
        
        % getters and setters for visual properties
        
        % XScale set/get
        function set.XScale(obj,value)
            obj.MessageHandler.XScale = lower(value);
        end
        function value = get.XScale(obj)
            value = obj.MessageHandler.XScale;
        end
        
        % YScale set/get
        function set.YScale(obj,value)
            obj.MessageHandler.YScale = lower(value);
        end
        function value = get.YScale(obj)
            value = obj.MessageHandler.YScale;
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
            obj.MessageHandler.XLimits = value;
        end
        function value = get.XLimits(obj)
            value = obj.MessageHandler.XLimits;
        end
        
        % YLimits set/get
        function set.YLimits(obj, value)
            obj.MessageHandler.YLimits = value;
            obj.YLimMode = "manual";
        end
        function value = get.YLimits(obj)
            value = obj.MessageHandler.YLimits;
        end
        
        % YLimits set/get
        function set.YLimMode(obj, value)
            obj.MessageHandler.YLimMode = lower(value);
        end
        function value = get.YLimMode(obj)
            value = obj.MessageHandler.YLimMode;
        end
        
        % Grid set/get
        function set.Grid(obj, value)
            obj.MessageHandler.Grid = lower(value);
        end
        function value = get.Grid(obj)
            value = obj.MessageHandler.Grid;
        end
        
        % ColorTheme set/get
        function set.ColorTheme(obj, value)
            obj.MessageHandler.ColorTheme = lower(value);
        end
        function value = get.ColorTheme(obj)
            value = obj.MessageHandler.ColorTheme;
        end

        % MultipleYAxis set/get
        function set.MultipleYAxis(obj, value)
            if isequal(obj.MessageHandler.MultipleYAxis, value)
                % No change to current value
                return
            end

            obj.MessageHandler.MultipleYAxis = lower(value);

            obj.updateChannelPropertyToParent();
        end

        function value = get.MultipleYAxis(obj)
            value = obj.MessageHandler.MultipleYAxis;
        end
    end

    methods
        function set.YAxesInfo(obj, value)
            if length (value) ~= obj.NumChannels
                msgID = 'hwmanagerapp:scopes:YAxesPropertyLength';
                error(message(msgID));
            end
            obj.MessageHandler.YAxesInfo = value;
            obj.updateChannelPropertyToParent();
        end
        function value = get.YAxesInfo(obj)
            value = obj.MessageHandler.YAxesInfo;
        end

        function updateChannelPropertyToParent(obj)
            % This function runs when MultipleYAxis is "on" . It also runs when
            % updating the YAxesInfo. It sends the values in YAxesInfo to the
            % JS side to be used in the scope's axes
            if (obj.MultipleYAxis ~= 1 || ~obj.LinesCreated)
                return
            end
            for key = 1:length(obj.YAxesInfo)
                yAxisInfo = obj.YAxesInfo(key);
                % JS indexing
                msg.identifier = key - 1;
                % Send over YLabel
                msg.property = "YLabel";
                msg.value = yAxisInfo.YLabel;
                obj.MessageHandler.setChannelProperty(msg);
                if yAxisInfo.YLimMode == "manual"
                    % Send over YLimits if manual YLimMode
                    msg.property = "YLimits";
                    msg.value = yAxisInfo.YLimits;
                    obj.MessageHandler.setChannelProperty(msg);
                else
                    % Notify YLimMode is auto so that the YLimits can be
                    % calculated
                    msg.property = "YLimMode";
                    msg.value = yAxisInfo.YLimMode;
                    obj.MessageHandler.setChannelProperty(msg);
                end
                % Send over YScale
                msg.property = "YScale";
                msg.value = yAxisInfo.YScale;
                obj.MessageHandler.setChannelProperty(msg);
            end
        end
    end
end
