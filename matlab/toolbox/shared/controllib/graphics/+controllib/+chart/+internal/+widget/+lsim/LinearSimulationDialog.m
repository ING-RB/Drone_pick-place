classdef LinearSimulationDialog < controllib.ui.internal.dialog.AbstractDialog & ...
                                    matlab.mixin.SetGet
    % Linear Simulation Dialog (LSIM UI)
    
    % Copyright 2023 The MathWorks, Inc.
    properties
        Type {mustBeMember(Type,{'lsim','initial'})} = 'lsim'
        % TargetTag - string
        %   String that can be used to compare current and next target.
        TargetTag string
        Updating = false
    end

    properties (Dependent)
        Data
        SelectedSystem
    end

    properties (Access = protected)
        DataInternal
    end

    properties (Access = private)
        FileMenu
        LoadMenu
        SaveMenu
        EditMenu
        CutMenu
        CopyMenu
        PasteMenu
        DeleteMenu
        HelpMenu
        AboutToolMenu
        TabGroup
        InputSignalsTab
        SelectedSystemDropDown
        InitialStatesTab
        InputWidget
        TimeWidget
        InitialWidget
        InterpolationDropDown
        InterpolationDropDownLabel
        SimulateButton
        CloseButton
    end
    
    events
        SimulateButtonPushed
    end
    
    methods
        function this = LinearSimulationDialog(data,type)
            arguments
                data controllib.chart.internal.widget.lsim.LinearSimulationData
                type {mustBeMember(type,{'lsim','initial'})} = 'lsim'
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Title = m('Controllib:gui:strLinearSimulationTool');
            this.Name = 'LinearSimulationTool';
            this.DataInternal = data;
            this.Type = type;
            
            registerUIListeners(this,...
                addlistener(this,'CloseEvent',@(es,ed) cbCloseEvent(this)),'CloseEventListener');
        end
        
        function updateUI(this)
            if this.IsWidgetValid
                if strcmp(this.Type,'lsim')
                    resizeInputSignals(this.DataInternal);
                    this.SelectedSystemDropDown.Items = [this.DataInternal.SystemNames];
                    updateUI(this.TimeWidget);
                    updateUI(this.InputWidget);
                    this.InterpolationDropDown.Value = char(this.DataInternal.Interpolations{this.SelectedSystem});
                end
                updateUI(this.InitialWidget);
            end
        end

        function pack(this,varargin)
            % Set InputTable and InitialStatesTable to fixed size
            if strcmp(this.Type,'lsim')
                setFixedTableSize(this.InputWidget);
            end
            setFixedTableSize(this.InitialWidget);
            % Turn scrollable off
            if strcmp(this.Type,'lsim')
                this.InputSignalsTab.Scrollable = 'off';
            end
            this.InitialStatesTab.Scrollable = 'off';
            % Pack
            pack@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
            % Set table to auto size
            if strcmp(this.Type,'lsim')
                setAutoTableSize(this.InputWidget);
            end
            setAutoTableSize(this.InitialWidget);
            % Turn scrollable on
            if strcmp(this.Type,'lsim')
                this.InputSignalsTab.Scrollable = 'on';
            end
            this.InitialStatesTab.Scrollable = 'on';
        end        

        function delete(this)
            if strcmp(this.Type,'lsim')
                delete(this.TimeWidget);
                delete(this.InputWidget);
            end
            delete(this.InitialWidget);
        end
        
        function selectTab(this,mode)
            arguments
                this
                mode {mustBeMember(mode,{'initialCondition','inputData'})} = 'inputData'
            end
            switch mode
                case 'inputData'
                    this.TabGroup.SelectedTab = this.InputSignalsTab;
                case 'initialCondition'
                    this.TabGroup.SelectedTab = this.InitialStatesTab;
            end
            cbTabSelectionChanged(this,this.TabGroup);
        end
        
        function loadSession(this,session,filename)
            expectedSessionFields = {'savedStartTimes','savedStepLengths',...
                'savedSimSamples','savedStepLengths','savedStatus','savedInputSignals'};
            if ~all(isfield(session,expectedSessionFields))
                errstr = m('Controllib:gui:errInvalidSessionFile',filename);
                showError(this,errstr);
                return;
            else
                expectedInputFields =  {'Value','Source','SubSource','Column',...
                    'Name','Size','Transposed','Construction','Interval'};
                if ~all(isfield(session.savedInputSignals(1),expectedInputFields))
                    errstr = m('Controllib:gui:errInvalidSessionFile',filename);
                    showError(this,errstr);
                    return;
                end
            end
            if length(this.DataInternal.StartTimes) == length(session.savedStartTimes)
                invalidSession = false;
                for ii = 1:length(session.savedInputSignals)
                    inputSignals = getInputSignals(this.DataInternal,ii);
                    if length(session.savedInputSignals(ii).values) ~= length(inputSignals)
                        invalidSession = ii;
                        break;
                    end
                end
                if ~invalidSession
                    try
                        currentInputSignals = cell(size(this.DataInternal.NumSystems));
                        for ii = 1:this.DataInternal.NumSystems
                            currentInputSignals{ii} = this.DataInternal.getInputSignals(ii);
                        end
                        currentStartTimes = this.DataInternal.StartTimes;
                        currentIntervals = this.DataInternal.Intervals;
                        currentSimulationSamples = this.DataInternal.SimulationSamples;
                        currentStatus = this.DataInternal.Status;
                        for ii = 1:length(session.savedInputSignals)
                            inputSignals = repmat(controllib.chart.internal.widget.lsim.createEmptySignal(),...
                                [1,length(session.savedInputSignals(ii).values)]);
                            for jj = 1:length(inputSignals)
                                inputSignals(jj).Value = session.savedInputSignals(ii).values{jj};
                                inputSignals(jj).Source = session.savedInputSignals(ii).sources{jj};
                                inputSignals(jj).SubSource = session.savedInputSignals(ii).subsources{jj};
                                inputSignals(jj).Column = session.savedInputSignals(ii).columns{jj};
                                inputSignals(jj).Name = session.savedInputSignals(ii).names{jj};
                                inputSignals(jj).Size = session.savedInputSignals(ii).sizes{jj};
                                inputSignals(jj).Transposed = session.savedInputSignals(ii).transposed{jj};
                                inputSignals(jj).Construction = session.savedInputSignals(ii).constructions{jj};
                                inputSignals(jj).Interval = session.savedInputSignals(ii).intervals{jj};
                            end
                            updateInputSignals(this.DataInternal,inputSignals,ii);
                        end
                        this.DataInternal.StartTimes = session.savedStartTimes;
                        this.DataInternal.Intervals = session.savedStepLengths;
                        this.DataInternal.SimulationSamples = session.savedSimSamples;
                        this.DataInternal.Status = session.savedStatus;
                        updateUI(this);
                    catch
                        for ii = 1:this.DataInternal.NumSystems
                            updateInputSignals(this.DataInternal,currentInputSignals{ii},ii);
                        end
                        this.DataInternal.StartTimes = currentStartTimes;
                        this.DataInternal.Intervals = currentIntervals;
                        this.DataInternal.SimulationSamples = currentSimulationSamples;
                        this.DataInternal.Status = currentStatus;
                        errstr = m('Controllib:gui:errInvalidSessionFile',filename);
                        showError(this,errstr);
                        return;
                    end
                else
                    errstr = m('Controllib:gui:errLoadNumInputsMismatch',filename,...
                        this.DataInternal.SystemNames(invalidSession),...
                        num2str(length(session.savedInputSignals(invalidSession).values)),...
                        num2str(length(getInputSignals(this.DataInternal,invalidSession))));
                    showError(this,errstr);
                end
            else
                errstr = m('Controllib:gui:errLoadNumSystemMismatch',filename,...
                    num2str(length(session.savedStartTimes)),...
                    num2str(length(this.DataInternal.StartTimes)));
                showError(this,errstr);
            end
        end
        
        function session = saveSession(this)
            session.savedStartTimes = this.DataInternal.StartTimes;
            session.savedStepLengths = this.DataInternal.Intervals;
            session.savedSimSamples = this.DataInternal.SimulationSamples;
            session.savedStatus = this.DataInternal.Status;
            for ii = 1:this.DataInternal.NumSystems
                signals = this.DataInternal.getInputSignals(ii);
                for jj = 1:length(signals)
                    session.savedInputSignals(ii).values{jj} = signals(jj).Value;
                    session.savedInputSignals(ii).sources{jj} = signals(jj).Source;
                    session.savedInputSignals(ii).subsources{jj} = signals(jj).SubSource;
                    session.savedInputSignals(ii).columns{jj} = signals(jj).Column;
                    session.savedInputSignals(ii).names{jj} = signals(jj).Name;
                    session.savedInputSignals(ii).sizes{jj} = signals(jj).Size;
                    session.savedInputSignals(ii).transposed{jj} = signals(jj).Transposed;
                    session.savedInputSignals(ii).constructions{jj} = signals(jj).Construction;
                    session.savedInputSignals(ii).intervals{jj} = signals(jj).Interval;
                end
            end
            tableData = getSignalsTableData(this.InputWidget);
            session.savedCellData = tableData{:,:};
        end

        function set.SelectedSystem(this,systemIdx)
            this.SelectedSystemDropDown.Value = this.SelectedSystemDropDown.Items(systemIdx);
            updateUI(this);
        end

        function selectedSystem = get.SelectedSystem(this)
            selectedSystem = this.SelectedSystemDropDown.ValueIndex;
        end

        function Data = get.Data(this)
            Data = this.DataInternal;
        end

        function set.Data(this,data)
            this.DataInternal = data;
            updateUI(this);
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Tab Group
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'1x','fit'};
            parentGrid.ColumnWidth = {'1x'};
            parentGrid.Padding = 0;
            parentGrid.RowSpacing = 10;
            parentGrid.Scrollable = 'on';
            this.TabGroup = uitabgroup(parentGrid);
            this.TabGroup.Layout.Row = 1;
            this.TabGroup.Layout.Column = 1;
            this.TabGroup.SelectionChangedFcn = ...
                @(es,ed) cbTabSelectionChanged(this,es);
            if strcmp(this.Type,'lsim')
                % Input Signals Tab
                this.InputSignalsTab = uitab(this.TabGroup);
                this.InputSignalsTab.Title = m('Controllib:gui:strInputSignals');
                this.InputSignalsTab.Scrollable = 'off';
                inputGrid = uigridlayout(this.InputSignalsTab);
                inputGrid.RowHeight = {'fit','fit','1x'};
                inputGrid.ColumnWidth = {'1x'};
                inputGrid.Padding = 0;
                inputGrid.RowSpacing = 0;
                % System Selection
                systemSelectGrid = uigridlayout(inputGrid);
                systemSelectGrid.RowHeight = {'fit'};
                systemSelectGrid.ColumnWidth = {'fit','fit','1x','fit'};
                systemSelectGrid.Layout.Row = 1;
                systemSelectGrid.Layout.Column = 1;
                label = uilabel(systemSelectGrid,'Text',m('Controllib:gui:strSelectedSystemLabel'));
                label.Layout.Row = 1;
                label.Layout.Column = 1;
                dropdown = uidropdown(systemSelectGrid);
                dropdown.Layout.Row = 1;
                dropdown.Layout.Column = 2;
                dropdown.Items = [this.DataInternal.SystemNames];
                dropdown.ValueChangedFcn = ...
                    @(es,ed) cbSelectedSystemDropDownValueChanged(this,es,ed);
                this.SelectedSystemDropDown = dropdown;
                % Time Widget
                this.TimeWidget = controllib.chart.internal.widget.lsim.TimeParameters(inputGrid,this);
                w = getWidget(this.TimeWidget);
                w.Layout.Row = 2;
                % Input Signals Widget
                this.InputWidget = controllib.chart.internal.widget.lsim.InputTable(inputGrid,this);
                w = getWidget(this.InputWidget);
                w.Layout.Row = 3;
                createTableContextMenu(this.InputWidget);
            end
            % Initial States Tab
            this.InitialStatesTab = uitab(this.TabGroup);
            this.InitialStatesTab.Title = m('Controllib:gui:strInitialStates');
            this.InitialStatesTab.Scrollable = 'off';
            initialGrid = uigridlayout(this.InitialStatesTab);
            initialGrid.RowHeight = {'1x'};
            initialGrid.ColumnWidth = {'1x'};
            initialGrid.Padding = 0;
            initialGrid.RowSpacing = 0;
            this.InitialWidget = controllib.chart.internal.widget.lsim.InitialTable(initialGrid,this);
            % Buttons and Interpolation Method
            buttonGrid = uigridlayout(parentGrid);
            buttonGrid.Layout.Row = 2;
            buttonGrid.Layout.Column = 1;
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'fit','fit','1x','fit','fit'};
            buttonGrid.Padding = [10 10 10 0];
            % Interpolation
            if strcmp(this.Type,'lsim')
                % Label
                label = uilabel(buttonGrid,'Text',m('Controllib:gui:strInterpolationMethodLabel'));
                label.Layout.Row = 1;
                label.Layout.Column = 1;
                this.InterpolationDropDownLabel = label;
                % DropDown
                dropdown = uidropdown(buttonGrid);
                dropdown.Layout.Row = 1;
                dropdown.Layout.Column = 2;
                dropdown.Items = {m('Controllib:gui:strAutomatic'),...
                    m('Controllib:gui:strZeroOrderHold'),...
                    m('Controllib:gui:strFirstOrderHold')};
                dropdown.ItemsData = {'auto','zoh','foh'};
                dropdown.Value = char(this.DataInternal.Interpolations{this.SelectedSystem});
                dropdown.ValueChangedFcn = ...
                    @(es,ed) cbInterpolationDropDownValueChanged(this,es,ed);
                this.InterpolationDropDown = dropdown;
            end
            % Simulate Button
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strSimulate'));
            button.Layout.Row = 1;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) notify(this,'SimulateButtonPushed');
            this.SimulateButton = button;
            % Cancel Button
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strClose'));
            button.Layout.Row = 1;
            button.Layout.Column = 5;
            button.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this,es,ed);
            this.CloseButton = button;
            % Menu
            buildMenu(this);
            % Size the dialog
            this.UIFigure.Position(3:4) = [640 490];
            % Add Tags
            widgets = qeGetWidgets(this);
            for widgetName = fieldnames(widgets)'
                w = widgets.(widgetName{1});
                if isprop(w,'Tag')
                    w.Tag = widgetName{1};
                end
            end            
            this.UIFigure.Position(3:4) = [640 550];
        end
        
        function connectUI(this)
            L = addlistener(this,'CloseEvent',@(es,ed) close(this));
            registerUIListeners(this,L,'DialogClose');            
        end
    end
    
    methods (Access = private)
        function buildMenu(this)
            % File
            this.FileMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strFile'));
            this.LoadMenu = uimenu(this.FileMenu,'Text',m('Controllib:gui:strLoadInputTable'));
            this.LoadMenu.MenuSelectedFcn = @(es,ed) cbLoadInputTable(this);
            this.SaveMenu = uimenu(this.FileMenu,'Text',m('Controllib:gui:strSaveInputTable'));
            this.SaveMenu.MenuSelectedFcn = @(es,ed) cbSaveInputTable(this);
            % Edit
            this.EditMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strEdit'));
            this.EditMenu.MenuSelectedFcn = @(es,ed) openContextMenu(this.InputWidget,es,ed);
            this.CutMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strCutSignal'),...
                                      'Tag','CutSignal');
            this.CutMenu.MenuSelectedFcn = @(es,ed) cutSignal(this.InputWidget);
            this.CopyMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strCopySignal'),...
                                       'Tag','CopySignal');
            this.CopyMenu.MenuSelectedFcn = @(es,ed) copySignal(this.InputWidget);
            this.PasteMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strPasteSignal'),...
                                        'Tag','PasteSignal');
            this.PasteMenu.MenuSelectedFcn = @(es,ed) pasteSignal(this.InputWidget);
            this.DeleteMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strDeleteSignal'),...
                                         'Tag','DeleteSignal');
            this.DeleteMenu.MenuSelectedFcn = @(es,ed) deleteSignal(this.InputWidget);
            if strcmp(this.Type,'lsim')
                createTableContextMenu(this.InputWidget);
            end
            % Help
            this.HelpMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strHelp'));
            this.AboutToolMenu = uimenu(this.HelpMenu,'Text',m('Controllib:gui:strAboutLinearSimulationTool'));
            this.AboutToolMenu.MenuSelectedFcn = @(es,ed) callbackHelp(this);
            if strcmp(this.Type,'initial')
                this.FileMenu.Enable = false;
                this.EditMenu.Enable = false;
            end
        end
        
        function cbInterpolationDropDownValueChanged(this,es,~)
            this.DataInternal.Interpolations{this.SelectedSystem} = es.Value;
        end
        
        function cbTabSelectionChanged(this,es)
            if isequal(es.SelectedTab,this.InputSignalsTab)
                this.FileMenu.Enable = true;
                this.EditMenu.Enable = true;
                if strcmp(this.Type,'lsim')
                    this.InterpolationDropDown.Visible = 'on';
                    this.InterpolationDropDownLabel.Visible = 'on';
                end
            else
                this.FileMenu.Enable = false;
                this.EditMenu.Enable = false;
                if strcmp(this.Type,'lsim')
                    this.InterpolationDropDown.Visible = 'off';
                    this.InterpolationDropDownLabel.Visible = 'off';
                end
            end
        end
        
        function callbackHelp(~)
            ctrlguihelp('lsim_overview');
        end
        
        function cbCancelButtonPushed(this,~,~)
            close(this);
            cbCloseEvent(this);
        end
        
        function cbCloseEvent(this)
            if strcmp(this.Type,'lsim')
                closeDialogs(this.TimeWidget);
                closeDialogs(this.InputWidget);
            end
            closeDialogs(this.InitialWidget);
            close(this);
        end

        function cbSelectedSystemDropDownValueChanged(this,~,~)
            updateUI(this);
        end
        
        function cbLoadInputTable(this)
            [filename,pathname] = uigetfile;
            if filename
                try
                    session = load([pathname filename]);
                    loadSession(this,session,filename);
                catch
                    errstr = m('Controllib:gui:errInvalidSessionFile',filename);
                    showError(this,errstr);
                end
            end
        end
        
        function cbSaveInputTable(this)
            session = saveSession(this);
            [filename,pathname] = uiputfile('lsimGUI.mat', ...
                m('Controllib:gui:LsimSelectConditionsFile'));
            if filename
                save(fullfile(pathname,filename),'-struct','session');
            end
        end
        
        function showError(this,errorMessage)
            f = getParentUIFigure(this);
            uialert(f,errorMessage,m('Controllib:gui:strLinearSimulationTool'),...
                            'Icon','error');
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
       
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.TabGroup = this.TabGroup;
            widgets.InputSignalsTab = this.InputSignalsTab;
            widgets.InitialStatesTab = this.InitialStatesTab;
            widgets.InputWidget = this.InputWidget;
            widgets.TimeWidget = this.TimeWidget;
            widgets.InitialWidget = this.InitialWidget;
            widgets.InterpolationDropDown = this.InterpolationDropDown;
            widgets.SimulateButton = this.SimulateButton;
            widgets.CloseButton = this.CloseButton;
            widgets.FileMenu = this.FileMenu;
            widgets.LoadMenu = this.LoadMenu;
            widgets.SaveMenu = this.SaveMenu;
            widgets.EditMenu = this.EditMenu;
            widgets.CutMenu = this.CutMenu;
            widgets.CopyMenu = this.CopyMenu;
            widgets.PasteMenu = this.PasteMenu;
            widgets.DeleteMenu = this.DeleteMenu;
            widgets.HelpMenu = this.HelpMenu;
            widgets.AboutToolMenu = this.AboutToolMenu;
        end
    end
end

function str = m(id,varargin)
str = getString(message(id,varargin{:}));
end