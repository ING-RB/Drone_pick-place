classdef (Sealed) EventOptions < matlab.ui.componentcontainer.ComponentContainer
    % EventOptions: A set controls for selecting the options in the
    % odeEvent class. The event function is chosen with a FunctionSelector,
    % and the remaining options are selected from controls that are in a
    % popout which is accessible from an icon. For use in SolveODETask.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access=public,Dependent)
        State
        Enable
    end

    properties (Hidden,Transient)
        % Main controls in this component
        EventfunSelector         matlab.internal.dataui.FunctionSelector
        Icon                     matlab.ui.control.Image
        Popout                   matlab.ui.container.internal.Popout
        % Controls inside the popout
        PopoutGrid               matlab.ui.container.GridLayout
        PopoutHeaderIcon         matlab.ui.control.Image
        DirectionDD              matlab.ui.control.DropDown
        ResponseDD               matlab.ui.control.DropDown
        CallbackLabel            matlab.ui.control.Label
        CallbackSelector         matlab.internal.dataui.FunctionSelector
    end

    properties (Hidden,Constant)
        TextRowHeight = 22;
        PopoutWidth = 255;
        IconWidth = 16;
        DefaultEventfunState = struct("FcnType",'local',...
            "LocalValue",'select variable',...
            "HandleValue",'@(t,y) y(1)',...
            "BrowseValue",'');
        DefaultCallbackState = struct("FcnType",'local',...
            "LocalValue",'select variable',...
            "HandleValue",'@(t,y) disp(t)',...
            "BrowseValue",'');
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Method needed by the ComponentContainer constructor
            % Lay out the contents of the control

            % Usually this will be put in a GridLayout. For testing, set a
            % reasonable initial position within a UIFigure.
            obj.Position = [100 100 300 25];

            % Create EventfunSelector and Icon in grid. Then create Popout
            % to be targeted to the Icon
            g = uigridlayout(obj,...
                RowHeight = obj.TextRowHeight,...
                ColumnWidth = {"1x" obj.TextRowHeight},...
                Padding = 0);
            obj.EventfunSelector = matlab.internal.dataui.FunctionSelector(...
                Parent = g,...
                AllowEmpty = true,...
                IncludeBrowse = true,...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tag = "EventfunSelector",...
                AutoArrangeGrid = false,...
                Tooltip = getMsgText("EventfunTooltip"));
            obj.EventfunSelector.GridLayout.ColumnWidth{1} = 120;
            obj.EventfunSelector.GridLayout.ColumnWidth{2} = "1x";
            obj.Icon = uiimage(g, ScaleMethod = "none",...
                ImageClickedFcn = @donothing,...
                Tooltip = getMsgText("IconTooltip"));
            matlab.ui.control.internal.specifyIconID(obj.Icon,...
                "meatballMenuUI",obj.IconWidth,obj.IconWidth);
            obj.Popout = matlab.ui.container.internal.Popout(Trigger = "click");
            obj.Popout.Position = [0 0 obj.PopoutWidth+10 (3*obj.TextRowHeight + 20)];
            % Don't set the Target as the icon until after the icon is
            % visible in the figure

            % The remaining controls are inside the popout
            obj.PopoutGrid = uigridlayout(Parent = [],...
                RowHeight = repmat(obj.TextRowHeight,1,5),...
                ColumnWidth = {obj.IconWidth 90-obj.IconWidth obj.PopoutWidth-95},...
                Padding = 5,...
                ColumnSpacing = 5,...
                RowSpacing = 5);
            % Help button to link to odeEvent doc
            obj.PopoutHeaderIcon = uiimage(obj.PopoutGrid,...
                ImageClickedFcn = @(~,~)helpview("matlab","ODELET_Events"),...
                ScaleMethod = "fill", ...
                Tooltip = getMsgText("HelpTooltip"));
            matlab.ui.control.internal.specifyIconID(obj.PopoutHeaderIcon,...
                "helpMonoUI",obj.IconWidth,obj.IconWidth);
            % Title of popout
            headerLabel = uilabel(obj.PopoutGrid,...
                Text = getMsgText("Title"),...
                FontWeight="bold");
            headerLabel.Layout.Column = [2 3];
            % Lay out controls with corresponding labels
            L = uilabel(obj.PopoutGrid,...
                Text = getMsgText("Direction"));
            L.Layout.Column = [1 2];
            obj.DirectionDD = uidropdown(obj.PopoutGrid,...
                Items = [getMsgText("Both") getMsgText("Ascending") getMsgText("Descending")],...
                ItemsData = ["both" "ascending" "descending"],...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tooltip = getMsgText("DirectionTooltip"));
            L = uilabel(obj.PopoutGrid,...
                Text = getMsgText("Response"));
            L.Layout.Column = [1 2];
            obj.ResponseDD = uidropdown(obj.PopoutGrid,...
                Items = [getMsgText("Proceed") getMsgText("Stop") getMsgText("Callback")],...
                ItemsData = ["proceed" "stop" "callback"],...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tooltip = getMsgText("ResponseTooltip"));
            obj.CallbackSelector = matlab.internal.dataui.FunctionSelector(obj.PopoutGrid,...
                IncludeBrowse = true,...
                AllowEmpty = true,...
                ValueChangedFcn = @obj.notifyValueChanged,...
                AutoArrangeGrid = false,...
                Tooltip = getMsgText("CallbackTooltip"));
            % Selector text is dynamically set by caller
            obj.CallbackSelector.Layout.Column = [1 3];
            obj.CallbackSelector.Layout.Row = [4 5];
            % Rearrange elements of the FunctionSelector to fit into popout
            obj.CallbackSelector.GridLayout.ColumnSpacing = 5;
            obj.CallbackSelector.GridLayout.RowSpacing = 5;
            obj.CallbackSelector.GridLayout.ColumnWidth = {95 "1x" "fit" "fit"};
            obj.CallbackSelector.GridLayout.RowHeight = [obj.TextRowHeight obj.TextRowHeight];
            obj.CallbackSelector.FcnTypeDropDown.Layout.Column = [2 4];
            obj.CallbackSelector.LocalFcnDropDown.Layout.Column = [1 3];
            obj.CallbackSelector.LocalFcnDropDown.Layout.Row = 2;
            obj.CallbackSelector.NewFcnButton.Layout.Column = 4;
            obj.CallbackSelector.NewFcnButton.Layout.Row = 2;
            obj.CallbackSelector.BrowseEditField.Layout.Column = [1 2];
            obj.CallbackSelector.BrowseEditField.Layout.Row = 2;
            obj.CallbackSelector.BrowseButton.Layout.Column = 3;
            obj.CallbackSelector.BrowseButton.Layout.Row = 2;
            obj.CallbackSelector.HandleEditField.Layout.Column = [1 4];
            obj.CallbackSelector.HandleEditField.Layout.Row = 2;
            % create label after Selector so it isn't covered up
            obj.CallbackLabel = uilabel(obj.PopoutGrid,...
                Text = getMsgText("CallbackLabel"));
            obj.CallbackLabel.Layout.Column = [1 2];
            obj.CallbackLabel.Layout.Row = 4;

            obj.PopoutGrid.Parent = obj.Popout;
            
        end

        function update(obj)
            % Method required by ComponentContainer
            % Called when properties of the component are updated

            % Prevent the popout from being parented to the uifigure at
            % initial construction (live task constructor complains)
            if ~obj.Visible
                obj.Popout.Target = [];
            else
                obj.Popout.Target = obj.Icon;
            end
            % Callback selector only needs to be visible when the response
            % is 'callback'
            showCallback = isequal(obj.ResponseDD.Value,"callback");
            obj.CallbackSelector.Visible = showCallback;
            obj.CallbackLabel.Visible = showCallback;
            % Adjust the height of the popout accordingly
            numrows = 3 + 2*showCallback;
            obj.Popout.Position(4) = numrows*obj.TextRowHeight + 5*(numrows+1);
        end
    end

    methods (Access=private)
        function notifyValueChanged(obj,src,~)
            % callback for components within the popout
            update(obj);
            if isequal(src.Tag,"EventfunSelector") && ~isempty(obj.EventfunSelector.Value)
                % Auto open popout when user defines EventDefinition fun
                open(obj.Popout);
            end
            notify(obj,'ValueChanged');
        end
    end

    methods % public gets and sets
        function reset(obj)
            % restores default values
            obj.EventfunSelector.resetToDefault();
            obj.DirectionDD.Value = "both";
            obj.ResponseDD.Value = "proceed";
            obj.CallbackSelector.resetToDefault();
        end

        function s = get.State(obj)
            % Store only as much info as we need to restore the component
            % in the save/load workflow. Non-default values do not need to
            % be stored.
            s = struct();
            if ~isequal(obj.EventfunSelector.State,obj.DefaultEventfunState)
                s.EventfunSelectorState = obj.EventfunSelector.State;
            end
            if ~isequal(obj.CallbackSelector.State,obj.DefaultCallbackState)
                s.CallbackSelectorState = obj.CallbackSelector.State;
            end
            if ~isequal(obj.DirectionDD.Value,"both")
                s.DirectionDDValue = obj.DirectionDD.Value;
            end
            if ~isequal(obj.ResponseDD.Value,"proceed")
                s.ResponseDDValue = obj.ResponseDD.Value;
            end
        end

        function set.State(obj,s)
            % State struct is used for serialization
            if isfield(s,"EventfunSelectorState")
                obj.EventfunSelector.State = s.EventfunSelectorState;
            else
                obj.EventfunSelector.State = obj.DefaultEventfunState;
            end
            if isfield(s,"CallbackSelectorState")
                obj.CallbackSelector.State = s.CallbackSelectorState;
            else
                obj.CallbackSelector.State = obj.DefaultCallbackState;
            end
            if isfield(s,"DirectionDDValue")
                obj.DirectionDD.Value = s.DirectionDDValue;
            else
                obj.DirectionDD.Value = "both";
            end
            if isfield(s,"ResponseDDValue")
                obj.ResponseDD.Value = s.ResponseDDValue;
            else
                obj.ResponseDD.Value = "proceed";
            end
        end

        function onoff = get.Enable(obj)
            onoff = obj.DirectionDD.Enable;
        end

        function set.Enable(obj,onoff)
            obj.EventfunSelector.Enable = onoff;
            obj.DirectionDD.Enable = onoff;
            obj.ResponseDD.Enable = onoff;
            obj.CallbackSelector.Enable = onoff;
        end

        function str = getValue(obj,isInternal)
            % Return string to be used for code generation
            evFun = obj.EventfunSelector.Value;
            if isempty(evFun)
                str = '';
                return
            end            
            NVvals = '';
            if ~isequal(obj.DirectionDD.Value,"both")
                NVvals = NVvals + ", Direction = """ + obj.DirectionDD.Value + """";
            end
            response = obj.ResponseDD.Value;
            if ~isequal(response,"proceed")
                NVvals = NVvals + ", Response = """ + response + """";
            end
            doCallback = isequal(response,"callback") && ~isempty(obj.CallbackSelector.Value);
            if isInternal
                % Code generated is to be used internally by the live task
                % to determine auto-selected solver. In this case we do not
                % have access to local functions in the script where the
                % live task is embedded. So for any function inputs, we use
                % a dummy function with the expected syntax.
                evFun = "@(t,y) y";
                if doCallback
                    NVvals = NVvals + ", CallbackFcn = @(t,y) y";
                end
            elseif doCallback
                NVvals = NVvals + ", CallbackFcn = " + obj.CallbackSelector.Value;
            end
            if isempty(NVvals)
                % all default params, use syntax without 'odeEvent'
                str = evFun;
            else
                str = "odeEvent(EventFcn = " + evFun + NVvals + ")";
            end
        end
    end
end

function str = getMsgText(id)
str = string(message("MATLAB:mathui:EventOptions" + id));
end

function donothing(~,~)
% Need this callback to make the pointer change on hovering over icon
end