classdef (ConstructOnLoad) ColorContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "ColorContainer":
    % Widget that is used to set the axes foreground color.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.ColorContainer(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   Value:
    %       Set or get the color triplet ([R G B]) for the axes foreground. 
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        Label
    end
    
    properties(Dependent,SetObservable,AbortSet)
        Value
    end
    
    properties (Access = private)
        TextLabel
        EditField
        Button
        ValueInternal
        UpdateWidget = true
        WidgetTags = struct(...
                'TitleLabel','ColorTitleLabel',...
                'TextLabel','ColorTextLabel',...
                'EditField','ColorEditField',...
                'Button','ColorSelectButton');
    end
    
    properties(Hidden)
        AddTagToWidgets = true
    end
    
    methods
        function this = ColorContainer(varargin)
            this.Label = m('Controllib:gui:strAxesForegroundLabel');
            h = cstprefs.tbxprefs;
            this.ValueInternal = h.AxesForegroundColor;
            this.ContainerTitle = m('Controllib:gui:strColors');
        end
        
        function Value = get.Value(this)
            Value = this.ValueInternal;
        end
        
        function set.Value(this,Value)
            localValidate(Value);
            if ~isempty(this.EditField) && isvalid(this.EditField) && this.UpdateWidget
                this.EditField.Value = mat2str(Value,3);
            end            
            this.ValueInternal = Value;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit'},...
                                        'ColumnWidth',{'fit','1x','fit'},...
                                        'Scrollable',"off");
            widget.Padding = 0;
            % Label
            this.TextLabel = uilabel(widget);
            this.TextLabel.Layout.Row = 2;
            this.TextLabel.Layout.Column = 1;
            this.TextLabel.Text = this.Label;
            % EditField
            this.EditField = uieditfield(widget);
            this.EditField.Layout.Row = 2;
            this.EditField.Layout.Column = 2;
            this.EditField.Value = mat2str(this.Value,3);
            this.EditField.ValueChangedFcn = ...
                @(es,ed) callbackEditFieldValueChangedFcn(this,es,ed);
            % Button
            this.Button = uibutton(widget,'push');
            this.Button.Layout.Row = 2;
            this.Button.Layout.Column = 3;
            this.Button.Text = m('Controllib:gui:strSelectLabel');
            this.Button.ButtonPushedFcn = @(es,ed) callbackButtonPushedFcn(this,es,ed);
            % Add Tags
            if this.AddTagToWidgets
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
        
        function callbackEditFieldValueChangedFcn(this,es,ed)
            try
                numericValue = str2num(ed.Value);
                this.UpdateWidget = false;
                this.Value = numericValue;
                this.UpdateWidget = true;
            catch
                this.UpdateWidget = true;
                es.Value = mat2str(this.ValueInternal,3);
            end
        end
        
        function callbackButtonPushedFcn(this,es,ed)
            value = uisetcolor(this.ValueInternal);
            if ~isequal(value,0)
                this.Value = value;
            end
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.TitleLabel = this.TitleLabel;
            widgets.TextLabel = this.TextLabel;
            widgets.EditField = this.EditField;
            widgets.Button = this.Button;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end

function localValidate(value)
validateattributes(value,{'numeric'},{'size',[1 3],'>=',0,'<=',1});
end
