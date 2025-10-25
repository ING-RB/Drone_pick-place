classdef (ConstructOnLoad) TimeResponseContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "TimeResponseContainer":
    % Widget that is used to specify settings for time response
    % characteristics.
    %
    % To use container in a dialog/panel:
    %
    %   c = controllib.widget.internal.cstprefs.TimeResponseContainer();
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties
    %   SettlingTimeThreshold:
    %       Set or get the threshold for computing the settling time in
    %       time response plots.
    %   RiseTimeLimits:
    %       Set or get the minimum and maximum values for computing the
    %       rise time in time response plots.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        SettlingTimeLabel
        RiseTimeLabel
    end
    
    properties(Dependent,SetObservable,AbortSet)
        SettlingTimeThreshold
        RiseTimeLimits
    end
    
    properties (Access = private)
        ShowSettlingTime = true
        ShowRiseTime = true
        SettlingTimeThresholdEditField
        RiseTimeLimitsMinEditField
        RiseTimeLimitsMaxEditField
        SettlingTimeThresholdInternal
        RiseTimeLimitsInternal
        UpdateWidget = true
        WidgetTags = struct(...
            'SettlingTimeThresholdEditField','SettlingTimeThresholdEditField',...
            'RiseTimeLimitsMinEditField','RiseTimeLimitsMinEditField',...
            'RiseTimeLimitsMaxEditField','RiseTimeLimitsMaxEditField');
    end
    
    properties
        AddTagsToWidgets = true
    end
    
    methods
        function this = TimeResponseContainer(optionalArguments)
            arguments
                optionalArguments.ShowSettlingTime = true;
                optionalArguments.ShowRiseTime = true;
            end
            this.ShowSettlingTime = optionalArguments.ShowSettlingTime;
            this.ShowRiseTime = optionalArguments.ShowRiseTime;
            this.SettlingTimeLabel = m('Controllib:gui:strShowSettlingTimeLabel');
            this.RiseTimeLabel = m('Controllib:gui:strShowRiseTimeLabel');
            toolboxPreferences = cstprefs.tbxprefs;
            this.SettlingTimeThreshold = toolboxPreferences.SettlingTimeThreshold;
            this.RiseTimeLimits = toolboxPreferences.RiseTimeLimits;
            this.ContainerTitle = m('Controllib:gui:strTimeResponse');
        end
        
        % SettlingTimeThreshold
        function SettlingTimeThreshold = get.SettlingTimeThreshold(this)
            SettlingTimeThreshold = this.SettlingTimeThresholdInternal;
        end
        
        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            if ~isempty(this.SettlingTimeThresholdEditField) && ...
                    isvalid(this.SettlingTimeThresholdEditField) && this.UpdateWidget
                this.SettlingTimeThresholdEditField.Value = 100*SettlingTimeThreshold;
            end
            this.SettlingTimeThresholdInternal = SettlingTimeThreshold;
        end
        
        % RiseTimeLimits
        function RiseTimeLimits = get.RiseTimeLimits(this)
            RiseTimeLimits = this.RiseTimeLimitsInternal;
        end
        
        function set.RiseTimeLimits(this,RiseTimeLimits)
            if ~isempty(this.RiseTimeLimitsMinEditField) && ...
                    isvalid(this.RiseTimeLimitsMinEditField) && this.UpdateWidget
                this.RiseTimeLimitsMinEditField.Value = 100*RiseTimeLimits(1);
                this.RiseTimeLimitsMaxEditField.Value = 100*RiseTimeLimits(2);
            end
            this.RiseTimeLimitsInternal = RiseTimeLimits;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit','fit'},'ColumnWidth',{'1x'},...
                'Scrollable',"off");
            widget.Padding = 0;
            % CheckBox
            if this.ShowSettlingTime
                gridLayout = uigridlayout(widget,'RowHeight',{'1x'},...
                    'ColumnWidth',{'fit',30,'fit'},...
                    'Scrollable',"on");
                gridLayout.Padding = 0;
                label = uilabel(gridLayout,'Text',this.SettlingTimeLabel);
                this.SettlingTimeThresholdEditField = uieditfield(gridLayout,'numeric');
                this.SettlingTimeThresholdEditField.Limits = [0 100];
                this.SettlingTimeThresholdEditField.Value = 100*this.SettlingTimeThreshold;
                this.SettlingTimeThresholdEditField.ValueChangedFcn = ...
                    @(es,ed) callbackSettlingTimeThresholdValueChanged(this,es,ed);
                label = uilabel(gridLayout,'Text','%');
            end
            if this.ShowRiseTime
                gridLayout = uigridlayout(widget,'RowHeight',{'1x'},...
                    'ColumnWidth',{'fit',30,'fit',30,'fit'},...
                    'Scrollable',"on");
                gridLayout.Padding = 0;
                label = uilabel(gridLayout,'Text',this.RiseTimeLabel);
                this.RiseTimeLimitsMinEditField = uieditfield(gridLayout,'numeric');
                this.RiseTimeLimitsMinEditField.Limits = [0 100];
                this.RiseTimeLimitsMinEditField.Value = 100*this.RiseTimeLimits(1);
                this.RiseTimeLimitsMinEditField.ValueChangedFcn = ...
                    @(es,ed) callbackRiseTimeMinValueChanged(this,es,ed);
                label = uilabel(gridLayout,'Text',m('Controllib:gui:strTo'));
                this.RiseTimeLimitsMaxEditField = uieditfield(gridLayout,'numeric');
                this.RiseTimeLimitsMaxEditField.Limits = [0 100];
                this.RiseTimeLimitsMaxEditField.Value = 100*this.RiseTimeLimits(2);
                this.RiseTimeLimitsMaxEditField.ValueChangedFcn = ...
                    @(es,ed) callbackRiseTimeMaxValueChanged(this,es,ed);
                label = uilabel(gridLayout,'Text','%');
            end
            
            % Add Tags
            if this.AddTagsToWidgets
                addTags(this);
            end
        end
    end
    
    methods (Access = private)
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    this.(wn{1}).Tag = this.WidgetTags.(wn{1});
                end
            end
        end
        
        function callbackSettlingTimeThresholdValueChanged(this,es,ed)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            this.SettlingTimeThreshold = ed.Value/100;
            this.UpdateWidget = updateWidgetFlag;
        end
        
        function callbackRiseTimeMinValueChanged(this,es,ed)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            this.RiseTimeLimits(1) = ed.Value/100;
            this.UpdateWidget = updateWidgetFlag;
        end
        
        function callbackRiseTimeMaxValueChanged(this,es,ed)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            this.RiseTimeLimits(2) = ed.Value/100;
            this.UpdateWidget = updateWidgetFlag;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.SettlingTimeEditField = this.SettlingTimeThresholdEditField;
            widgets.RiseTimeMinEditField = this.RiseTimeLimitsMinEditField;
            widgets.RiseTimeMaxEditField = this.RiseTimeLimitsMaxEditField;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
