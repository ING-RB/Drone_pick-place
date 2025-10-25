classdef TimeParameters < matlab.mixin.SetGet & ...
                          controllib.ui.internal.dialog.MixedInDataListeners
    % Time Parameters Panel in Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = private)
        EndTimes
        NumberOfSamples
        ParentDialog
    end

    properties (Access = public)
        Parent
        Name
        Container
        
        StartTimeEditField
        EndTimeEditField
        IntervalEditField
        NumberOfSamplesLabel
        ImportTimeButton
        
        ImportTimeDlg
        
    end

    properties (Dependent)
        Data
        SelectedSystem
    end

    properties (Access = private)
        LinearSimulationDialog
    end
    
    methods
        function this = TimeParameters(hParent,lsimgui)
            this.Parent = hParent;
            this.LinearSimulationDialog = lsimgui;
            this.Name = 'TimeWidget';
            updateEndTimes(this);
            this.Container = createContainer(this);
            installListeners(this);
        end
        
        function updateUI(this)
            update(this);
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function delete(this)
            if ~isempty(this.ImportTimeDlg)
                delete(this.ImportTimeDlg);
                this.ImportTimeDlg = [];
            end
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportTimeDlg) && isvalid(this.ImportTimeDlg)
                close(this.ImportTimeDlg);
            end
        end

        function SelectedSystem = get.SelectedSystem(this)
            SelectedSystem = this.LinearSimulationDialog.SelectedSystem;
        end

        function Data = get.Data(this)
            Data = this.LinearSimulationDialog.Data;
        end

        function set.Data(this,data)
            this.LinearSimulationDialog.Data = data;
            updateUI(this);
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createContainer(this)
            widget = uigridlayout('Parent',this.Parent);
            widget.RowHeight = {'fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x',10,'fit','1x',10,'fit','1x'};
            widget.Scrollable = 'off';
            % Header label
            label = uilabel(widget,'Text',m('Controllib:gui:strTiming'));
            label.FontWeight = 'bold';
            % Start Time
            label = uilabel(widget,'Text',m('Controllib:gui:strStartTimeLabel',...
                m('Controllib:gui:strSec'),''));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label.HorizontalAlignment = 'left';
            editfield = uieditfield(widget,'numeric');
            editfield.Layout.Row = 3;
            editfield.Layout.Column = 2;
            editfield.Value = this.Data.StartTimes(this.SelectedSystem);
            editfield.ValueChangedFcn = @(es,ed) cbStartTimeChanged(this,es,ed);
            if ~isnan(this.EndTimes(this.SelectedSystem))
                editfield.Limits = [-Inf this.EndTimes(this.SelectedSystem)-this.Data.Intervals(this.SelectedSystem)];
            else %Uninitialized
                editfield.Limits = [-Inf 0];
            end
            editfield.LowerLimitInclusive = 'off';
            this.StartTimeEditField = editfield;
            % End Time
            label = uilabel(widget,'Text',m('Controllib:gui:strEndTimeLabel',...
                m('Controllib:gui:strSec')));
            label.Layout.Row = 3;
            label.Layout.Column = 4;
            label.HorizontalAlignment = 'right';
            editfield = uieditfield(widget,'numeric');
            editfield.Layout.Row = 3;
            editfield.Layout.Column = 5;
            editfield.Limits = [this.Data.StartTimes(this.SelectedSystem)+this.Data.Intervals(this.SelectedSystem) Inf];
            editfield.UpperLimitInclusive = 'off';
            if ~isnan(this.EndTimes(this.SelectedSystem))
                editfield.Value = this.EndTimes(this.SelectedSystem);
            else
                editfield.Value = 0;
            end
            editfield.ValueChangedFcn = @(es,ed) cbEndTimeChanged(this,es,ed);
            this.EndTimeEditField = editfield;
            % Interval
            label = uilabel(widget,'Text',m('Controllib:gui:strIntervalLabel',...
                m('Controllib:gui:strSec')));
            label.Layout.Row = 3;
            label.Layout.Column = 7;
            label.HorizontalAlignment = 'right';
            editGrid = uigridlayout(widget);
            editGrid.Layout.Row = 3;
            editGrid.Layout.Column = 8;
            editGrid.RowHeight = {'fit'};
            editGrid.ColumnWidth = {'1x'};
            editGrid.ColumnSpacing = 0;
            editGrid.Padding = 0;
            editfield = uieditfield(editGrid,'numeric');
            editfield.Layout.Row = 1;
            editfield.Layout.Column = 1;
            editfield.HorizontalAlignment = 'right';
            if ~isnan(this.EndTimes(this.SelectedSystem))
                editfield.Limits = [0 this.EndTimes(this.SelectedSystem)-this.Data.StartTimes(this.SelectedSystem)];
                editfield.LowerLimitInclusive = 'off';
            else %Uninitialized
                editfield.Limits = [0 Inf];
                editfield.Editable = 'off';
            end
            editfield.Value = this.Data.Intervals(this.SelectedSystem);
            editfield.ValueChangedFcn = @(es,ed) cbIntervalChanged(this,es,ed);
            this.IntervalEditField = editfield;
            % Number of Samples
            label = uilabel(widget,'Text',[m('Controllib:gui:strNumberofSamplesLabel'),...
                                            num2str(this.NumberOfSamples(this.SelectedSystem))]);
            label.Layout.Row = 4;
            label.Layout.Column = [1 5];
            this.NumberOfSamplesLabel = label;
            % Import Button
            buttonGrid = uigridlayout(widget);
            buttonGrid.Layout.Row = 4;
            buttonGrid.Layout.Column = 8;
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'1x','fit'};
            buttonGrid.ColumnSpacing = 0;
            buttonGrid.Padding = [0 0 0 0];
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strImportTime'));
            button.Layout.Row = 1;
            button.Layout.Column = 2;
            button.HorizontalAlignment = 'right';
            button.ButtonPushedFcn = @(es,ed) cbImportTimeButtonPushed(this,es,ed);
            this.ImportTimeButton = button;
            % Add Tags
            widgets = qeGetWidgets(this);
            for widgetName = fieldnames(widgets)'
                w = widgets.(widgetName{1});
                if isprop(w,'Tag')
                    w.Tag = widgetName{1};
                end
            end            
        end
        
        function installListeners(this)
            L = addlistener(this.Data,'InputSignalsSynced',@(es,ed) update(this));
            registerDataListeners(this,L,'InputSignalsSyncedListener');
        end
    end
    
    methods (Access = ?controllib.chart.internal.widget.lsim.ImportTime)
        function updateTimeVector(this,timeVector)
            this.Data.TimeVectors{this.SelectedSystem} = timeVector;
            this.EndTimes(this.SelectedSystem) = this.Data.TimeVectors{this.SelectedSystem}(end);
            update(this);
        end        
    end
    
    methods (Access = private)
        function cbEndTimeChanged(this,es,ed) %#ok<*INUSD>
            if isempty(this.Data.TimeVectors{this.SelectedSystem})
                this.IntervalEditField.Editable = 'on';
                this.IntervalEditField.Limits(2) = es.Value;
                this.IntervalEditField.LowerLimitInclusive = 'off';
                this.IntervalEditField.Value = es.Value/10;
                this.Data.Intervals(this.SelectedSystem) = this.IntervalEditField.Value;
            end
            this.Data.SimulationSamples(this.SelectedSystem) = ...
                length(this.Data.StartTimes(this.SelectedSystem):this.Data.Intervals(this.SelectedSystem):es.Value);
            update(this);
        end

        function cbIntervalChanged(this,es,ed)
            this.Data.Intervals(this.SelectedSystem) = es.Value;
            this.Data.SimulationSamples(this.SelectedSystem) = ...
                length(this.Data.StartTimes(this.SelectedSystem):es.Value:this.EndTimes(this.SelectedSystem));
            update(this);
        end

        function cbStartTimeChanged(this,es,ed)
            this.Data.StartTimes(this.SelectedSystem) = es.Value;
            if isempty(this.Data.TimeVectors{this.SelectedSystem})
                this.IntervalEditField.Editable = 'on';
                this.IntervalEditField.Limits(2) = -es.Value;
                this.IntervalEditField.LowerLimitInclusive = 'off';
                this.IntervalEditField.Value = -es.Value/10;
                this.Data.Intervals(this.SelectedSystem) = this.IntervalEditField.Value;
                this.Data.SimulationSamples(this.SelectedSystem) = ...
                    length(es.Value:this.Data.Intervals(this.SelectedSystem):0);
            else
                this.Data.SimulationSamples(this.SelectedSystem) = ...
                    length(es.Value:this.Data.Intervals(this.SelectedSystem):this.EndTimes(this.SelectedSystem));
            end
            update(this);
        end

        function cbImportTimeButtonPushed(this,es,ed)
            if isempty(this.ImportTimeDlg) || ~isvalid(this.ImportTimeDlg)
                this.ImportTimeDlg = controllib.chart.internal.widget.lsim.ImportTime(this);
            end
            show(this.ImportTimeDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function update(this)
            updateEndTimes(this);
            this.EndTimeEditField.Limits(1) = this.Data.Intervals(this.SelectedSystem)+this.Data.StartTimes(this.SelectedSystem);
            if ~isnan(this.EndTimes(this.SelectedSystem))
                this.StartTimeEditField.Limits(2) = this.EndTimes(this.SelectedSystem)-this.Data.Intervals(this.SelectedSystem);
                this.IntervalEditField.Limits(2) = this.EndTimes(this.SelectedSystem)-this.Data.StartTimes(this.SelectedSystem);
                this.IntervalEditField.Editable = 'on';
                this.EndTimeEditField.Value = this.EndTimes(this.SelectedSystem);
            else
                this.StartTimeEditField.Limits(2) = -this.Data.Intervals(this.SelectedSystem);
                this.IntervalEditField.Limits(2) = -this.Data.StartTimes(this.SelectedSystem);
                this.IntervalEditField.Editable = 'off';
                this.EndTimeEditField.Value = 0;
            end
            this.StartTimeEditField.Value = this.Data.StartTimes(this.SelectedSystem);
            this.IntervalEditField.Value = this.Data.Intervals(this.SelectedSystem);
            this.NumberOfSamplesLabel.Text = ...
                [m('Controllib:gui:strNumberofSamplesLabel'),...
                num2str(this.Data.SimulationSamples(this.SelectedSystem))];
        end
        
        function updateEndTimes(this)
            for ii = 1:length(this.Data.TimeVectors)
                if isempty(this.Data.TimeVectors{ii})
                    this.EndTimes(ii) = NaN;
                    this.NumberOfSamples(ii) = 0;
                else
                    this.EndTimes(ii) = this.Data.TimeVectors{ii}(end);
                    this.NumberOfSamples(ii) = length(this.Data.TimeVectors{ii});
                end
            end
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.StartTimeEditField = this.StartTimeEditField;
            widgets.EndTimeEditField = this.EndTimeEditField;
            widgets.IntervalEditField = this.IntervalEditField;
            widgets.ImportTimeButton = this.ImportTimeButton;
            widgets.ImportTimeDlg = this.ImportTimeDlg;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
