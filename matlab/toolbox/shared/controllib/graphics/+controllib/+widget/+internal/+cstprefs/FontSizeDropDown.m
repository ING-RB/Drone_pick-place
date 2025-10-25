classdef (ConstructOnLoad) FontSizeDropDown < controllib.ui.internal.dialog.AbstractContainer
    % "FontSizeDropDown": 
    % Dropdown widget that is used to specify the font size.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.FontSizeDropDown(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   Value:
    %       Set or get the fontsize.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        Value
        Tag
    end
    
    properties(Access = private,Transient)
        ValidFontSizes = 8:16;
    end
    
    properties
        IsEditable = true
    end
    
    properties(Access = private)
        ValueInternal
        DropDown
    end
    
    events
        ValueChanged
    end
    
    methods
        function this = FontSizeDropDown(value)
            this@controllib.ui.internal.dialog.AbstractContainer;
            if nargin == 0
                toolboxPreferences = cstprefs.tbxprefs;
                value = toolboxPreferences.AxesFontSize;
            end
            this.ValueInternal = value;
        end
        
        function Value = get.Value(this)
            Value = this.ValueInternal;
        end
        
        function set.Value(this,Value)
            if ~strcmp(Value,this.ValueInternal)
                localValidate(Value);
                this.ValueInternal = Value;
                localSetWidgetValue(this);
            end
        end
        
        function tag = get.Tag(this)
            tag = this.DropDown.Tag;
        end
        
        function set.Tag(this,tag)
            this.DropDown.Tag = tag;
        end
    end
    
    methods (Access = protected, Sealed)
        function container = createContainer(this)
            container = uigridlayout('Parent',[],...
                'Scrollable',"off");
            container.RowHeight = {'fit'};
            container.ColumnWidth = {80};
            container.Padding = 0;
            dropdown = uidropdown(container);
            dropdown.Editable = this.IsEditable;
            dropdown.Items = getItems(this);
            dropdown.ValueChangedFcn = @(es,ed) callbackValueChanged(this,es,ed);
            this.DropDown = dropdown;
            localSetWidgetValue(this);
        end
    end
    
    methods (Access = protected)
        function items = getItems(this)
            items = arrayfun(@(x) [num2str(x),' pt'],this.ValidFontSizes,...
                                    'UniformOutput',false);
        end
        
        function callbackValueChanged(this,es,ed)
            value = ed.Value;
            if ed.Edited
                try
                    value = replace(value,'pt','');
                    numericValue = str2double(value);
                    localValidate(numericValue);
                    this.ValueInternal = numericValue;
                    localSetWidgetValue(this);
                catch
                    es.Value = ed.PreviousValue;
                end
            else
                this.ValueInternal = str2double(replace(value,'pt',''));
                eventData = controllib.app.internal.GenericEventData(this.ValueInternal);
                notify(this,'ValueChanged',eventData);
            end
        end
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets.DropDown = this.DropDown;
        end
    end
    
    methods (Access = private)
        function localSetWidgetValue(this)
            this.DropDown.Value = [num2str(this.ValueInternal),' pt'];
            eventData = controllib.app.internal.GenericEventData(this.ValueInternal);
            notify(this,'ValueChanged',eventData);
        end
    end
end

function localValidate(value)
validateattributes(value,{'numeric'},{'size',[1 1],'positive','real','finite'});
end