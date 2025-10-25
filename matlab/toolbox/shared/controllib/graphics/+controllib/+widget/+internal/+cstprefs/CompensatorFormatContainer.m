classdef (ConstructOnLoad) CompensatorFormatContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "CompensatorFormatContainer":
    % Widget that is used to specify the compensator format for display in
    % the Control System Designer. 
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.CompensatorFormatContainer();
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties (set or get the preferences for the following)
    %   Value
    %       Set or get the compensator format value. 'TimeConstant1',
    %       'TimeConstant2' or 'ZeroPoleGain'
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        Label
    end
    
    properties(Dependent,SetObservable,AbortSet)
        Value
    end
    
    properties (Access = private)
        ButtonGroup
        TimeConstantRadioButton
        NaturalFrequencyRadioButton
        ZPKRadioButton
        ValueInternal
        ButtonWidth = 300
        UpdateWidget = true
        WidgetTags = struct(...
                        'ButtonGroup','CompensatorFormatButtonGroup',...
                        'TimeConstantRadioButton','CompensatorFormatTimeConstantButton',...
                        'NaturalFrequencyRadioButton','CompensatorFormatNaturalFrequencyButton',...
                        'ZPKRadioButton','CompensatorFormatZPKRadioButton');
                        
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = CompensatorFormatContainer()
            toolboxPreferences = cstprefs.tbxprefs;
            this.Value = toolboxPreferences.CompensatorFormat;
            this.ContainerTitle = m('Controllib:gui:strCompensatorFormat');
        end
        
        function Value = get.Value(this)
            Value = this.ValueInternal;
        end
        
        function set.Value(this,Value)
            validatestring(Value,{'TimeConstant1','TimeConstant2','ZeroPoleGain'});
            localSetButtonValue(this,Value);
            this.ValueInternal = Value;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{90},'ColumnWidth',{this.ButtonWidth},...
                'Scrollable',"off");
            widget.Padding = 0;
            % Buttons
            this.ButtonGroup = uibuttongroup(widget);
            this.ButtonGroup.Layout.Row = 1;
            this.ButtonGroup.Layout.Column = 1;
            this.ButtonGroup.SelectionChangedFcn = @(es,ed) callbackSelectionChangedFcn(this,es,ed);
            this.ButtonGroup.BorderType = 'none';
            this.TimeConstantRadioButton = uiradiobutton(this.ButtonGroup,'Text',...
                                            [m('Controllib:gui:strTimeConstantLabel'),...
                                            '         DC x (1 + Tz s) / (1 + Tp s)']);
            this.TimeConstantRadioButton.Position = [2 70 this.ButtonWidth 20];
            this.NaturalFrequencyRadioButton = uiradiobutton(this.ButtonGroup,'Text',...
                                            [m('Controllib:gui:strNaturalFrequencyLabel'),...
                                            '   DC x (1 + s/wz) / (1 + s/wp)']);
            this.NaturalFrequencyRadioButton.Position = [2 40 this.ButtonWidth 20]; 
            this.ZPKRadioButton = uiradiobutton(this.ButtonGroup,'Text',...
                                            [m('Controllib:gui:strZPKLabel'),...
                                            '         K x (s + z) / (s + p)']);
            this.ZPKRadioButton.Position = [2 10 this.ButtonWidth 20];
            localSetButtonValue(this,this.ValueInternal);
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
        
        function callbackSelectionChangedFcn(this,es,ed)
            switch ed.NewValue
                case this.TimeConstantRadioButton
                    this.ValueInternal = 'TimeConstant1';
                case this.NaturalFrequencyRadioButton
                    this.ValueInternal = 'TimeConstant2';
                case this.ZPKRadioButton
                    this.ValueInternal = 'ZeroPoleGain';
            end
        end
        
        function localSetButtonValue(this,value)
            switch value
                case 'TimeConstant1'
                    this.TimeConstantRadioButton.Value = true;
                case 'TimeConstant2'
                    this.NaturalFrequencyRadioButton.Value = true;
                case 'ZeroPoleGain'
                    this.ZPKRadioButton.Value = true;
            end
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.ButtonGroup = this.ButtonGroup;
            widgets.TimeConstantButton = this.TimeConstantRadioButton;
            widgets.NaturalFrequencyButton = this.NaturalFrequencyRadioButton;
            widgets.ZPKButton = this.ZPKRadioButton;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
