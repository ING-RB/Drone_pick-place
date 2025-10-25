classdef FrequencyEditorDialog < controllib.ui.internal.dialog.AbstractDialog & ...
                                matlab.mixin.SetGet
    % FrequencyInputDialog
    %
    % dlg = controllib.chart.internal.widget.FrequencyInputDialog(System=sys)
    
    % Copyright 2022 The MathWorks, Inc.
    
    %% Properties
    properties (SetObservable=false,AbortSet)
        Frequency
        FrequencyUnits
        FrequencyChangedFcn
    end

    properties (GetAccess=public,SetAccess=private)
        IsModal
    end

    properties(Dependent)
        EnableAuto
        EnableRange
        EnableVector
    end
    
    events
        FrequencyChanged
    end

    properties (Access = private)
        FrequencyContainerWidget
        FrequencyContainer          controllib.widget.internal.cstprefs.FrequencyVectorContainer
        ButtonPanel                 controllib.widget.internal.buttonpanel.ButtonPanel    
    end

    %% Public methods
    methods
        function this = FrequencyEditorDialog(optionalArguments)
            arguments
                optionalArguments.System = []
                optionalArguments.Frequency = []
                optionalArguments.FrequencyUnits string = "auto"
                optionalArguments.EnableAuto logical = true
                optionalArguments.EnableRange logical = true
                optionalArguments.EnableVector logical = true
                optionalArguments.Modal logical = false
            end
            this.Title = "Specify frequency";
            this.Name = "FrequencyEditorDialog";
            this.CloseMode = 'cancel';

            % Frequency
            this.Frequency = optionalArguments.Frequency;

            % Frequency Units
            if strcmp(optionalArguments.FrequencyUnits,'auto')
                prefs = cstprefs.tbxprefs;
                if strcmp(prefs.FrequencyUnits,'auto')
                    this.FrequencyUnits = 'rad/s';
                else
                    this.FrequencyUnits = prefs.FrequencyUnits;
                end
            else
                this.FrequencyUnits = optionalArguments.FrequencyUnits;
            end

            % Modal
            this.IsModal = optionalArguments.Modal;

            % Check if auto should be disabled
            if ~isempty(optionalArguments.System) 
                if issparse(optionalArguments.System)
                    EnableAuto = false;
                    EnableRange = false;
                    EnableVector = true;
                else
                    EnableAuto = true;
                    EnableRange = true;
                    EnableVector = true;
                end
            else
                EnableAuto = optionalArguments.EnableAuto;
                EnableRange = optionalArguments.EnableRange;
                EnableVector = optionalArguments.EnableVector;
            end

            % Create FrequencyContainer
            this.FrequencyContainer = controllib.widget.internal.cstprefs.FrequencyVectorContainer(...
                Value=this.Frequency,Unit=this.FrequencyUnits,EnableAuto=EnableAuto,...
                EnableRange=EnableRange,EnableVector=EnableVector);
            this.FrequencyContainer.ShowContainerTitle = false;
            this.Frequency = this.FrequencyContainer.Value;
        end

        function updateUI(this)
            this.FrequencyContainer.Value = this.Frequency;
            this.FrequencyContainer.Unit = this.FrequencyUnits;
        end

        function EnableAuto = get.EnableAuto(this)
            EnableAuto = this.FrequencyContainer.EnableAuto;
        end

        function set.EnableAuto(this,EnableAuto)
            this.FrequencyContainer.EnableAuto = EnableAuto;
        end

        function EnableRange = get.EnableRange(this)
            EnableRange = this.FrequencyContainer.EnableRange;
        end

        function set.EnableRange(this,EnableRange)
            this.FrequencyContainer.EnableRange = EnableRange;
        end

        function EnableVector = get.EnableVector(this)
            EnableVector = this.FrequencyContainer.EnableVector;
        end

        function set.EnableVector(this,EnableVector)
            this.FrequencyContainer.EnableVector = EnableVector;
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function buildUI(this)
            % Layout
            layout = uigridlayout(this.UIFigure,[2 1],RowHeight={'fit','fit'},ColumnWidth={'1x'});
            layout.RowSpacing = 20;
            
            % Frequency Panel
            this.FrequencyContainerWidget = getWidget(this.FrequencyContainer);
            this.FrequencyContainerWidget.Parent = layout;
            this.FrequencyContainerWidget.Layout.Row = 1;
            
            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(layout,["OK","Apply","Cancel"]);
            this.ButtonPanel.ApplyButton.ButtonPushedFcn = @(es,ed) updateFrequency(this);
            this.ButtonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.ButtonPanel.CancelButton.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this);

            % Set size
            this.UIFigure.Position(3:4) = [460 180];
        end

        function updateFrequency(this)
            % Update frequency
            this.Frequency = this.FrequencyContainer.Value;

            % Update frequency units
            this.FrequencyUnits = this.FrequencyContainer.Unit;

            % Notify event
            notify(this,"FrequencyChanged");

            % Execute callback if specified
            if ~isempty(this.FrequencyChangedFcn)
                eventData = controllib.chart.internal.utils.GenericEventData;
                eventData.Data.Frequency = this.Frequency;
                eventData.Data.FrequencyUnits = this.FrequencyUnits;
                this.FrequencyChangedFcn(this,eventData);
            end
        end

        function cbOKButtonPushed(this)
            updateFrequency(this);
            close(this);
        end

        function cbCancelButtonPushed(this)
            close(this);
        end
    end
    
    %% Hidden (QE) methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets = qeGetWidgets(this.FrequencyContainer);
            widgets.OKButton = this.ButtonPanel.OKButton;
            widgets.ApplyButton = this.ButtonPanel.ApplyButton;
            widgets.CancelButton = this.ButtonPanel.CancelButton;
        end
    end
end