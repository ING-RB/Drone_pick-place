classdef (ConstructOnLoad) FrequencyVectorContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "FrequencyVectorContainer":
    % Widget that is used to set frequency vector and unit.
    %
    % To use container in a dialog/panel:
    %
    %   c = controllib.widget.internal.cstprefs.FrequencyVectorContainer('Value',[1 1000],'Unit','Hz');
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % To use container without "Generate automatically" option
    %
    %   c = controllib.widget.internal.cstprefs.FrequencyVectorContainer('Value',[1 1000],'Unit','Hz',...
    %           "ShowAutoOption",false); 
    %
    % Properties
    %   Value:
    %       Set or get the frequency vector.
    %       [] denotes auto setting.
    %       Numeric 2 element vector denotes frequency range setting.
    %       Numeric vector denotes frequency vector setting.
    %
    %   Unit:
    %       Set or get the frequency units.
    %       '' denotes auto setting.
    %
    % Methods
    %   getValueInUnit:
    %       Returns value in specified unit.
    %       Value = getValueInUnit(FrequencyVectorContainer,'Hz')
    %
    % Events
    %   ValueChanged
    %       Event thrown when UI is used to change frequency vector value or
    %       unit.

    % Copyright 2021-22 The MathWorks, Inc.

    properties(SetObservable, AbortSet)
        Value
        EnableAuto logical = true
        EnableRange logical = true
        EnableVector logical = true
    end

    properties(Dependent, SetObservable, AbortSet)
        Unit
    end

    properties (Access = private)
        Unit_I = ''
        FrequencyVectorString = 'logspace(0,3,50)'
        DefaultFrequencyUnit

        ButtonGroup
        ToLabel
        AutoRadioButton
        RangeRadioButton
        VectorRadioButton
        RangeStartEditField
        RangeStopEditField
        RangeUnitDropDown
        VectorEditField
        VectorUnitDropDown
        UpdateWidget = true
        WidgetTags = struct(...
            'ButtonGroup','ButtonGroup',...
            'RangeStartEditField','RangeStartEditField',...
            'RangeStopEditField','RangeStopEditField',...
            'RangeUnitDropDown','RangeUnitDropDown',...
            'VectorEditField','VectorEditField',...
            'VectorUnitDropDown','VectorUnitDropDown');
    end

    properties(Hidden)
        AddTagsToWidgets = true
    end

    events
        ValueChanged
    end

    methods
        function this = FrequencyVectorContainer(optionalArguments)
            arguments
                optionalArguments.Value = []
                optionalArguments.Unit = '';
                optionalArguments.EnableAuto logical = true
                optionalArguments.EnableRange logical = true
                optionalArguments.EnableVector logical = true
            end
            % Get Toolbox preference settings for time units
            toolboxPreferences = cstprefs.tbxprefs;
            if strcmpi(toolboxPreferences.FrequencyUnits,'auto')
                this.DefaultFrequencyUnit = 'rad/s';
            else
                this.DefaultFrequencyUnit = toolboxPreferences.FrequencyUnits;
            end

            % Show auto generated vector option
            this.EnableAuto = optionalArguments.EnableAuto;
            this.EnableRange = optionalArguments.EnableRange;
            this.EnableVector = optionalArguments.EnableVector;
            
            % Set Value and Units
            if ~isempty(optionalArguments.Value)
                this.Value = optionalArguments.Value;
            elseif this.EnableAuto
                this.Value = [];
            elseif this.EnableRange
                this.Value = {1,1000};
            else
                this.Value = logspace(0,3,50);
            end

            if ~isempty(optionalArguments.Value) && isempty(optionalArguments.Unit)
                this.Unit_I = this.DefaultFrequencyUnit;
            else
                this.Unit_I = optionalArguments.Unit;
            end
            
            % Set Container Title
            this.ContainerTitle = m('Controllib:gui:strFrequencyVector');
        end

        function updateUI(this)
            % Enable/Disable widgets
            enableDisableAuto(this);
            enableDisableRange(this);
            enableDisableVector(this);        

            if this.IsWidgetValid
                % Select radio button based on Value
                selectRadioButton(this);
                % Update appropriate units dropdown bases on Units
                updateUnitDropdown(this);
            end
        end

        function set.Value(this,Value)
            if this.IsWidgetValid
                % Select appropriate radio button if widget is built.
                % Invalid values error out.
                selectRadioButton(this,Value);
            end
            this.Value = Value;
        end

        function Units = get.Unit(this)
            Units = this.Unit_I;
        end

        function set.Unit(this,Units)
            if this.IsWidgetValid
                % Update appropirate units dropdown if widget is built.
                % Invalid units error out.
                updateUnitDropdown(this,Units);
            end
            if ~isempty(this.Value)
                % Do not set units if Value indicates auto setting.
                this.Unit_I = Units;
            end
        end

        function Value = getValueInUnit(this,newUnit)
            % value = getValueInUnit(FrequencyVectorContainer,'Hz')
            Value = funitconv(this.Unit,newUnit)*this.Value;
        end
        
        function set.EnableAuto(this,EnableAutoOption)
            this.EnableAuto = EnableAutoOption;
            enableDisableAuto(this);
        end

        function set.EnableRange(this,EnableRangeOption)
            this.EnableRange = EnableRangeOption;
            enableDisableRange(this);
        end

        function set.EnableVector(this,EnableVectorOption)
            this.EnableVector(this,EnableVectorOption);
            enableDisableVector(this);
        end
    end

    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],...
                'Scrollable',"off");
            widget.RowHeight = {25,25,25};
            widget.ColumnWidth = {5,175,'0.4x',20,'0.4x','1x'};
            widget.Padding = 0;
            
            % Button Group
            buttongroup = uibuttongroup(widget);
            buttongroup.Layout.Row = [1 3];
            buttongroup.Layout.Column = 2;
            buttongroup.BorderType = 'none';
            buttongroup.SelectionChangedFcn = ...
                @(es,ed) callbackFrequencyVectorSelectionChanged(this);
            
            % Auto option
            autoradiobutton = uiradiobutton(buttongroup);
            autoradiobutton.Text = m('Controllib:gui:strGenerateAutomatically');
            autoradiobutton.Position = [2 72 175 22];
            autoradiobutton.Tag = 'freqauto';
            if ~this.EnableAuto
                autoradiobutton.Enable = false;
            end

            % Range option
            rangeradiobutton = uiradiobutton(buttongroup);
            rangeradiobutton.Text = m('Controllib:gui:strDefinerange');
            rangeradiobutton.Position = [2 37 175 22];
            rangeradiobutton.Tag = 'freqrange';

            rangestarteditfield = uieditfield(widget,'numeric');
            rangestarteditfield.Layout.Row = 2;
            rangestarteditfield.Layout.Column = 3;
            rangestarteditfield.Enable = false;
            rangestarteditfield.Limits = [0 1000];
            rangestarteditfield.Value = 1;
            rangestarteditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyRangeStartChanged(this,es,ed);
            
            label = uilabel(widget,'Text',m('Controllib:gui:strTo'));
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 2;
            label.Layout.Column = 4;
            label.Enable = false;
            
            rangestopeditfield = uieditfield(widget,'numeric');
            rangestopeditfield.Layout.Row = 2;
            rangestopeditfield.Layout.Column = 5;
            rangestopeditfield.Enable = false;
            rangestopeditfield.Limits = [1 Inf];
            rangestopeditfield.Value = 1000;
            rangestopeditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyRangeStopChanged(this,es,ed);
            
            rangeunitsdropdown = uidropdown(widget);
            rangeunitsdropdown.Layout.Row = 2;
            rangeunitsdropdown.Layout.Column = 6;
            rangeunitsdropdown.Enable = false;
            rangeunitsdropdown.ItemsData = localGetValidFrequencyUnits();
            rangeunitsdropdown.Items = localGetValidFrequencyUnitsString();
            rangeunitsdropdown.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyRangeUnitsChanged(this);
            if isempty(this.Unit_I)
                rangeunitsdropdown.Value = this.DefaultFrequencyUnit;
            else
                rangeunitsdropdown.Value = this.Unit_I;
            end
            
            if ~this.EnableRange
                rangeradiobutton.Enable = false;
                rangestarteditfield.Enable = false;
                label.Enable = false;
            end
            % Vector option
            vectorradiobutton = uiradiobutton(buttongroup);
            vectorradiobutton.Text = m('Controllib:gui:strDefineVector');
            vectorradiobutton.Position = [2 2 175 22];
            vectorradiobutton.Tag = 'freqvector';
            vectoreditfield = uieditfield(widget);
            vectoreditfield.Layout.Row = 3;
            vectoreditfield.Layout.Column = [3 5];
            vectoreditfield.Enable = false;
            vectoreditfield.Value = this.FrequencyVectorString;
            vectoreditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyVectorEditFieldChanged(this,es,ed);
            vectorunitsdropdown = uidropdown(widget);
            vectorunitsdropdown.Layout.Row = 3;
            vectorunitsdropdown.Layout.Column = 6;
            vectorunitsdropdown.Enable = false;
            vectorunitsdropdown.ItemsData = localGetValidFrequencyUnits();
            vectorunitsdropdown.Items = localGetValidFrequencyUnitsString();
            vectorunitsdropdown.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyVectorUnitsChanged(this);
            if isempty(this.Unit_I)
                vectorunitsdropdown.Value = this.DefaultFrequencyUnit;
            else
                vectorunitsdropdown.Value = this.Unit_I;
            end

            this.ButtonGroup = buttongroup;
            this.ToLabel = label;
            this.AutoRadioButton = autoradiobutton;
            this.RangeRadioButton = rangeradiobutton;
            this.VectorRadioButton = vectorradiobutton;
            this.RangeStartEditField = rangestarteditfield;
            this.RangeStopEditField = rangestopeditfield;
            this.RangeUnitDropDown = rangeunitsdropdown;
            this.VectorEditField = vectoreditfield;
            this.VectorUnitDropDown = vectorunitsdropdown;

            % Add tags
            if this.AddTagsToWidgets
                addTags(this);
            end

            % Select radio button based on this.Value
            selectRadioButton(this);
        end
    end

    %% Private methods
    methods (Access = private)
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    this.(wn{1}).Tag = this.WidgetTags.(wn{1});
                end
            end
        end

        function callbackFrequencyVectorSelectionChanged(this,varargin)
            updateWidgets(this);
            updateData(this,varargin{:});
        end

        function callbackFrequencyRangeStartChanged(this,~,ed)
            this.RangeStopEditField.Limits(1) = ed.Value;
            updateData(this);
        end

        function callbackFrequencyRangeStopChanged(this,~,ed)
            this.RangeStartEditField.Limits(2) = ed.Value;
            updateData(this);
        end

        function callbackFrequencyVectorEditFieldChanged(this,~,ed)
            frequencyVector = evaluateFrequencyVectorString(ed.Value,inf);
            if isempty(frequencyVector)
                this.VectorEditField.Value = this.FrequencyVectorString;
            elseif ~isequal(this.Value,frequencyVector)
                this.FrequencyVectorString = makeFrequencyVectorString(frequencyVector);
                this.VectorEditField.Value = this.FrequencyVectorString;
            end
            updateData(this);
        end

        function callbackFrequencyRangeUnitsChanged(this)
            % Stop time units dropdown changed
            updateData(this);
        end

        function callbackFrequencyVectorUnitsChanged(this)
            updateData(this);
        end

        function selectRadioButton(this,Value)
            % Select appropriate radio button based on Value input. Default
            % uses the stored this.Value
            arguments
                this
                Value = this.Value;
            end
            if isempty(Value)
                % Select auto if enabled
                this.AutoRadioButton.Value = true;
                this.Unit_I = '';
            elseif iscell(Value)
                % Select range
                this.RangeRadioButton.Value = true;
                this.RangeStartEditField.Value = Value{1};
                this.RangeStopEditField.Value = Value{2};
                this.Unit_I = this.RangeUnitDropDown.Value;
            else
                % Select frequency vector
                this.VectorRadioButton.Value = true;
                this.FrequencyVectorString = makeFrequencyVectorString(Value);
                this.VectorEditField.Value = this.FrequencyVectorString;
                this.Unit_I = this.VectorUnitDropDown.Value;
            end
            updateWidgets(this);
        end

        function updateData(this,notifyValueChanged)
            % Update Value and Units and notify by default
            arguments
                this
                notifyValueChanged = true
            end
            switch this.ButtonGroup.SelectedObject.Tag
                case 'freqauto'
                    this.Value = [];
                    this.Unit_I = '';
                case 'freqrange'
                    this.Value = {this.RangeStartEditField.Value,...
                        this.RangeStopEditField.Value};
                    this.Unit_I = this.RangeUnitDropDown.Value;
                case 'freqvector'
                    this.FrequencyVectorString = this.VectorEditField.Value;
                    this.Value = eval(this.FrequencyVectorString);
                    this.Unit_I = this.VectorUnitDropDown.Value;
            end
            if notifyValueChanged
                % Notify ValueChanged event
                notify(this,'ValueChanged');
            end
        end

        function updateWidgets(this)
            switch this.ButtonGroup.SelectedObject.Tag
                case 'freqauto'
                    this.RangeStartEditField.Enable = false;
                    this.ToLabel.Enable = false;
                    this.RangeStopEditField.Enable = false;
                    this.RangeStartEditField.Enable = false;
                    this.RangeUnitDropDown.Enable = false;
                    this.VectorEditField.Enable = false;
                    this.VectorUnitDropDown.Enable = false;
                case 'freqrange'
                    this.RangeStartEditField.Enable = true;
                    this.ToLabel.Enable = true;
                    this.RangeStopEditField.Enable = true;
                    this.RangeStartEditField.Enable = true;
                    this.RangeUnitDropDown.Enable = true;
                    this.VectorEditField.Enable = false;
                    this.VectorUnitDropDown.Enable = false;
                case 'freqvector'
                    this.RangeStartEditField.Enable = false;
                    this.ToLabel.Enable = false;
                    this.RangeStopEditField.Enable = false;
                    this.RangeStartEditField.Enable = false;
                    this.RangeUnitDropDown.Enable = false;
                    this.VectorEditField.Enable = true;
                    this.VectorUnitDropDown.Enable = true;
            end
        end

        function updateUnitDropdown(this,Units)
            % Update appropriate dropdown based on Units. Default uses
            % stored this.Units_I
            arguments
                this
                Units = this.Unit_I
            end

            switch this.ButtonGroup.SelectedObject.Tag
                case 'freqrange'
                    this.RangeUnitDropDown.Value = Units;
                case 'freqvector'
                    this.VectorUnitDropDown.Value = Units;
            end
        end
    
        function enableDisableAuto(this)
            if this.IsWidgetValid
                this.AutoRadioButton.Enable = this.EnableAuto;
            end
        end

        function enableDisableRange(this)
            if this.IsWidgetValid
                this.RangeRadioButton.Enable = this.EnableRange;
                this.RangeStartEditField.Enable = this.EnableRange;
                this.ToLabel.Enable = this.EnableRange;
                this.RangeStopEditField.Enable = this.EnableRange;
                this.RangeUnitDropDown.Enable = this.EnableRange;
            end
        end

        function enableDisableVector(this)
            if this.IsWidgetValid
                this.VectorRadioButton.Enable = this.EnableVector;
                this.VectorEditField.Enable = this.EnableVector;
                this.VectorUnitDropDown.Enable = this.EnableVector;
            end
        end
    end

    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.ButtonGroup = this.ButtonGroup;
            widgets.AutoRadioButton = this.AutoRadioButton;
            widgets.RangeRadioButton = this.RangeRadioButton;
            widgets.VectorRadioButton = this.VectorRadioButton;
            widgets.RangeStartEditField = this.RangeStartEditField;
            widgets.RangeStopEditField = this.RangeStopEditField;
            widgets.RangeUnitDropDown = this.RangeUnitDropDown;
            widgets.VectorEditField = this.VectorEditField;
            widgets.VectorUnitDropDown = this.VectorUnitDropDown;
        end
    end
end

%% Local functions
function val = evaluateFrequencyVectorString(str,n)
% Evaluate string val
if ~isempty(str)
    val = evalin('base',str,'[]'); %#ok<EV3IN>
    if ~isnumeric(val) | ~(isreal(val) & isfinite(val)) | any(isnan(val(:))) %#ok<AND2,OR2>
        val = [];
    else
        val = val(:);
        %---Case: val must be same length as n
        if n<inf && length(val)==n
            %---Make sure val is >0
            if val<=0
                val = [];
            end
            %---Case: n is finite and vector length is 2
        elseif ~(n==inf && length(val)>2)
            val = [];
        end
    end
end
end

function str = makeFrequencyVectorString(val)
% Build a nice display string for val
lval = length(val);
if lval==0
    str = '';
elseif lval==1
    str = num2str(val);
elseif lval==2
    str = sprintf('[%0.3g %0.3g]',val(1),val(end));
else
    dval   = diff(val);
    val10  = log10(val);
    dval10 = diff(val10);
    tol    = 100*eps*max(abs(val));
    tol10  = 100*eps*max(abs(val10));
    if all(abs(dval-dval(1))<tol)
        %---Build compact vector (even step size)
        str = sprintf('[%s:%s:%s]',num2str(val(1)),num2str(dval(1)),num2str(val(end)));
    elseif all(abs(dval10-dval10(1))<tol10)
        %---Build logspace string
        str = sprintf('logspace(%s,%s,%d)',num2str(val10(1)),num2str(val10(end)),lval);
    elseif lval<=20
        %---Generic case (show all values, as long as the vector isn't too long!)
        str = sprintf('%g ',val);
        str = sprintf('[%s]',str(1:end-1));
    else
        %---Default string
        str = 'logspace(0,3,50)';
    end
end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end

function validFrequencyUnits = localGetValidFrequencyUnits()
validFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
validFrequencyUnits = validFrequencyUnits(:,1);
end

function validFrequencyUnitsString = localGetValidFrequencyUnitsString()
validFrequencyUnitsStringID = controllibutils.utGetValidFrequencyUnits;
validFrequencyUnitsString = cellfun(@(x) m(x),validFrequencyUnitsStringID(:,2),'UniformOutput',false);
end

