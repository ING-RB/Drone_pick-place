classdef VariableSelectorGC < ctrluis.paramtable.AbstractGC
    %
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties(Access=private)
        
        % Misc. variable selector widgets
        Widgets = struct(...
            'DialogLayout',[], ...
            'VariableSearchPanel',[], ...
            'VariableSearchPanelLayout',[], ...
            'VariableSearchFilterInstructionLabel',[], ...
            'VariableSearchNameEdit',[], ...
            'VariableSearchFilterList',[], ...
            'VariablesTable',[], ...
            'ExpressionPanel',[], ...
            'ExpressionPanelLayout',[], ...
            'ExpressionInstructionLabel',[],...
            'ExpressionTextEdit',[],...
            'ButtonsPanel',[] ...
            );
        
        % One of {'var','state'} to specify whether selector is for
        % variables or states
        Configuration 
        
        % Structure with labels to use when creating the dialog
        Labels
        
        % Flag indicating dialog should be modal
        Modal
        
        % Map file for the help button.
        MapFile
    end
    
    events(NotifyAccess = 'private', ListenAccess = 'public')
        % Notify listeners that dialog is being closed
        
        ActionPerformed  
    end
    
    %% Constructor
    methods
        function this = VariableSelectorGC(tcpeer)
            %% VariableSelectorGC Constructs VariableSelector graphical component
            
            % Call parent constructor.
            this = this@ctrluis.paramtable.AbstractGC(tcpeer);
            
            % Set property values.
            this.Configuration = 'var';
            this.Labels = struct(...
                'lblTitle',  getString(message('Controllib:gui:lblVariableSelector_Variables')), ...
                'lblFilter', getString(message('Controllib:gui:lblVariableSelector_FilterByName')), ...
                'lblName',   getString(message('Controllib:gui:lblDesignVariableTable_Variables')), ...
                'lblValue',  getString(message('Controllib:gui:lblDesignVariableSelectorTable_CurrentValue')), ...
                'lblUsedBy', getString(message('Controllib:gui:lblDesignVariableSelectorTable_UsedBy')) ...
                );
            this.Modal = false;
            this.MapFile = 'slcontrol';            
        end
    end
    
    %% Public methods (inherited).
    methods
        function setMapFile(this,file)
            %% Set map file.
            
            file = validatestring(file, {'slcontrol','sldo'});
            this.MapFile = file;
        end
        
        function updateUI(this)
            %% UPDATEUI Pushes data to the graphical display.
            
            % Return if the UI is not yet constructed.
            if ~this.IsWidgetValid
                return
            end
            
            % Get list of variables to select to display in table.
            tbl = this.Widgets.VariablesTable;
            data = this.TCPeer.CandidateVariables;
            fStr = this.Widgets.VariableSearchNameEdit.Value;
            
            fMode = this.Widgets.VariableSearchFilterList.Value;
            if ~isempty(fStr)
                data = localFilterCandidateVariables(data,fStr,fMode);
            end
            data = localFormatCandidateVariables(data);
            if isempty(data)
                tbl.Data = [];
            else
                if isVar(this)
                    data(:,4) = updateForDisplay(data(:,4));
                    tbl.Data = data;
                else
                    tbl.Data = data(:,1:3);
                end
            end
        end
    end
    
    %% Public methods (own).
    methods
        
        function setConfiguration(this,cfg,labels,modal)
            %% SETCONFIGURATION Sets configuration values.
            %
            
            if nargin > 1
                this.Configuration = cfg;
            end
            if nargin > 2
                this.Labels = labels;
            end
            if nargin > 3
                this.Modal = modal;
            end
        end
        
        function cfg = getConfiguration(this)
            %% GETCONFIGURATION Returns configuration structure.
            
            cfg = struct(...
                'Configuration',this.Configuration, ...
                'Labels',this.Labels);
        end
        
    end    
    
    %% Protected methods (inherited).
    methods(Access = protected)
        
        function buildUI(this)
            %% CEATEPANEL Constructs dialog.
            
            createDialogLayout(this)
            createVariableSearchPanel(this)
            createVariablesTable(this)
            if isVar(this)
                createExpressionPanel(this)
            end
            createButtonsPanel(this)
        end        
    end
    
    %% Hidden QE methods.
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            %% QEGETWIDGETS Returns widget structure.
            
            wdgts = this.Widgets;
        end
    end
    
    %% Private methods.
    methods(Access=private)
        
        function createDialogLayout(this)
            %% CREATEDIALOGLAYOUT Creates the main layout for the dialog.
            
            this.Name  = sprintf('dlgVariableSelector(%s)',this.Configuration);
            this.UIFigure.Name = this.Labels.lblTitle;
            this.UIFigure.Position(3:4) = [550 230];
            layout = uigridlayout(this.UIFigure,[4 1]);
            layout.ColumnWidth = {'1x'};
            layout.RowHeight = {'fit','1x','fit','fit'};
            layout.Scrollable = 'on';
            layout.RowSpacing = 5;
            layout.ColumnSpacing = 5;
            layout.Padding = 5;
            
            this.Widgets.DialogLayout = layout;
        end
        
        function createVariableSearchPanel(this)
            %% CREATEVARIABLESEARCHPANEL Creates variable search panel.
            % It constructs components for searching a specific
            % variable/state.
            
            createVarSrchPanel(this)
            createVarSrchPanelLayout(this)
            createVarSrchInstructionLabel(this)
            createVarSrchTextEditField(this)
            createVarSrchFilterListBox(this)
        end
        
        function createVarSrchPanel(this)
            %% CREATEVARSRCHPANEL Creates container for variable search panel.
            
            panel = uipanel(this.Widgets.DialogLayout,'Tag','variableSearchPanel');
            panel.BorderType = 'none';
            panel.Layout.Row = 1;
            panel.Layout.Column = 1;
            
            this.Widgets.VariableSearchPanel = panel;
        end
        
        function createVarSrchPanelLayout(this)
            %% CREATEVARSRCHPANELLAYOUT Creates layout for variable search panel.
            
            layout = uigridlayout(this.Widgets.VariableSearchPanel,[2 2]);
            layout.RowSpacing = 5;
            layout.ColumnSpacing = 0;
            layout.Padding = 0;
            layout.ColumnWidth = {'1x',20};
            layout.RowHeight = {'fit','fit'};
            
            this.Widgets.VariableSearchPanelLayout = layout;
        end
        
        function createVarSrchInstructionLabel(this)
            %% CREATEVARSRCHINSTRUCTIONLABEL Creates variable filter label.
            % It creates instruction label for searching a variable/state.
            
            filterInstructionLabel = uilabel(this.Widgets.VariableSearchPanelLayout, ...
                'Tag', 'filterInstructions', ...
                'Text',this.Labels.lblFilter);
            filterInstructionLabel.Layout.Row = 1;
            filterInstructionLabel.Layout.Column = 1;
            
            this.Widgets.VariableSearchFilterInstructionLabel = filterInstructionLabel;
        end
        
        function createVarSrchTextEditField(this)
            %% CREATEVARSRCHTEXTEDITFIELD Creates variable filter edit field.
            % It creates a text edit field to accept a variable/state name
            % for searching.
            
            varNameEdit = uieditfield(this.Widgets.VariableSearchPanelLayout, ...
                'Tag','filterEditField');
            varNameEdit.Layout.Row = 2;
            varNameEdit.Layout.Column = 1;
            varNameEdit.Interruptible = 'off';
            varNameEdit.ValueChangingFcn = @(src,data)cbFilterChanged(this,src,data);
                        
            this.Widgets.VariableSearchNameEdit = varNameEdit;
        end
        
        function createVarSrchFilterListBox(this)
            %% CREATEVARSRCHFILTERLISTBOX Creates a list of search options.
            % It creates a list of algorithms for searching a
            % variable/state name.
            
            varFilterList = uidropdown(this.Widgets.VariableSearchPanelLayout, ...
                'Tag', 'filterDropdown', ...
                'Items',{getString(message('Controllib:gui:lblVariableSelector_ExactStringSearch')), ...
                getString(message('Controllib:gui:lblVariableSelector_RegExpSearch'))});
            varFilterList.Layout.Row = 2;
            varFilterList.Layout.Column = 2;
            varFilterList.Interruptible = 'off';
            varFilterList.ValueChangedFcn = @(src,data)cbFilterChanged(this,src,data);            
            
            this.Widgets.VariableSearchFilterList = varFilterList;
        end
        
        function createVariablesTable(this)
            %% CREATEVARIABLESTABLE Creates table for the signals.
            
            % Set specific table properties for variable and state search.
            if isVar(this)
                columnName = {'',this.Labels.lblName,this.Labels.lblValue, ...
                    this.Labels.lblUsedBy};
                columnWidth = {25,'auto','auto','auto'};
                columnEditable = [true false false false];
                linkColumn = 4;
            else
                columnName = {'',this.Labels.lblName,this.Labels.lblValue};
                columnWidth = {25,'auto','auto'};
                columnEditable = [true false false];
                linkColumn = 2;
            end
            
            % Create the table.
            variableTable = uitable(this.Widgets.DialogLayout, ...
                'ColumnName',columnName, ...
                'ColumnWidth',columnWidth, ...
                'ColumnEditable',columnEditable, ...
                'Tag','variablesTable', ...
                'Interruptible','off', ...
                'RowName','', ...
                'RowStriping','off' ...
                );
            
            % Position the table in the container.
            variableTable.Layout.Row = 2;
            variableTable.Layout.Column = 1;
            
            % Change column color for showing block paths.
            variableTable.removeStyle()
            variableTable.addStyle(uistyle('FontColor', '#0000FF'),'column', linkColumn)
            
            % Install listener for design variables table events.
            variableTable.CellEditCallback = @(src,data)cbTableChanged(this,data);
            
            % Install listener for Candidate Variables hyperlink activation
            % events.
            variableTable.CellSelectionCallback = @(src,data)cbUsedByHyperLink(this,data);
                        
            % Add handle to the widget-reference.
            this.Widgets.VariablesTable = variableTable;
        end
        
        function createExpressionPanel(this)
            %% CREATEEXPRESSIONPANEL Creates expression search panel.
            % It creates a panel to accept an expression for a parameter
            % name.
            
            createExpPanel(this)
            createExpPanelLayout(this)
            createExpInstructionLabel(this)
            createExpTextEditField(this)            
        end
        
        function createExpPanel(this)
            %% CREATEEXPPANEL Creates expression search panel container.
            
            panel = uipanel(this.Widgets.DialogLayout,'Tag','expressionPanel');
            panel.BorderType = 'none';
            panel.Layout.Row = 3;
            panel.Layout.Column = 1;
            
            this.Widgets.ExpressionPanel = panel;
        end
        
        function createExpPanelLayout(this)
            %% CREATEEXPPANELLAYOUT Creates expression search panel layout.
            
            layout = uigridlayout(this.Widgets.ExpressionPanel,[2 1]);
            layout.RowSpacing = 5;
            layout.ColumnSpacing = 0;
            layout.Padding = 0;
            layout.ColumnWidth = {'1x'};
            layout.RowHeight = {'fit','fit'};
            
            this.Widgets.ExpressionPanelLayout = layout;
        end
        
        function createExpInstructionLabel(this)
            %% CREATEEXPINSTRUCTIONLABEL Creates expression search label.
            % It creates an instruction label for the expression search
            % panel.
            
            instructionLabel = uilabel(this.Widgets.ExpressionPanelLayout, ...
                'Text',getString(message('Controllib:gui:lblDesignVariable_SpecifyExpression')));
            instructionLabel.Layout.Row = 1;
            instructionLabel.Layout.Column = 1;
            
            this.Widgets.ExpressionInstructionLabel = instructionLabel;
        end
        
        function createExpTextEditField(this)
            %% CREATEEXPTEXTEDITFIELD Creates expression edit field.
            % It creates an edit field for accepting a parameter
            % expression.
            
            expressionEdit = uieditfield(this.Widgets.ExpressionPanelLayout, ...
                'Tag', 'expressionEdit');
            expressionEdit.Layout.Row = 2;
            expressionEdit.Layout.Column = 1;
            expressionEdit.Interruptible = 'off';
            expressionEdit.ValueChangedFcn = ...
                @(src,data)cbVariableExpressionChanged(this,data);            
            
            this.Widgets.ExpressionTextEdit = expressionEdit;
        end
        
        function createButtonsPanel(this)
            %% CREATEBUTTONSPANEL Creates button a panel at the bottom.
            % The button panel includes help, ok, and cancel buttons.
            
            % Create equal-width button panel.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.Widgets.DialogLayout,["help" "ok" "cancel"]);
            this.Widgets.ButtonsPanel = buttonPanel;
            
            % Set button panel location in the dialog.
            buttonLayout = getWidget(buttonPanel);
            buttonLayout.Layout.Row = 4;
            buttonLayout.Layout.Column = 1;
            
            % Attach callback functions.
            buttonPanel.HelpButton.ButtonPushedFcn = @(src,data) cbHelpButton(this);            
            buttonPanel.OKButton.ButtonPushedFcn = @(src,data) cbOKButton(this);            
            buttonPanel.CancelButton.ButtonPushedFcn = @(src,data) cbCancelButton(this);               
        end
        
        function selectRow(this,row)
            %% Select the specified row.
            
            this.Widgets.VariablesTable.Selection = [row 1;row 2; row 3; row 4];
        end
        
        function cbTableChanged(this,hData)
            %% CBTABLECHANGED Manages table change events.
            
            selectRow(this,hData.Indices(1))
            if hData.Indices(2) == 1
                % Selected column changed.
                
                % Get the selected variable list from the table.
                tbl = this.Widgets.VariablesTable;
                [Vars,sVars,usedBy] = localParseTableData(isVar(this),tbl.Data);
                
                % Update the peer.
                CV = this.TCPeer.CandidateVariables;
                [~,~,allUB] = localParseTableData(true,localFormatCandidateVariables(CV));
                allVars = CV(:,2);
                allUB = updateForDisplay(allUB);
                for ct=1:numel(Vars)
                    % Needed to find correct index as table may be
                    % filtered, first search on var name then on usedby.
                    iVar = strcmp(allVars,Vars{ct});
                    for ctA = find(iVar')
                        iVar(ctA) = isequal(allUB{ctA},usedBy{ct});
                    end
                    CV{iVar,1} = sVars(ct);
                end
                setCandidateVariables(this.TCPeer,CV);
            end
        end
        
        function cbFilterChanged(this,src,data)
            %% CBFILTERCHANGED Manages filter events.

            src.Value = data.Value;
            updateUI(this)
        end
        
        function cbUsedByHyperLink(this,hData)
            %% CBUSEDBYHYPERLINK Manages UsedBy hyperlink activation events.
            
            %g3456437: quick return if indices are empty. This occurs when
            %the user clicks on an empty space in the table.
            if isempty(hData.Indices)
                return
            end

            selectRow(this,hData.Indices(1))
            col = hData.Indices(2);
            if col==4
                row = hData.Indices(1);
                cp = this.TCPeer.CandidateVariables;
                if strcmp(this.Configuration,'var')
                    usedBy = cp{row,4};
                else
                    usedBy = cp(row,2);
                end
                for ct = 1:numel(usedBy)
                    slcontrollib.internal.utils.dynamicHiliteSystem(usedBy{ct});
                end
            end            
        end
        
        function cbVariableExpressionChanged(this,hData)
            %% CBVARIABLEEXPRESSIONCHANGED Manages expression change events.
            
            newExpr = hData.Source.Value;
            if isempty(newExpr)
                return
            end
            CV = this.TCPeer.CandidateVariables;
            [name,indexing] = strtok(newExpr,'.({');
            idx = strcmp(newExpr,CV(:,2));
            if any(idx) && ~isempty(indexing)
                % Already have exactly this expression, make sure its
                % selected.
                CV{idx,1} = true;
                this.TCPeer.setCandidateVariables(CV);
                this.TCPeer.update;
                return
            end
            idx = strcmp(CV(:,2),name);
            badValue = true;
            if any(idx)
                UsedBy = CV{idx,4};
                try
                    val = sdo.getValueFromModel(getModelName(this), newExpr);
                catch
                    val = 'bad value';
                end
				
                if isnumeric(val) && ~isempty(val) && isreal(val)
                    badValue = false;
                    if isempty(indexing)
                        % Selected a double variable
                        CV{idx,1} = true;
                    else
                        newEntry = {true, newExpr, val, UsedBy};
                        CV = vertcat(newEntry,CV);
                    end
                    % Update candidate parameter list
                    this.TCPeer.setCandidateVariables(CV);
                    this.TCPeer.update;
                end
            end
            if badValue
                % Error
                dlgMsg = getString(message('Controllib:gui:errDesignVariable_BadDesignVarExpression',newExpr));
                dlgTitle = getString(message('Controllib:gui:AddParamTable_ErrorTitle'));
                uialert(this.UIFigure,dlgMsg,dlgTitle,'Icon','error','Modal',true)
            end
        end
        
        function cbOKButton(this)
            %% CBOKBUTTON Manages OK button events.
            %
            
            close(this)
            notify(this, 'ActionPerformed', ctrluis.paramtable.GenericEventData('btnOk'))
        end
        
        function cbHelpButton(this)
            %% CBHELPBUTTON Manage Help button events.
            
            if strcmp(this.Configuration,'var')
                helpview(this.MapFile, 'select_parameters','CSHelpWindow')
            else
                helpview(this.MapFile, 'select_states','CSHelpWindow')
            end
        end
        
        function cbCancelButton(this)
            %% CBCANCELBUTTON Manages Cancel button events.
            
            close(this)
        end
        
        function yes = isVar(this)
            %% ISVAR Returns true for variable configuration.
            
            yes = this.Configuration=="var";
        end
        
        function mdl = getModelName(this)
            %% GETMODELNAME Returns model name.
            
            % Find model from CandidateVariables used-by value.  There
            % should be at least one candidate variable used by the model. 
            CV = this.TCPeer.CandidateVariables;
            for ct = 1:size(CV,1)
                usedby = CV{ct,4};
                if ~isempty(usedby)
                    element = usedby{1};
                    mdl = bdroot(element);
                    break
                end
            end
        end
        
    end
end
%% Local utility functions
function data = localFormatCandidateVariables(data)
%% LOCALFORMATCANDIDATEVARIABLES Convert raw variable data into display data.
%
%    Helper method to convert the tool-component's candidate
%    variable data into data that can be displayed

for ct=1:size(data,1)
    
    ub = data{ct,4};  %UsedBy
    if ~iscell(ub)
        ub = {ub};
    end
    nub = numel(ub);
    if nub == 0
        data{ct,4} = {''};
    elseif nub > 4
        ub(4) = {getString(message('Controllib:gui:lblVariableSelector_MoreUsedBy', ...
            sprintf('%d',nub-4)))};
        ub(5:end) = [];
        data{ct,4} = ub;
    end
    
    val = data{ct,3};  % Current value
    try
        if isnumeric(val) && isreal(val)
            data{ct,3} = mat2str(val,16);
        else
            % Throw error to get into catch.
            error('Controllib:general:UnexpectedError',...
                getString(message('Controllib:general:UnexpectedError', ...
                'Value must be real')))
        end
    catch
        sz = size(val);
        szStr = sprintf('%d',sz(1));
        for ctSZ=2:numel(sz)
            szStr = sprintf('%sx%d',szStr,sz(ctSZ));
        end
        data{ct,3} = sprintf('<%s %s>',szStr,class(val));
    end
end
end
function data = localFilterCandidateVariables(data, fStr, fMode)
%% LOCALFILTERCANDIDATEVARIABLES Filters the candidate variable list.
%
%    Helper method to filter the candidate variable list based
%    on user supplied search string and search method.
%

% Search for match in the variable name itself.  For variables in
% referenced models, don't include the model name or block path.
allNames = data(:,2);
for ct = 1:numel(allNames)
    name = allNames{ct};
    parts = sdo.internal.splitParameterName(name);
    allNames{ct} = parts.name;
end
% Filter the variable list.
if strcmp(fMode,getString(message('Controllib:gui:lblVariableSelector_ExactStringSearch')))
    idx = strncmp(allNames,fStr,length(fStr));
    data = data(idx,:);
elseif strcmp(fMode,getString(message('Controllib:gui:lblVariableSelector_RegExpSearch')))
    idx = cellfun('isempty',regexp(allNames,fStr));
    data = data(~idx,:);
end
end

function [names,idx,usedBy] = localParseTableData(isVar,data)
%% LOCALPARSETABLEDATA Parses table data.

idx    = [data{:,1}];  %Selected
names  = data(:,2);    %Names
if isVar
    usedBy = data(:,4);    %Block paths
    for i = 1:size(usedBy,1)
        if isequal(usedBy{i}, {''})
            usedBy{i} = cell(0,1);
        end
    end
else
    row = size(idx,1);
    usedBy = cell(row,1);
    for i = 1:row
        usedBy{i} = cell(0,1);
    end
end
end

function usedBy = updateForDisplay(usedBy)
%% UPDATEFORDISPLAY Updates parameter block path for table display.

for i = 1:size(usedBy,1)
    usedBy{i} = createDisplayStr(usedBy{i});
end
end

function dispStr = createDisplayStr(usedBy)
%% CREATEDISPLAYSTR Creates block display string.
% It creates a display string for the blocks that use the same parameter.

if isempty(usedBy)
    dispStr = '';
else
    dispStr = usedBy{1};
    if numel(usedBy) > 1
        dispStr = [dispStr ', ...'];
    end
end
end
