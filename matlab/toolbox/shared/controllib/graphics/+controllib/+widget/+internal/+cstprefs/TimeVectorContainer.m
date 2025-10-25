classdef (ConstructOnLoad) TimeVectorContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "TimeVectorContainer":
    % Widget that is used to set time vector and unit.
    %
    % To use container in a dialog/panel:
    %
    %   c = controllib.widget.internal.cstprefs.TimeVectorContainer('Value',5,'Unit','minutes');
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % To use container without "Generate automatically" option
    %
    %   c = controllib.widget.internal.cstprefs.FrequencyVectorContainer('Value',5,'Unit','minutes',...
    %           "ShowAutoOption",false);
    %
    % Properties
    %   Value:
    %       Set or get the time vector.
    %       [] denotes auto setting.
    %       Numeric scalar denotes stop time setting.
    %       Numeric vector denotes time vector setting
    %   Unit:
    %       Set or get the time units.
    %       '' denotes auto setting.
    %
    % Methods
    %   getValueInUnit:
    %       Returns value in specified unit.
    %       Value = getValueInUnit(TimeVectorContainer,'minutes')
    %
    % Events
    %   ValueChanged
    %       Event thrown when UI is used to change time vector value or
    %       unit.

    % Copyright 2021-22 The MathWorks, Inc.

    properties(SetObservable, AbortSet)
        Value
        EnableAuto logical = true
        EnableFinal logical = true
        EnableVector logical = true
    end

    properties(Dependent, SetObservable, AbortSet)
        Unit
    end

    properties (Access = private)
        Unit_I = ''
        TimeVectorString = '0:0.01:10'
        DefaultTimeUnit

        ButtonGroup
        AutoRadioButton
        FinalTimeRadioButton
        VectorRadioButton
        FinalTimeEditField
        FinalTimeUnitDropDown
        VectorEditField
        VectorUnitDropDown
        UpdateWidget = true
        WidgetTags = struct(...
            'ButtonGroup','ButtonGroup',...
            'FinalTimeEditField','StopTimeEditField',...
            'FinalTimeUnitDropDown','StopTimeUnitDropDown',...
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
        function this = TimeVectorContainer(optionalArguments)
            arguments
                optionalArguments.Value = []
                optionalArguments.Unit = '';
                optionalArguments.EnableAuto = true
                optionalArguments.EnableFinal logical = true
                optionalArguments.EnableVector logical = true
            end
            % Get Toolbox preference settings for time units
            toolboxPreferences = cstprefs.tbxprefs;
            if strcmpi(toolboxPreferences.TimeUnits,'auto')
                this.DefaultTimeUnit = 'seconds';
            else
                this.DefaultTimeUnit = toolboxPreferences.TimeUnits;
            end

            % Show auto generated vector option
            this.EnableAuto = optionalArguments.EnableAuto;
            this.EnableFinal = optionalArguments.EnableFinal;
            this.EnableVector = optionalArguments.EnableVector;

            % Set Value and Units
            if ~isempty(optionalArguments.Value)
                this.Value = optionalArguments.Value;
            elseif this.EnableAuto
                this.Value = [];
            elseif this.EnableFinal
                this.Value = 10;
            else
                this.Value = 0:0.01:10;
            end

            if ~isempty(optionalArguments.Value) && isempty(optionalArguments.Unit)
                this.Unit_I = this.DefaultTimeUnit;
            else
                this.Unit_I = optionalArguments.Unit;
            end

            % Set Container Title
            this.ContainerTitle = m('Controllib:gui:strTimeVector');
        end

        function updateUI(this)
            % Enable/Disable widgets
            enableDisableAuto(this);
            enableDisableFinal(this);
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
            % value = getValueInUnit(TimeVectorContainer,'minutes')
            Value = tunitconv(this.Unit,newUnit)*this.Value;
        end

        function set.EnableAuto(this,EnableAuto)
            this.EnableAuto = EnableAuto;
            enableDisableAuto(this);
        end

        function set.EnableFinal(this,EnableFinal)
            this.EnableFinal = EnableFinal;
            enableDisableFinal(this);
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
            widget.ColumnWidth = {5,175,'1x','1x'};
            widget.Padding = 0;

            % Button Group
            buttongroup = uibuttongroup(widget);
            buttongroup.Layout.Row = [1 3];
            buttongroup.Layout.Column = 2;
            buttongroup.BorderType = 'none';
            buttongroup.SelectionChangedFcn = ...
                @(es,ed) callbackTimeVectorSelectionChanged(this);

            % Auto
            autoradiobutton = uiradiobutton(buttongroup);
            autoradiobutton.Text = m('Controllib:gui:strGenerateAutomatically');
            autoradiobutton.Position = [2 72 175 22];
            autoradiobutton.Tag = 'timeauto';
            if ~this.EnableAuto
                autoradiobutton.Enable = false;
            end

            % Stop time
            finaltimeradiobutton = uiradiobutton(buttongroup);
            finaltimeradiobutton.Text = m('Controllib:gui:strDefineStopTime');
            finaltimeradiobutton.Position = [2 37 175 22];
            finaltimeradiobutton.Tag = 'timestop';

            finaltimeeditfield = uieditfield(widget,'numeric');
            finaltimeeditfield.Layout.Row = 2;
            finaltimeeditfield.Layout.Column = 3;
            finaltimeeditfield.Enable = false;
            finaltimeeditfield.Value = 1;
            finaltimeeditfield.Limits = [0 Inf];
            finaltimeeditfield.LowerLimitInclusive = 'off';
            finaltimeeditfield.UpperLimitInclusive = 'off';
            finaltimeeditfield.ValueChangedFcn = ...
                @(es,ed) callbackFinalTimeEditFieldChanged(this);

            finaltimeunitsdropdown = uidropdown(widget);
            finaltimeunitsdropdown.Layout.Row = 2;
            finaltimeunitsdropdown.Layout.Column = 4;
            finaltimeunitsdropdown.Enable = false;
            finaltimeunitsdropdown.ItemsData = localGetValidTimeUnits();
            finaltimeunitsdropdown.Items =localGetValidTimeUnitsString();
            if isempty(this.Unit_I)
                finaltimeunitsdropdown.Value = this.DefaultTimeUnit;
            else
                finaltimeunitsdropdown.Value = this.Unit_I;
            end
            finaltimeunitsdropdown.ValueChangedFcn = ...
                @(es,ed) callbackFinalTimeUnitsChanged(this);

            if ~this.EnableFinal
                finaltimeradiobutton.Enable = false;
                finaltimeeditfield.Enable = false;
                finaltimeunitsdropdown.Enable = false;
            end

            % Time Vector
            vectorradiobutton = uiradiobutton(buttongroup);
            vectorradiobutton.Text = m('Controllib:gui:strDefineVector');
            vectorradiobutton.Position = [2 2 175 22];
            vectorradiobutton.Tag = 'timevector';

            vectoreditfield = uieditfield(widget);
            vectoreditfield.Layout.Row = 3;
            vectoreditfield.Layout.Column = 3;
            vectoreditfield.Enable = false;
            vectoreditfield.HorizontalAlignment = 'right';
            vectoreditfield.Value = this.TimeVectorString;
            vectoreditfield.ValueChangedFcn = @(es,ed)...
                callbackTimeVectorEditFieldChanged(this,es,ed);

            vectorunitsdropdown = uidropdown(widget);
            vectorunitsdropdown.Layout.Row = 3;
            vectorunitsdropdown.Layout.Column = 4;
            vectorunitsdropdown.Enable = false;
            vectorunitsdropdown.ItemsData = localGetValidTimeUnits();
            vectorunitsdropdown.Items = localGetValidTimeUnitsString();
            if isempty(this.Unit_I)
                vectorunitsdropdown.Value = this.DefaultTimeUnit;
            else
                vectorunitsdropdown.Value = this.Unit_I;
            end
            vectorunitsdropdown.ValueChangedFcn = ...
                @(es,ed) callbackTimeVectorUnitsChanged(this);

            if ~this.EnableVector
                vectorradiobutton.Enable = false;
                vectoreditfield.Enable = false;
                vectorunitsdropdown.Enable = false;
            end

            % Assign widgets to properties
            this.ButtonGroup = buttongroup;
            this.AutoRadioButton = autoradiobutton;
            this.FinalTimeRadioButton = finaltimeradiobutton;
            this.VectorRadioButton = vectorradiobutton;
            this.FinalTimeEditField = finaltimeeditfield;
            this.FinalTimeUnitDropDown = finaltimeunitsdropdown;
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

        function callbackTimeVectorSelectionChanged(this,varargin)
            % Radio button selection changed
            updateWidgets(this);
            updateData(this,varargin{:});
        end

        function callbackFinalTimeEditFieldChanged(this)
            % Stop time edit field changed
            updateData(this);
        end

        function callbackFinalTimeUnitsChanged(this)
            % Stop time units dropdown changed
            updateData(this);
        end

        function callbackTimeVectorEditFieldChanged(this,~,ed)
            % Evalauate input string
            timeVector = evaluateTimeVectorString(ed.Value,inf);
            if isempty(timeVector)
                % Revert if invalid input
                this.VectorEditField.Value = this.TimeVectorString;
            elseif ~isequal(this.Value,timeVector)
                % Create new string if new and valid input
                this.TimeVectorString = makeTimeVectorString(timeVector);
                this.VectorEditField.Value = this.TimeVectorString;
            end
            updateData(this);
        end

        function callbackTimeVectorUnitsChanged(this)
            updateData(this);
        end

        function selectRadioButton(this,Value)
            % Select appropriate radio button based on Value input. Default
            % uses the stored this.Value
            arguments
                this
                Value = this.Value
            end

            if isempty(Value)
                % Select auto
                this.AutoRadioButton.Value = true;
                this.Unit_I = '';
            elseif isscalar(Value)
                % Select stop time
                this.FinalTimeRadioButton.Value = true;
                this.FinalTimeEditField.Value = Value;
                this.Unit_I = this.FinalTimeUnitDropDown.Value;
            else
                % Select time vector
                this.VectorRadioButton.Value = true;
                this.TimeVectorString = makeTimeVectorString(Value);
                this.VectorEditField.Value = this.TimeVectorString;
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
                case 'timeauto'
                    % Auto setting. Units are always ''
                    this.Value = [];
                    this.Unit_I = '';
                case 'timestop'
                    % Stop time. Units are based on dropdown value
                    this.Value = this.FinalTimeEditField.Value;
                    this.Unit_I = this.FinalTimeUnitDropDown.Value;
                case 'timevector'
                    % Time vector. Units are based on dropdown value
                    this.TimeVectorString = this.VectorEditField.Value;
                    this.Value = eval(this.TimeVectorString);
                    this.Unit_I = this.VectorUnitDropDown.Value;
            end
            if notifyValueChanged
                % Notify ValueChanged event
                notify(this,'ValueChanged');
            end
        end

        function updateWidgets(this)
            switch this.ButtonGroup.SelectedObject.Tag
                case 'timeauto'
                    this.FinalTimeEditField.Enable = false;
                    this.FinalTimeUnitDropDown.Enable = false;
                    this.VectorEditField.Enable = false;
                    this.VectorUnitDropDown.Enable = false;
                case 'timestop'
                    this.FinalTimeEditField.Enable = true;
                    this.FinalTimeUnitDropDown.Enable = true;
                    this.VectorEditField.Enable = false;
                    this.VectorUnitDropDown.Enable = false;
                case 'timevector'
                    this.FinalTimeEditField.Enable = false;
                    this.FinalTimeUnitDropDown.Enable = false;
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
                case 'timestop'
                    this.FinalTimeUnitDropDown.Value = Units;
                case 'timevector'
                    this.VectorUnitDropDown.Value = Units;
            end
        end

        function enableDisableAuto(this)
            if this.IsWidgetValid
                this.AutoRadioButton.Enable = this.EnableAuto;
            end
        end

        function enableDisableFinal(this)
            if this.IsWidgetValid
                this.FinalTimeRadioButton.Enable = this.EnableFinal;
                this.FinalTimeEditField.Enable = this.EnableFinal;
                this.FinalTimeUnitDropDown.Enable = this.EnableFinal;
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
            widgets.StopTimeRadioButton = this.FinalTimeRadioButton;
            widgets.VectorRadioButton = this.VectorRadioButton;
            widgets.StopTimeEditField = this.FinalTimeEditField;
            widgets.StopTimeUnitDropDown = this.FinalTimeUnitDropDown;
            widgets.VectorEditField = this.VectorEditField;
            widgets.VectorUnitDropDown = this.VectorUnitDropDown;
        end
    end
end

%% Local functions
function val = evaluateTimeVectorString(str,n)
% Evaluate string val
if ~isempty(str)
    val = evalin('base',str,'[]'); %#ok<EV3IN>
    if ~isnumeric(val) | ~(isreal(val) & isfinite(val)) %#ok<AND2,OR2>
        val = [];
    else
        val = val(:);
        %---Case: val must be same length as n
        if n<inf && length(val)==n
            %---Make sure val is >0
            if val<=0
                val = [];
            end
            %---Case: val is vector (length>1)
        elseif n==inf && length(val)>1
            %---Make sure all of val is >=0 and monotonically increasing
            if val(1)<0 || (val(2)-val(1))<=0
                val = [];
            else
                val = fixTimeVector(val);
            end
        else
            val = [];
        end
    end
end
end

function str = makeTimeVectorString(val)
% Build a nice display string for val
lval = length(val);
if lval==0
    str = '';
elseif lval==1
    str = num2str(val);
else
    val = fixTimeVector(val);
    str = sprintf('[%s:%s:%s]',num2str(val(1)),num2str(val(2)-val(1)),num2str(val(end)));
end
end

function val = fixTimeVector(val)
%---Fix vector if not evenly spaced
t0 = val(1);
dt = val(2)-val(1);
nt0 = round(t0/dt);
t0 = nt0*dt;
val = dt*(0:1:nt0+length(val)-1);
if t0>0
    val = val(val>=t0);
end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end

function validTimeUnits = localGetValidTimeUnits()
validTimeUnits = controllibutils.utGetValidTimeUnits;
validTimeUnits = validTimeUnits(:,1);
end

function validTimeUnitsString = localGetValidTimeUnitsString()
validTimeUnitsStringID = controllibutils.utGetValidTimeUnits;
validTimeUnitsString = cellfun(@(x) m(x),validTimeUnitsStringID(:,2),'UniformOutput',false);
end

