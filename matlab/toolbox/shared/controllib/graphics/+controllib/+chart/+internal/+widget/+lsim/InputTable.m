classdef InputTable < matlab.mixin.SetGet & ...
                        controllib.ui.internal.dialog.MixedInUIListeners
    % Input Table Panel for Linear Simulation Tool
    
    % Copyright 2020-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        SelectedRows
    end
    
    properties (Access = ?controllib.chart.internal.widget.lsim.LinearSimulationDialog)
        CopiedSignal
        CutMenu
        CopyMenu
        PasteMenu
        DeleteMenu
    end
    
    properties (Dependent,SetAccess=private)
        SelectedSystem
        Data
    end

    properties (Access = private)
        Name
        Parent
        LinearSimulationDialog

        Container
        ImportSignalButton
        DesignSignalButton
        SignalsTable
        SummaryLabel
        
        TableVariableNames = {m('Controllib:gui:strChannels'),...
            m('Controllib:gui:strData'),...
            m('Controllib:gui:strVariableDimensions')};
        ImportSignalDlg
        DesignSignalDlg

        NonEditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input-readonly')

        FixedGridSizeForTable = [268 215];
    end
    
    %% Constructor/destructor
    methods
        function this = InputTable(hParent,lsimgui)
            this.Name = 'InputSignalsWidget';
            this.Parent = hParent;
            this.LinearSimulationDialog = lsimgui;
            this.Container = createContainer(this);
            updateTableData(this);
        end

        function delete(this)
            delete(this.ImportSignalDlg);
            delete(this.DesignSignalDlg);
        end
    end

    %% Public methods
    methods        
        function updateUI(this)
            updateTableData(this);
            updateSummary(this);
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportSignalDlg)
                close(this.ImportSignalDlg);
            end
            
            if ~isempty(this.DesignSignalDlg)
                close(this.DesignSignalDlg);
            end
        end
        
        function tableData = getSignalsTableData(this)
            tableData = this.SignalsTable.Data;
        end
        
        function setFixedTableSize(this)
            this.Container.ColumnWidth{2} = this.FixedGridSizeForTable(1);
            this.Container.RowHeight{3} = this.FixedGridSizeForTable(2);
        end
        
        function setAutoTableSize(this)
            this.Container.ColumnWidth{2} = '1x';
            this.Container.RowHeight{3} = '1x';
        end
    end
    
    %% Get/Set
    methods
        % SelectedRow
        function selectedRows = get.SelectedRows(this)
            selectedRows = this.SignalsTable.Selection;
        end

        function SelectedSystem = get.SelectedSystem(this)
            SelectedSystem = this.LinearSimulationDialog.SelectedSystem;
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
            widget.RowHeight = {'fit','fit','1x',55,'fit'};
            widget.ColumnWidth = {'fit','1x','fit','fit'};
            widget.Scrollable = 'off';
            
            % Widget header label
            label = uilabel(widget,'Text',m('Controllib:gui:strSystemInputs'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label.FontWeight = 'bold';
            
            % Table
            signaltable = uitable('Parent',widget);
            signaltable.Layout.Row = 3;
            signaltable.Layout.Column = [1 4];
            signaltable.SelectionType = 'row';
            signaltable.RowStriping = 'off';
            signaltable.ColumnEditable = [false,false,false];
            signaltable.FontSize = 10;
            signaltable.CellSelectionCallback = @(es,ed) cbCellSelectionChanged(this,es,ed);
            addStyle(signaltable,this.NonEditableCellStyle,'column',1:3);
            this.SignalsTable = signaltable;
            
            % Summary
            label = uilabel(widget);
            label.Layout.Row = 4;
            label.Layout.Column = [1 4];
            label.Text = m('Controllib:gui:msgUseImportDesignButtons');
            label.HorizontalAlignment = 'center';
            this.SummaryLabel = label;
            
            % Buttons
            button = uibutton(widget,'Text',m('Controllib:gui:strImportSignalLabel'));
            button.Layout.Row = 5;
            button.Layout.Column = 3;
            button.ButtonPushedFcn = @(es,ed) cbImportSignalButtonPushed(this,es,ed);
            this.ImportSignalButton = button;
            
            button = uibutton(widget,'Text',m('Controllib:gui:strDesignSignalLabel'));
            button.Layout.Row = 5;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) cbDesignSignalButtonPushed(this,es,ed);
            this.DesignSignalButton = button;
            
            % Add Tags
            widgets = qeGetWidgets(this);
            for widgetName = fieldnames(widgets)'
                w = widgets.(widgetName{1});
                if isprop(w,'Tag')
                    w.Tag = widgetName{1};
                end
            end
        end
    end
    
    methods(Access = {?controllib.chart.internal.widget.lsim.ImportSignal, ...
                        ?controllib.chart.internal.widget.lsim.DesignSignal})
        function updateSignals(this,signal)
            % Get selected rows and number of imported signals
            selectedRows = this.SelectedRows;
            importSignalLength = length(signal.Columns);
            selectedSignalLength = length(selectedRows);
            try
                selectedRows = checkSignalLengthValidity(this,...
                    selectedRows,importSignalLength);
                if ~isempty(selectedRows)
                    % Update signal structure
                    inputSignals = repmat(controllib.chart.internal.widget.lsim.createEmptySignal(),...
                        1,importSignalLength);
                    switch signal.Source(1:3)
                        case {'wor','mat'}
                            varName = signal.SubSource;
                            for k = 1:importSignalLength
                                inputSignals(k).Transposed = ...
                                    signal.Transposed;
                                inputSignals(k).Source = ...
                                    signal.Source(1:3);
                                inputSignals(k).SubSource = varName;
                                inputSignals(k).Value = ...
                                    signal.Data(:,signal.Columns(k));
                                inputSignals(k).Construction = ...
                                    signal.Construction;
                                inputSignals(k).Interval = ...
                                    [1 length(inputSignals(k).Value)];
                                inputSignals(k).Column = ...
                                    signal.Columns(k);
                                inputSignals(k).Name = varName;
                                inputSignals(k).Size = size(signal.Data);
                                inputSignals(k).Length = [];
                            end
                        case 'inp'
                            for k = 1:lenimport
                                inputdata(selectedRows(k)).source = copyStruc.tablesources{k}; %#ok<*AGROW>
                                inputdata(selectedRows(k)).values = copyStruc.data{k};
                                inputdata(selectedRows(k)).subsource = copyStruc.subsource{k};
                                inputdata(selectedRows(k)).construction = copyStruc.construction{k};
                                inputdata(selectedRows(k)).interval = copyStruc.intervals(2*k-1:2*k);
                                inputdata(selectedRows(k)).column = copyStruc.columns{k};
                                inputdata(selectedRows(k)).name = copyStruc.names{k};
                                inputdata(selectedRows(k)).transposed = copyStruc.transposed(k);
                                inputdata(selectedRows(k)).size = copyStruc.size(2*k-1:2*k);
                            end
                        case {'xls','csv','asc'}
                            for k=1:length(signal.Columns)
                                inputSignals(k).Transposed = ...
                                    signal.Transposed;
                                inputSignals(k).Source = ...
                                    signal.Source(1:3);
                                inputSignals(k).SubSource = ...
                                    signal.SubSource;
                                inputSignals(k).Value = signal.Data(:,k);
                                inputSignals(k).Construction = ...
                                    signal.Construction;
                                inputSignals(k).Interval = ...
                                    [1 length(inputSignals(k).Value)];
                                inputSignals(k).Column = ...
                                    signal.Columns(k);
                                inputSignals(k).Name = ...
                                    ['Column' char('A'+signal.Columns(k)-1)];
                                inputSignals(k).Size = ...
                                    [length(inputSignals(k).Value) 1];
                                inputSignals(k).Length = [];
                            end
                        case 'sig'
                            for k=1:selectedSignalLength
                                inputSignals(k).Source = ...
                                    signal.Source(1:3);
                                inputSignals(k).SubSource = ...
                                    signal.SubSource;
                                inputSignals(k).Value = signal.Data;
                                inputSignals(k).Construction = ...
                                    signal.Construction;
                                inputSignals(k).Interval = ...
                                    [1 signal.Length];
                                inputSignals(k).Column = 1;
                                inputSignals(k).Name =  signal.SubSource;
                                inputSignals(k).Size = ...
                                    [length(inputSignals(k).Value) 1];
                            end
                    end
                    oldSignals = this.Data.getInputSignals(this.SelectedSystem);
                    updateInputSignals(this.Data,inputSignals,this.SelectedSystem,selectedRows);
                    if this.Data.MinimumSignalIntervals(this.SelectedSystem) < this.Data.SimulationSamples(this.SelectedSystem)
                        strOK = getString(message('Control:general:strOK'));
                        strCancel = getString(message('Control:general:strCancel'));
                        qstr = getString(message('Controllib:gui:msgReduceDataSamples',...
                            num2str(this.Data.MinimumSignalIntervals(this.SelectedSystem))));
                        continueimp = uiconfirm(getParentUIFigure(this),qstr, ...
                            getString(message('Controllib:gui:strLinearSimulationTool')),...
                            'Options',{strOK,strCancel},...
                            'DefaultOption',strOK);
                        if strcmp(continueimp,strCancel)
                            updateInputSignals(this.Data,oldSignals,this.SelectedSystem,selectedRows);
                        else
                            % force input signals to have the new shorter length
                            syncInputSignals(this.Data,this.SelectedSystem);
                        end
                    end
                    updateUI(this);
                end
            catch
                %For uialert
            end
        end
    end
    
    methods(Access = ?controllib.chart.internal.widget.lsim.LinearSimulationDialog)
        function createTableContextMenu(this)
            if ~isempty(ancestor(this.Container,'figure')) && ...
                    isempty(this.SignalsTable.ContextMenu)
                % Context Menu
                this.SignalsTable.ContextMenu = ...
                    uicontextmenu(ancestor(this.Container,'figure'));
                L = addlistener(this.SignalsTable.ContextMenu,'ContextMenuOpening',...
                    @(es,ed) openContextMenu(this,es,ed));
                registerUIListeners(this,L,'ContextMenuOpeningListener');
                % Menu Items
                this.CutMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strCutSignal'),...
                    'Tag','cutsignal');
                this.CutMenu.MenuSelectedFcn = @(es,ed) cutSignal(this);
                this.CopyMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strCopySignal'),...
                    'Tag','copysignal');
                this.CopyMenu.MenuSelectedFcn = @(es,ed) copySignal(this);
                this.PasteMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strPasteSignal'),...
                    'Tag','pastesignal');
                this.PasteMenu.MenuSelectedFcn = @(es,ed) pasteSignal(this);
                this.DeleteMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strDeleteSignal'),...
                    'Tag','deletesignal');
                this.DeleteMenu.MenuSelectedFcn = @(es,ed) deleteSignal(this);
            end
        end
        
        function openContextMenu(this,es,ed)
            if isa(es,'matlab.ui.container.Menu')
                cutMenu = findall(es,'Tag','CutMenu');
                copyMenu = findall(es,'Tag','CopyMenu');
                pasteMenu = findall(es,'Tag','PasteMenu');
                deleteMenu = findall(es,'Tag','DeleteMenu');
            else
                cutMenu = this.CutMenu;
                copyMenu = this.CopyMenu;
                pasteMenu = this.PasteMenu;
                deleteMenu = this.DeleteMenu;

                row = ed.InteractionInformation.DisplayRow;
                col = ed.InteractionInformation.DisplayColumn;
                if isempty([row col])
                    this.SignalsTable.Selection = [];
                else
                    this.SignalsTable.Selection = row;
                end
            end
            
            if ~isempty(this.SignalsTable.Selection)
                set(es.Children,'Enable',true);
                % Cut/Copy/Delete
                if isSelectedSignalEmpty(this)
                    copyMenu.Enable = false;
                    cutMenu.Enable = false;
                    deleteMenu.Enable = false;
                else
                    copyMenu.Enable = true;
                    cutMenu.Enable = true;
                    deleteMenu.Enable = true;
                end
                % Insert/Paste
                if isempty(this.CopiedSignal)
                    pasteMenu.Enable = false;
                else
                    pasteMenu.Enable = true;
                end
            else
                set(es.Children,'Enable',false);
            end
        end
        
        function cutSignal(this)
            signals = this.Data.getInputSignals(this.SelectedSystem);
            this.CopiedSignal = signals(this.SelectedRows);
            resetSignal(this.Data,this.SelectedSystem,this.SelectedRows);
            updateTableData(this);
            updateSummary(this);
        end
        
        function copySignal(this,es,ed) %#ok<*INUSD> 
            signals = this.Data.getInputSignals(this.SelectedSystem);
            this.CopiedSignal = signals(this.SelectedRows);
        end
        
        function pasteSignal(this,es,ed)
            copiedSignalLength = length(this.CopiedSignal);
            selectedRows = checkSignalLengthValidity(this,...
                                this.SelectedRows,copiedSignalLength);
            try %#ok<TRYNC>
                if ~isempty(this.CopiedSignal) && ~isempty(selectedRows)
                    signals = this.Data.getInputSignals(this.SelectedSystem);
                    signals(selectedRows) = this.CopiedSignal;
                    this.Data.setInputSignals(signals,this.SelectedSystem)
                    updateTableData(this);
                    updateSummary(this);
                end
            end
        end
                
        function deleteSignal(this,es,ed)
            resetSignal(this.Data,this.SelectedSystem,this.SelectedRows);
            updateTableData(this);
            updateSummary(this);
        end
    end
    
    methods (Access = private)
        function updateTableData(this)
            n = this.Data.NInputs(this.SelectedSystem);
            channelNames = cell(n,1);
            dataString = repmat({''},n,1);
            variableDimensionsString = repmat({''},n,1);
            for k = 1:n
                % Channel Name Column
                names = this.Data.ChannelNames{this.SelectedSystem};
                if isempty(names{k})
                    channelNames{k} = num2str(k);
                else
                    channelNames{k} = names{k};
                end
                % Data Column
                signals = this.Data.getInputSignals(this.SelectedSystem);
                if ~isempty(signals(k).Value)
                    startIdx = signals(k).Interval(1);
                    endIdx = signals(k).Interval(2);
                    if signals(k).Transposed
                        dataString{k} = [signals(k).Name,...
                            '(',num2str(signals(k).Column),',',...
                            num2str(startIdx),':',...
                            num2str(endIdx),')'];
                    else
                        dataString{k} = [signals(k).Name,...
                            '(',num2str(startIdx),':',...
                            num2str(endIdx),',',...
                            num2str(signals(k).Column),')'];
                    end
                    variableDimensionsString{k} = [num2str(signals(k).Size(1)),...
                        ' x ',num2str(signals(k).Size(2))];
                end
                % Variable Dimensions
                
            end
            tableData = table(channelNames,dataString,variableDimensionsString,...
                'VariableNames',this.TableVariableNames);
            this.SignalsTable.Data = tableData;
        end
        
        function updateSummary(this)
            selectedinputs = this.SelectedRows;
            signals =  this.Data.getInputSignals(this.SelectedSystem);
            selectedSignals = signals(selectedinputs);
            if isscalar(selectedinputs)
                switch selectedSignals.Source
                    case 'xls'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom1',...
                            selectedSignals.SubSource, ...
                            selectedSignals.Construction,...
                            num2str(selectedSignals.Column));
                    case 'asc'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom2',...
                            selectedSignals.SubSource,...
                            selectedSignals.Construction,...
                            selectedSignals.Column);
                    case 'csv'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom3',...
                            selectedSignals.Construction,...
                            num2str(selectedSignals.Column));
                    case 'wor'
                        if selectedSignals.Transposed
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom4',...
                                selectedSignals.SubSource,...
                                num2str(selectedSignals.Column));
                        else
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom5',...
                                selectedSignals.SubSource,...
                                num2str(selectedSignals.Column));
                        end
                    case 'mat'
                        if selectedSignals.Transposed
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom6', ...
                                selectedSignals.SubSource,...
                                selectedSignals.Construction,...
                                num2str(selectedSignals.Column));
                        else
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom7', ...
                                selectedSignals.SubSource,...
                                selectedSignals.Construction,...
                                num2str(selectedSignals.Column));
                        end
                    case 'sig'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom8', ...
                            selectedSignals.SubSource,...
                            selectedSignals.Construction);
                    case 'ini'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom9', ...
                            num2str(selectedSignals.Column));
                    otherwise
                        summaryString = m('Controllib:gui:msgUseImportDesignButtons');
                end
                
            elseif isempty(selectedinputs)
                summaryString = m('Controllib:gui:strNoSelection');
            else
                summaryString = m('Controllib:gui:strMultiSelect');
            end
            this.SummaryLabel.Text = summaryString;
            
        end
        
        function cbImportSignalButtonPushed(this,es,ed)
            if isempty(this.ImportSignalDlg) || ~isvalid(this.ImportSignalDlg)
                this.ImportSignalDlg = controllib.chart.internal.widget.lsim.ImportSignal(this);
            end
            show(this.ImportSignalDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbDesignSignalButtonPushed(this,es,ed)
            if length(this.Data.TimeVectors{this.SelectedSystem}) < 2
                uiconfirm(getParentUIFigure(this),...
                    m('Controllib:gui:LsimTimeVectorLength'),...
                    m('Controllib:gui:strLinearSimulationTool'),...
                    'Icon','error');
                return;
            end
            if isempty(this.DesignSignalDlg) || ~isvalid(this.DesignSignalDlg)
                this.DesignSignalDlg = controllib.chart.internal.widget.lsim.DesignSignal(this);
            elseif ~this.DesignSignalDlg.IsVisible
                updateTimes(this.DesignSignalDlg);
            end
            show(this.DesignSignalDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbCellSelectionChanged(this,es,ed)
            updateSummary(this);
        end
        
        function signalEmpty = isSelectedSignalEmpty(this)
            signalEmpty = true;
            if ~isempty(this.SelectedRows)
                signals = this.Data.getInputSignals(this.SelectedSystem);
                signalEmpty = isempty(signals(this.SelectedRows(1)).Value);
            end
        end
        
        function selectedRows = checkSignalLengthValidity(this,selectedRows,importSignalLength)
            % Error checks based on imported signal and selected rows
            selectedSignalLength = length(selectedRows);
            if importSignalLength == selectedSignalLength
                % Check if sufficient room in table
                if importSignalLength > this.Data.NInputs(this.SelectedSystem) - selectedRows + 1
                    showError(this,m('Controllib:gui:errInsufficientRoomAddSignal'));
                end

                if importSignalLength > 0
                    signals = this.Data.getInputSignals(this.SelectedSystem);
                    if ~all(cellfun(@isempty,...
                            {signals(selectedRows+1:(selectedRows+importSignalLength-1)).Name}))
                        strOK = m('Control:general:strOK');
                        strCancel = m('Control:general:strCancel');
                        f = getParentUIFigure(this);
                        f.WindowStyle = 'modal';
                        overwrite = uiconfirm(getParentUIFigure(this),...
                            m('Controllib:gui:errInsertSignalOverwrite'),...
                            m('Controllib:gui:strLinearSimulationTool'),...
                            'Options',{strOK,strCancel},...
                            'DefaultOption',strOK,...
                            'Icon','question');
                        f.WindowStyle = 'normal';
                        if strcmp(overwrite,strCancel)
                            selectedRows = [];
                            return;
                        end
                    end
                    selectedRows = selectedRows:selectedRows+importSignalLength-1;
                else
                    showError(this,m('Controllib:gui:errNoInputsSelected'));
                end
            elseif importSignalLength ~= 1
                errstr = m('Controllib:gui:errSizeMismatch',...
                    num2str(importSignalLength),num2str(selectedSignalLength));
                showError(this,errstr);
            end
        end
        
        function showError(this,errorMessage)
            f = getParentUIFigure(this);
            uialert(f,errorMessage,m('Controllib:gui:strLinearSimulationTool'),'Icon','error');
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.ImportSignalButton = this.ImportSignalButton;
            widgets.DesignSignalButton = this.DesignSignalButton;
            widgets.SignalsTable = this.SignalsTable;
            widgets.SummaryLabel = this.SummaryLabel;
            widgets.ImportSignalDlg = this.ImportSignalDlg;
            widgets.DesignSignalDlg = this.DesignSignalDlg;
            widgets.CutMenu = this.CutMenu;
            widgets.CopyMenu = this.CopyMenu;
            widgets.PasteMenu = this.PasteMenu;
            widgets.DeleteMenu = this.DeleteMenu;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
