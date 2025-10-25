classdef (ConstructOnLoad) ConfidenceRegionContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "ConfidenceRegionContainer": 
    % Widget that is used to set confidence region options for identified models.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.ConfidenceRegionContainer(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   StandardDeviation:
    %       Set or get the number of standard deviations for display.
    %
    %   ZeroMeanInterval
    %       Set or get option to display using zero mean interval.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        ShowStandardDeviationEditfield = true
        ShowZeroMeanCheckbox = false
    end
    
    properties(Dependent,SetObservable,AbortSet)
        ConfidenceNumSD
        ZeroMeanInterval
    end
    
    properties (Access = private)
        StandardDeviationLabel
        StandardDeviationEditfield
        ZeroMeanCheckbox
        
        ConfidenceNumSDInternal = 1;
        ZeroMeanIntervalInternal = false;
        UpdateWidget = true
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    events
        ValueChanged
    end
    
    methods
        function this = ConfidenceRegionContainer(optionalArguments)
            arguments
                optionalArguments.ShowStandardDeviationEditfield = true;
                optionalArguments.ShowZeroMeanCheckbox = false;
            end
            this.ShowStandardDeviationEditfield = optionalArguments.ShowStandardDeviationEditfield;
            this.ShowZeroMeanCheckbox = optionalArguments.ShowZeroMeanCheckbox;
            this.ContainerTitle = m('Controllib:gui:strConfidenceCharTitle');
        end
        
        function ConfidenceNumSD = get.ConfidenceNumSD(this)
            ConfidenceNumSD = this.ConfidenceNumSDInternal;
        end
        
        function set.ConfidenceNumSD(this,ConfidenceNumSD)
            if ~isempty(this.StandardDeviationEditfield) && ...
                    isvalid(this.StandardDeviationEditfield) && this.UpdateWidget
                this.StandardDeviationEditfield.Value = ConfidenceNumSD;
            end
            this.ConfidenceNumSDInternal = ConfidenceNumSD;
        end
        
        function ZeroMeanInterval = get.ZeroMeanInterval(this)
            ZeroMeanInterval = this.ZeroMeanIntervalInternal;
        end
        
        function set.ZeroMeanInterval(this,ZeroMeanInterval)
            if ~isempty(this.ZeroMeanCheckbox) && isvalid(this.ZeroMeanCheckbox) && ...
                    this.UpdateWidget
                this.ZeroMeanCheckbox.Value = ZeroMeanInterval;
            end
            this.ZeroMeanIntervalInternal = ZeroMeanInterval;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit'},'ColumnWidth',{'fit','1x'},...
                'Scrollable',"off");
            widget.Padding = 0;
            % Standard Deviation
            if this.ShowStandardDeviationEditfield
                this.StandardDeviationLabel = ...
                    uilabel(widget,'Text',m('Controllib:gui:strConfidenceNumSDLabel'));
                this.StandardDeviationLabel.Layout.Row = 1;
                this.StandardDeviationLabel.Layout.Column = 1;
                this.StandardDeviationEditfield = uieditfield(widget,'numeric');
                this.StandardDeviationEditfield.Layout.Row = 1;
                this.StandardDeviationEditfield.Layout.Column = 2;
                this.StandardDeviationEditfield.Value = this.ConfidenceNumSD;
                this.StandardDeviationEditfield.Limits = [0 Inf];
                this.StandardDeviationEditfield.UpperLimitInclusive = 'off';
                this.StandardDeviationEditfield.ValueChangedFcn = ...
                    @(es,ed) cbStandDeviationValueChanged(this,es,ed);
            end
            % Zero Mean Interval
            if this.ShowZeroMeanCheckbox
                this.ZeroMeanCheckbox = ...
                    uicheckbox(widget,'Text',m('Controllib:gui:strConfidenceDiplayZeroIntervalLabel'));
                this.ZeroMeanCheckbox.Value = this.ZeroMeanInterval;
                this.ZeroMeanCheckbox.ValueChangedFcn = ...
                    @(es,ed) cbUseZeroMeanValueChanged(this,es,ed);
            end
            % Add Tags
            if this.AddTagsToWidgets
                addTags(this);
            end
        end
    end
    
    methods (Access = private)
        function addTags(this)
            if this.ShowStandardDeviationEditfield
                this.StandardDeviationEditfield.Tag = 'StandardDeviationEditfield';
            end
            
            if this.ShowZeroMeanCheckbox
                this.ZeroMeanCheckbox.Tag = 'ZeroMeanCheckbox';
            end
        end
        
        function cbStandDeviationValueChanged(this,es,ed)
            this.ConfidenceNumSD = ed.Value;
        end
        
        function cbUseZeroMeanValueChanged(this,es,ed)
            this.ZeroMeanInterval = ed.Value;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.StandardDeviationEditfield = this.StandardDeviationEditfield;
            widgets.ZeroMeanCheckbox = this.ZeroMeanCheckbox;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
