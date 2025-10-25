classdef (ConstructOnLoad) GridContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "GridContainer":
    % Widget that contains a checkbox to turn the grid setting on/off.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.GridContainer(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   Value:
    %       Show or hide the gridlines in a plot. Accepted values are 'on'
    %       or 'off'. 
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Dependent,SetObservable,AbortSet)
        Value
    end
    
    properties (Access = private)
        GridCheckBox
        ValueInternal
        UpdateWidget = true
        WidgetTags = struct(...
                        'TitleLabel','GridTitleLabel',...
                        'GridCheckBox','GridCheckBox');
                        
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = GridContainer()
            toolboxPreferences = cstprefs.tbxprefs;
            this.Value = toolboxPreferences.Grid;
            this.ContainerTitle = m('Controllib:gui:strGrids');
        end
        
        function Value = get.Value(this)
            Value = this.ValueInternal;
        end
        
        function set.Value(this,Value)
            arguments
                this
                Value matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.GridCheckBox) && isvalid(this.GridCheckBox) ...
                    && this.UpdateWidget
                this.GridCheckBox.Value = strcmp(Value,'on');
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
            this.GridCheckBox = uicheckbox(widget,'Text',m('Controllib:gui:strShowGridsLabel'));
            this.GridCheckBox.Value = strcmp(this.ValueInternal,'on');
            this.GridCheckBox.ValueChangedFcn = @(es,ed) callbackValueChangedFcn(this,es,ed);
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
            widgets.CheckBox = this.GridCheckBox;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
