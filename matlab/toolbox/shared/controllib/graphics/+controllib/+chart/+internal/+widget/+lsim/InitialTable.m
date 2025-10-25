classdef InitialTable < matlab.mixin.SetGet
    % Initial Table Panel for Linear Simulation Dialog

    % Copyright 2023-2024 The MathWorks, Inc.   

    %% Properties
    properties (Dependent,SetAccess=private)
        SelectedSystem
        Data
    end

    properties (Access = private)
        Name
        Parent
        LinearSimulationDialog
        Container        
        
        SelectedSystemDropDown
        ImportStateVectorButton
        StatesTable
        NoStateSpaceLabel
     
        TableVariableNames = {m('Controllib:gui:strStateName'),...
            m('Controllib:gui:strInitialValue')};
        ImportStatesDlg
        
        NonEditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input-readonly')
        EditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input');
        
        FixedGridSizeForTable = [241 200];
    end
    
    %% Constructor/destructor
    methods
        function this = InitialTable(hParent,lsimgui)
            arguments
                hParent
                lsimgui controllib.chart.internal.widget.lsim.LinearSimulationDialog
            end
            this.Name = 'InitialStatesWidget';
            this.Parent = hParent;
            this.LinearSimulationDialog = lsimgui;
            this.Container = createContainer(this);
        end
        
        function delete(this)
            delete(this.ImportStatesDlg);
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            updateSystemDropdown(this);
            updateTableData(this);
            if ~isempty(this.ImportStatesDlg) && isvalid(this.ImportStatesDlg)
                updateUI(this.ImportStatesDlg)
            end
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportStatesDlg) && isvalid(this.ImportStatesDlg)
                close(this.ImportStatesDlg);
            end
        end
        
        function setFixedTableSize(this)
            this.Container.ColumnWidth{3} = this.FixedGridSizeForTable(1);
            this.Container.RowHeight{5} = this.FixedGridSizeForTable(2);
        end
        
        function setAutoTableSize(this)
            this.Container.ColumnWidth{3} = '1x';
            this.Container.RowHeight{5} = '1x';
        end
    end

    %% Get/Set
    methods        
        % SelectedSystem
        function selectedSystem = get.SelectedSystem(this)
            selectedSystem = this.SelectedSystemDropDown.ValueIndex;
        end

        % Data
        function Data = get.Data(this)
            Data = this.LinearSimulationDialog.Data;
        end
    end   
    
    %% Protected sealed methods
    methods(Access = protected, Sealed)
        function widget = createContainer(this)
            widget = uigridlayout('Parent',this.Parent);
            widget.RowHeight = {'fit',1,'fit','fit','1x','fit'};
            widget.ColumnWidth = {'fit','fit','1x','fit'};
            widget.Scrollable = 'off';
            
            % System Selection
            label = uilabel(widget,'Text',m('Controllib:gui:strSelectedSystemLabel'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            dropdown = uidropdown(widget);
            dropdown.Layout.Row = 1;
            dropdown.Layout.Column = 2;
            stateIdx = cellfun(@(x) ~isempty(x),this.Data.InitialStates);
            dropdown.Items = [this.Data.SystemNames(stateIdx)];
            dropdown.ValueChangedFcn = ...
                @(es,ed) cbSelectedSystemDropDownValueChanged(this,es,ed);
            this.SelectedSystemDropDown = dropdown;
            % Table header
            label = uilabel(widget,'Text',m('Controllib:gui:strSpecifyInitialStates'));
            label.Layout.Row = 3;
            label.Layout.Column = [1 3];
            label.FontWeight = 'bold';
            % Label for no state space systems
            label = uilabel(widget);
            label.Layout.Row = 4;
            label.Layout.Column = [1 4];
            label.HorizontalAlignment = 'center';
            label.Text = m('Controllib:gui:LsimNoStateSpaceSystems');
            this.NoStateSpaceLabel = label;
            % Table
            statestable = uitable('Parent',widget);
            statestable.Layout.Row = 5;
            statestable.Layout.Column = [1 4];
            statestable.RowStriping = 'off';
            statestable.ColumnEditable = [false,true];
            statestable.FontSize = 10;
            statestable.CellEditCallback = @(es,ed) cbCellEdited(this,es,ed);
            addStyle(statestable,this.NonEditableCellStyle,'column',1);
            addStyle(statestable,this.EditableCellStyle,'column',2);
            this.StatesTable = statestable;
            % Import Button
            button = uibutton(widget,'Text',m('Controllib:gui:strImportStateVectorLabel'));
            button.Layout.Row = 6;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) cbImportStateVectorButtonPushed(this,es,ed);
            this.ImportStateVectorButton = button;
        end
    end
    
    methods (Access = private)
        function updateTableData(this)
            resetInitialStates(this.Data);
            selectedSystem = this.SelectedSystem;
            widget = getWidget(this);
            if ~isempty(selectedSystem)
                names = this.Data.StateNames{selectedSystem};
                values = this.Data.InitialStates{selectedSystem};
                if length(names) < length(values)
                    values = values(1:length(names));
                elseif length(names) > length(values)
                    values = [values;zeros(length(names)-length(values))];
                end
                this.StatesTable.Data = table(names,...                    
                    values,...
                    'VariableNames',this.TableVariableNames);
                this.NoStateSpaceLabel.Visible = 'off';
                widget.RowHeight{4} = 0;
                this.ImportStateVectorButton.Enable = true;
            else
                this.StatesTable.Data = table([],[],...
                    'VariableNames',this.TableVariableNames);
                this.NoStateSpaceLabel.Visible = 'on';
                widget.RowHeight{4} = 'fit';
                this.ImportStateVectorButton.Enable = false;
            end
        end
        
        function updateSystemDropdown(this)
            stateIdx = cellfun(@(x) ~isempty(x),this.Data.InitialStates);
            this.SelectedSystemDropDown.Items = [this.Data.SystemNames(stateIdx)];
        end

        function cbSelectedSystemDropDownValueChanged(this,~,~)
            updateUI(this);
        end
        
        function cbImportStateVectorButtonPushed(this,~,~)
            if isempty(this.ImportStatesDlg) || ~isvalid(this.ImportStatesDlg)
                this.ImportStatesDlg = controllib.chart.internal.widget.lsim.ImportState(this);
            end
            show(this.ImportStatesDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbCellEdited(this,es,ed)
            if isnan(ed.NewData) || ~isfinite(ed.NewData)
                es.Data{ed.Indices(1),ed.Indices(2)} = ed.PreviousData;
            else
                selectedSystem = this.SelectedSystem;
                if ~isempty(selectedSystem)
                    this.Data.InitialStates{selectedSystem} = es.Data{:,2};
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
            widgets.SelectedSystemDropDown = this.SelectedSystemDropDown;
            widgets.ImportStateVectorButton = this.ImportStateVectorButton;
            widgets.StatesTable = this.StatesTable;
            widgets.ImportStatesDlg = this.ImportStatesDlg;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
