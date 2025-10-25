classdef (ConstructOnLoad) FontOptionsWidget < controllib.ui.internal.dialog.AbstractContainer
    % "FontOptionsWidget": 
    % Widget that is used to specify font size and font style.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.FontOptionsWidget(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %       FontSize        numeric
    %       FontWeight      'bold' or 'normal'
    %       FontAngle       'italic' or 'normal'
    %       FontLabel       String to display the label
    
    % Copyright 2020 The MathWorks, Inc.
    properties(Access = public, Dependent)
        FontSize
        FontWeight
        FontAngle
        FontLabel
    end
    
    properties(Access = private,Transient)
    end
    
    properties

    end
    
    properties(Access = private)
        Label
        SizeDropDown
        BoldCheckBox
        ItalicCheckBox
        FontSizeInternal
        FontWeightInternal
        FontAngleInternal
        FontLabelInternal
    end
    
    events
        FontSizeChanged
        FontWeightChanged
        FontAngleChanged
    end
    
    methods
        function this = FontOptionsWidget()
            this@controllib.ui.internal.dialog.AbstractContainer;
            toolboxPreferences = cstprefs.tbxprefs;
            this.FontSizeInternal = toolboxPreferences.AxesFontSize;
            this.FontWeightInternal = toolboxPreferences.AxesFontWeight;
            this.FontAngleInternal = toolboxPreferences.AxesFontAngle;
            this.FontLabel = m('Controllib:gui:strLabels');
        end
    end
    
    methods %set/get
        % FontSize
        function FontSize = get.FontSize(this)
            FontSize = this.FontSizeInternal;
        end
        
        function set.FontSize(this,FontSize)
            if ~isempty(this.SizeDropDown) && isvalid(this.SizeDropDown)
                this.SizeDropDown.Value = FontSize;
            end
            this.FontSizeInternal = FontSize;
        end
        
        % FontWeight
        function FontWeight = get.FontWeight(this)
            FontWeight = this.FontWeightInternal;
        end
        
        function set.FontWeight(this,FontWeight)
            validatestring(FontWeight,{'bold','normal'});
            if ~isempty(this.BoldCheckBox) && isvalid(this.BoldCheckBox)
                this.BoldCheckBox.Value = strcmp(FontWeight,'bold');
            end
            this.FontWeightInternal = FontWeight;
        end
        
        % FontAngle
        function FontAngle = get.FontAngle(this)
            FontAngle = this.FontAngleInternal;
        end
        
        function set.FontAngle(this,FontAngle)
            validatestring(FontAngle,{'italic','normal'});
            if ~isempty(this.ItalicCheckBox) && isvalid(this.ItalicCheckBox)
                this.ItalicCheckBox.Value = strcmp(FontAngle,'italic');
            end
            this.FontAngleInternal = FontAngle;
        end
       
        % FontLabel
        function FontLabel = get.FontLabel(this)
            FontLabel = this.FontLabelInternal;
        end
        
        function set.FontLabel(this,FontLabel)
            if ~isempty(this.Label) && isvalid(this.Label)
                this.Label.Value = FontLabel;
            end
            this.FontLabelInternal = FontLabel;
        end
        
    end
    
    methods (Access = protected, Sealed)
        function container = createContainer(this)
            % Container
            container = uigridlayout('Parent',[],...
                'Scrollable',"off");
            container.RowHeight = {'1x'};
            container.ColumnWidth = {'1x','fit','fit','fit'};
            container.Padding = 0;
            % Label
            this.Label = uilabel(container);
            this.Label.Layout.Column = 1;
            this.Label.Text = this.FontLabel;
            % FontSize dropdown
            this.SizeDropDown = controllib.widget.internal.cstprefs.FontSizeDropDown(this.FontSize);
            w = getWidget(this.SizeDropDown);
            w.Parent = container;
            w.Layout.Column = 2;
            weakThis = matlab.lang.WeakReference(this);
            addlistener(this.SizeDropDown,'ValueChanged',...
                                @(es,ed) callbackFontSizeChanged(weakThis.Handle,es,ed));
            % Bold CheckBox
            this.BoldCheckBox = uicheckbox(container);
            this.BoldCheckBox.Layout.Column = 3;
            this.BoldCheckBox.Text = m('Controllib:gui:strBold');
            this.BoldCheckBox.Value = strcmp(this.FontWeight,'bold');
            this.BoldCheckBox.ValueChangedFcn = ...
                                @(es,ed) callbackFontWeightChanged(this,es,ed);
            % Bold CheckBox
            this.ItalicCheckBox = uicheckbox(container);
            this.ItalicCheckBox.Layout.Column = 4;
            this.ItalicCheckBox.Text = m('Controllib:gui:strItalic');
            this.ItalicCheckBox.Value = strcmp(this.FontAngle,'italic');
            this.ItalicCheckBox.ValueChangedFcn = ...
                                @(es,ed) callbackFontAngleChanged(this,es,ed);
        end
    end
    
    methods (Access = private)
        function callbackFontSizeChanged(this,es,ed)
            this.FontSizeInternal = ed.Data;
            notify(this,'FontSizeChanged',ed);
        end
        
        function callbackFontWeightChanged(this,es,ed)
            if ed.Value
                this.FontWeightInternal = 'bold';
            else
                this.FontWeightInternal = 'normal';
            end
            eventData = controllib.app.internal.GenericEventData(this.FontWeightInternal);
            notify(this,'FontWeightChanged',eventData);
        end
        
        function callbackFontAngleChanged(this,es,ed)
            if ed.Value
                this.FontAngleInternal = 'italic';
            else
                this.FontAngleInternal = 'normal';
            end
            eventData = controllib.app.internal.GenericEventData(this.FontAngleInternal);
            notify(this,'FontAngleChanged',eventData);
        end
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            dropdownWidget = qeGetWidgets(this.SizeDropDown);
            widgets.Label = this.Label;
            widgets.SizeDropDown = dropdownWidget.DropDown;
            widgets.BoldCheckBox = this.BoldCheckBox;
            widgets.ItalicCheckBox = this.ItalicCheckBox;
        end
        
        function setTags(this,tags)
            this.SizeDropDown.Tag = tags.FontSize;
            this.BoldCheckBox.Tag = tags.FontWeight;
            this.ItalicCheckBox.Tag = tags.FontAngle;
            this.Label.Tag = tags.FontLabel;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end