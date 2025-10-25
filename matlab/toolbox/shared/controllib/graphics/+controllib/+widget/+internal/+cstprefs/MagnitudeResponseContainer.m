classdef (ConstructOnLoad) MagnitudeResponseContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "MagnitudeResponseContainer": 
    % Widget that is used to set minimum gain for the magnitude response.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.MagnitudeResponseContainer(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   MinGainLimit:
    %       Set or get the minimum gain limit for the magnitude response
    %       plots. 
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        Label
    end
    
    properties(Dependent,SetObservable,AbortSet)
        MinGainLimit
        MagnitudeUnits
    end
    
    properties (Access = private)
        MinGainLimitCheckBox
        MinGainLimitEditField
        MinGainLimitInternal
        MagnitudeUnitsInternal
        UpdateWidget = true
        WidgetTags = struct(...
                        'MinGainLimitCheckBox','MinGainLimitCheckBox',...
                        'MinGainLimitEditField','MinGainLimitEditField',...
                        'TitleLabel','MinGainTitleLabel');
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    events
        ValueChanged
    end
    
    methods
        function this = MagnitudeResponseContainer()
            this.Label = m('Controllib:gui:strMinGainLabel');
            toolboxPreferences = cstprefs.tbxprefs;
            this.MinGainLimit = toolboxPreferences.MinGainLimit;
            this.MagnitudeUnitsInternal = toolboxPreferences.MagnitudeUnits;
            this.ContainerTitle = m('Controllib:gui:strMagnitudeResponse');
        end
        
        function MinGainLimit = get.MinGainLimit(this)
            MinGainLimit = this.MinGainLimitInternal;
        end
        
        function set.MinGainLimit(this,MinGainLimit)
            validatestring(MinGainLimit.Enable,{'on','off'});
            if ~isempty(this.MinGainLimitCheckBox) && isvalid(this.MinGainLimitCheckBox) && ...
                    this.UpdateWidget
                this.MinGainLimitCheckBox.Value = strcmp(MinGainLimit.Enable,'on');
                this.MinGainLimitEditField.Enable = MinGainLimit.Enable;
                this.MinGainLimitEditField.Value = MinGainLimit.MinGain;
            end
            this.MinGainLimitInternal = MinGainLimit;
        end
        
        function MagnitudeUnits = get.MagnitudeUnits(this)
            MagnitudeUnits = this.MagnitudeUnitsInternal;
        end
        
        function set.MagnitudeUnits(this,MagnitudeUnits)
            validatestring(MagnitudeUnits,{'abs','dB'});
            switch MagnitudeUnits
                case 'abs'
                    this.MinGainLimitEditField.Limits = [0 Inf];
                    this.MinGainLimit.MinGain = db2mag(this.MinGainLimit.MinGain);
                case 'dB'
                    this.MinGainLimitEditField.Limits = [-Inf Inf];
                    this.MinGainLimit.MinGain = mag2db(this.MinGainLimit.MinGain);
            end
            this.MagnitudeUnitsInternal = MagnitudeUnits;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit'},'ColumnWidth',{'fit','1x'},...
                'Scrollable',"off");
            widget.Padding = 0;
            % CheckBox
            this.MinGainLimitCheckBox = uicheckbox(widget,'Text',this.Label);
            this.MinGainLimitCheckBox.Value = strcmp(this.MinGainLimitInternal.Enable,'on');
            this.MinGainLimitCheckBox.ValueChangedFcn = ...
                @(es,ed) callbackCheckBoxValueChangedFcn(this,es,ed);
            this.MinGainLimitEditField = uieditfield(widget,'numeric');
            if strcmp(this.MagnitudeUnits,'dB')
                this.MinGainLimitEditField.Limits = [-Inf Inf];
            else
                this.MinGainLimitEditField.Limits = [0 Inf];
            end
            this.MinGainLimitEditField.UpperLimitInclusive = 'off';
            this.MinGainLimitEditField.Enable = this.MinGainLimit.Enable;
            this.MinGainLimitEditField.Value = this.MinGainLimitInternal.MinGain;
            this.MinGainLimitEditField.ValueChangedFcn = ...
                @(es,ed) callbackEditFieldValueChangedFcn(this,es,ed);
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
        
        function callbackCheckBoxValueChangedFcn(this,es,ed)
            if ed.Value
                this.MinGainLimit.Enable = 'on';
            else
                this.MinGainLimit.Enable = 'off';
            end
        end
        
        function callbackEditFieldValueChangedFcn(this,es,ed)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            this.MinGainLimit.MinGain = ed.Value;
            this.UpdateWidget = updateWidgetFlag;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.MinGainCheckBox = this.MinGainLimitCheckBox;
            widgets.MinGainEditField = this.MinGainLimitEditField;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
