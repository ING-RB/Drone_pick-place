classdef TimeEditorDialog < controllib.ui.internal.dialog.AbstractDialog & ...
                                matlab.mixin.SetGet
    % TimeEditorDialog
    %
    % dlg = controllib.chart.internal.widget.TimeEditorDialog(System=sys)
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    %% Properties
    properties (SetObservable=false,AbortSet)
        Time
        TimeUnits
        TimeChangedFcn
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
        TimeChanged
    end

    properties (Access = private)
        TimeContainerWidget
        TimeContainer               controllib.widget.internal.cstprefs.TimeVectorContainer
        ButtonPanel                 controllib.widget.internal.buttonpanel.ButtonPanel    
    end

    %% Public methods
    methods
        function this = TimeEditorDialog(optionalArguments)
            arguments
                optionalArguments.System = []
                optionalArguments.Time = []
                optionalArguments.TimeUnits string = "auto"
                optionalArguments.EnableAuto logical = true
                optionalArguments.EnableFinal logical = true;
                optionalArguments.EnableVector logical = true;
                optionalArguments.Modal logical = false
            end
            this.Title = "Specify time";
            this.Name = "TimeEditorDialog";
            this.CloseMode = 'cancel';

            % Time
            this.Time = optionalArguments.Time;

            % Time Units
            if strcmp(optionalArguments.TimeUnits,'auto')
                prefs = cstprefs.tbxprefs;
                if strcmp(prefs.TimeUnits,'auto')
                    this.TimeUnits = 'seconds';
                else
                    this.TimeUnits = prefs.TimeUnits;
                end
            else
                this.TimeUnits = optionalArguments.TimeUnits;
            end

            % Modal
            this.IsModal = optionalArguments.Modal;

            % Check if auto should be disabled
            if ~isempty(optionalArguments.System) 
                if issparse(optionalArguments.System)
                    EnableAuto = false;
                    EnableFinal = true;
                    EnableVector = true;
                else
                    EnableAuto = true;
                    EnableFinal = true;
                    EnableVector = true;
                end
            else
                EnableAuto = optionalArguments.EnableAuto;
                EnableFinal = optionalArguments.EnableFinal;
                EnableVector = optionalArguments.EnableVector;
            end

            % Create TimeContainer            
            this.TimeContainer = controllib.widget.internal.cstprefs.TimeVectorContainer(...
                Value=this.Time,Unit=this.TimeUnits,EnableAuto=EnableAuto,...
                EnableFinal=EnableFinal,EnableVector=EnableVector);
            this.TimeContainer.ShowContainerTitle = false;
            this.Time = this.TimeContainer.Value;
        end

        function updateUI(this)
            this.TimeContainer.Value = this.Time;
            this.TimeContainer.Unit = this.TimeUnits;
        end

        function EnableAuto = get.EnableAuto(this)
            EnableAuto = this.TimeContainer.EnableAuto;
        end

        function set.EnableAuto(this,EnableAuto)
            this.TimeContainer.EnableAuto = EnableAuto;
        end

        function EnableRange = get.EnableRange(this)
            EnableRange = this.TimeContainer.EnableRange;
        end

        function set.EnableRange(this,EnableRange)
            this.TimeContainer.EnableRange = EnableRange;
        end

        function EnableVector = get.EnableVector(this)
            EnableVector = this.TimeContainer.EnableVector;
        end

        function set.EnableVector(this,EnableVector)
            this.TimeContainer.EnableVector = EnableVector;
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function buildUI(this)
            % Layout
            layout = uigridlayout(this.UIFigure,[2 1],RowHeight={'fit','fit'},ColumnWidth={'1x'});
            layout.RowSpacing = 20;
            
            % Time Panel
            this.TimeContainerWidget = getWidget(this.TimeContainer);
            this.TimeContainerWidget.Parent = layout;
            this.TimeContainerWidget.Layout.Row = 1;
            
            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(layout,["OK","Apply","Cancel"]);
            this.ButtonPanel.ApplyButton.ButtonPushedFcn = @(es,ed) updateTime(this);
            this.ButtonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.ButtonPanel.CancelButton.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this);

            % Set size
            this.UIFigure.Position(3:4) = [460 180];
        end

        function updateTime(this)
            % Update time
            this.Time = this.TimeContainer.Value;

            % Update time units
            this.TimeUnits = this.TimeContainer.Unit;

            % Notify event
            notify(this,"TimeChanged");

            % Execute callback if specified
            if ~isempty(this.TimeChangedFcn)
                eventData = controllib.chart.internal.utils.GenericEventData;
                eventData.Data.Time = this.Time;
                eventData.Data.TimeUnits = this.TimeUnits;
                this.TimeChangedFcn(this,eventData);
            end
        end

        function cbOKButtonPushed(this)
            updateTime(this);
            close(this);
        end

        function cbCancelButtonPushed(this)
            close(this);
        end
    end
    
    %% Hidden (QE) methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets = qeGetWidgets(this.TimeContainer);
            widgets.OKButton = this.ButtonPanel.OKButton;
            widgets.ApplyButton = this.ButtonPanel.ApplyButton;
            widgets.CancelButton = this.ButtonPanel.CancelButton;
        end
    end
end