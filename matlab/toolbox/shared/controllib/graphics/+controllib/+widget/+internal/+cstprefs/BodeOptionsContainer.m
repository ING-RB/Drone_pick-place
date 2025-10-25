classdef (ConstructOnLoad) BodeOptionsContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "BodeOptionsContainer":
    % Widget that is used to bode editor options in Control System
    % Designer.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.BodeOptionsContainer();
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties (set or get the preferences for the following)
    %   Value:
    %       Show or hide the plant and sensor poles and zeros on the bode
    %       editor. 'on' or 'off'.
    
    % Copyright 2020 The MathWorks, Inc.
    properties(Dependent,SetObservable,AbortSet)
        Value
    end
    
    properties (Access = private)
        PoleZeroCheckBox
        ValueInternal
        UpdateWidget = true
        WidgetTags = struct(...
                        'TitleLabel','BodeOptionsTitleLabel',...
                        'PoleZeroCheckBox','PoleZeroCheckBox');
                        
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = BodeOptionsContainer()
            toolboxPreferences = cstprefs.tbxprefs;
            this.Value = toolboxPreferences.ShowSystemPZ;
            this.ContainerTitle = m('Controllib:gui:strBodeOptions');
        end
        
        function Value = get.Value(this)
            Value = this.ValueInternal;
        end
        
        function set.Value(this,Value)
            validatestring(Value,{'on','off'});
            if ~isempty(this.PoleZeroCheckBox) && isvalid(this.PoleZeroCheckBox) ...
                    && this.UpdateWidget
                this.PoleZeroCheckBox.Value = strcmp(Value,'on');
            end
            this.ValueInternal = Value;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit'},'ColumnWidth',{'1x'},...
                'Scrollable',"off");
            widget.Padding = 0;
            % CheckBox
            this.PoleZeroCheckBox = uicheckbox(widget,'Text',m('Controllib:gui:strShowPlantPolesZeros'));
            this.PoleZeroCheckBox.Value = strcmp(this.ValueInternal,'on');
            this.PoleZeroCheckBox.ValueChangedFcn = @(es,ed) callbackValueChangedFcn(this,es,ed);
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
        
        function callbackValueChangedFcn(this,es,ed)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            if ed.Value
                this.Value = 'on';
            else
                this.Value = 'off';
            end
            this.UpdateWidget = updateWidgetFlag;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.CheckBox = this.PoleZeroCheckBox;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
