classdef viewprefs < controllib.ui.internal.dialog.AbstractDialog & ...
        matlab.mixin.SetGet
    % Preferences dialog for the Linear System Analyzer
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (SetObservable,AbortSet)
        FrequencyUnits          = ''
        FrequencyScale          = ''
        MagnitudeUnits          = ''
        MagnitudeScale          = ''
        PhaseUnits              = ''
        TimeUnits               = ''
        Grid                    = ''
        GridColor               = []
        TitleFontSize           = []
        TitleFontWeight         = ''
        TitleFontAngle          = ''
        XYLabelsFontSize        = []
        XYLabelsFontWeight      = ''
        XYLabelsFontAngle       = ''
        AxesFontSize            = []
        AxesFontWeight          = ''
        AxesFontAngle           = ''
        IOLabelsFontSize        = []
        IOLabelsFontWeight      = ''
        IOLabelsFontAngle       = ''
        AxesForegroundColor     = []
        SettlingTimeThreshold   = []
        RiseTimeLimits          = []
        UnwrapPhase             = ''
        PhaseWrappingBranch     = []
        ComparePhase            = struct('Enable','off','Freq',0,'Phase',0)
        MinGainLimit            = struct('Enable','off','MinGain',0)
        TimeVector              = []
        TimeVectorUnits         = ''
        FrequencyVector         = []
        FrequencyVectorUnits    = ''
        Target
        ToolboxPreferences
        HasSparseModels = false;
    end
    
    properties (Access = private)
        TabGroup
        UnitsTab
        UnitsContainer
        StyleTab
        GridContainer
        FontsContainer
        ColorContainer
        OptionsTab
        TimeResponseContainer
        MagnitudeResponseContainer
        PhaseResponseContainer
        ParametersTab
        TimeVectorContainer
        FrequencyVectorContainer
        HelpButton
        OKButton
        ApplyButton
        CancelButton
        Version
        Listeners
        
        TimeVectorString = '0:0.01:10'
        FrequencyVectorString = 'logspace(0,3,50)'
    end
    
    methods
        function this = viewprefs(Target)
            if nargin > 0
                this.Target = Target;
            end
            initialize(this);
            this.Title = m('Controllib:gui:strLTIViewerPreferences');
        end
        
        function updateUI(this)
            % Set UI Component values to corresponding class property
            % values
            this.UnitsContainer.FrequencyUnits = this.FrequencyUnits;
            this.UnitsContainer.FrequencyScale = this.FrequencyScale;
            this.UnitsContainer.MagnitudeUnits = this.MagnitudeUnits;
            this.UnitsContainer.MagnitudeScale = this.MagnitudeScale;
            this.UnitsContainer.PhaseUnits = this.PhaseUnits;
            this.UnitsContainer.TimeUnits = this.TimeUnits;
            this.GridContainer.Value = this.Grid;
            this.FontsContainer.TitleFontSize = this.TitleFontSize;
            this.FontsContainer.TitleFontWeight = this.TitleFontWeight;
            this.FontsContainer.TitleFontAngle = this.TitleFontAngle;
            this.FontsContainer.XYLabelsFontSize = this.XYLabelsFontSize;
            this.FontsContainer.XYLabelsFontWeight = this.XYLabelsFontWeight;
            this.FontsContainer.XYLabelsFontAngle = this.XYLabelsFontAngle;
            this.FontsContainer.AxesFontSize = this.AxesFontSize;
            this.FontsContainer.AxesFontWeight = this.AxesFontWeight;
            this.FontsContainer.AxesFontAngle = this.AxesFontAngle;
            this.FontsContainer.IOLabelsFontSize = this.IOLabelsFontSize;
            this.FontsContainer.IOLabelsFontWeight = this.IOLabelsFontWeight;
            this.FontsContainer.IOLabelsFontAngle = this.IOLabelsFontAngle;
            this.ColorContainer.Value = this.AxesForegroundColor;
            this.TimeResponseContainer.SettlingTimeThreshold = this.SettlingTimeThreshold;
            this.TimeResponseContainer.RiseTimeLimits = this.RiseTimeLimits;
            this.PhaseResponseContainer.UnwrapPhase = this.UnwrapPhase;
            this.PhaseResponseContainer.PhaseWrappingBranch = this.PhaseWrappingBranch;
            this.PhaseResponseContainer.ComparePhase = this.ComparePhase;
            this.MagnitudeResponseContainer.MinGainLimit = this.MinGainLimit;
            selectTimeVectorRadioButton(this);
            selectFrequencyVectorRadioButton(this);            
        end
        
        function edit(this)
            if this.IsWidgetValid
                updateUI(this);
                show(this);
            else
                show(this,this.Target);
            end
        end
        
        function set.HasSparseModels(this,flag)
            arguments
                this (1,1) cstprefs.viewprefs
                flag (1,1) logical
            end
            this.HasSparseModels = flag;
            if ~isempty(this.TimeVectorContainer)
                this.TimeVectorContainer.AutoRadioButton.Enable = ~flag;
                selectTimeVectorRadioButton(this);
            end
            if ~isempty(this.FrequencyVectorContainer)
                this.FrequencyVectorContainer.AutoRadioButton.Enable = ~flag;
                this.FrequencyVectorContainer.RangeRadioButton.Enable = ~flag;
                selectFrequencyVectorRadioButton(this);
            end
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Parent Grid (UITabGroup and Buttons)
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'1x','fit'};
            parentGrid.ColumnWidth = {'1x'};
            parentGrid.Padding = [0 0 0 0];
            parentGrid.RowSpacing = 0;
            % UITabGroup
            tabGroup = uitabgroup(parentGrid);
            tabGroup.Layout.Row = 1;
            tabGroup.Layout.Column = 1;
            this.TabGroup = tabGroup;
            % Units tab
            this.UnitsTab = uitab(tabGroup);
            this.UnitsTab.Title = m('Controllib:gui:strUnits');
            unitsGrid = uigridlayout(this.UnitsTab);
            unitsGrid.RowHeight = {'fit'};
            unitsGrid.ColumnWidth = {'1x'};
            this.UnitsContainer = controllib.widget.internal.cstprefs.UnitsContainer(...
                'FrequencyUnits','FrequencyScale',...
                'MagnitudeUnits','MagnitudeScale',...
                'TimeUnits','PhaseUnits');
            wdgt = getWidget(this.UnitsContainer);
            wdgt.Parent = unitsGrid;
            % Style tab
            this.StyleTab = uitab(tabGroup);
            this.StyleTab.Title = m('Controllib:gui:strStyle');
            styleGrid = uigridlayout(this.StyleTab);
            styleGrid.RowHeight = {'fit','fit','fit','fit','fit'};
            styleGrid.ColumnWidth = {'fit'};
            this.GridContainer = controllib.widget.internal.cstprefs.GridContainer();
            wdgt = getWidget(this.GridContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = 1;
            this.FontsContainer = controllib.widget.internal.cstprefs.FontsContainer();
            wdgt = getWidget(this.FontsContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 3;
            wdgt.Layout.Column = 1;
            this.ColorContainer = controllib.widget.internal.cstprefs.ColorContainer();
            wdgt = getWidget(this.ColorContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 5;
            wdgt.Layout.Column = 1;
            % Options Tab
            this.OptionsTab = uitab(tabGroup);
            this.OptionsTab.Title = m('Controllib:gui:strOptions');
            optionsGrid = uigridlayout(this.OptionsTab);
            optionsGrid.RowHeight = {'fit','fit','fit','fit'};
            optionsGrid.ColumnWidth = {'fit'};
            this.TimeResponseContainer = controllib.widget.internal.cstprefs.TimeResponseContainer();
            wdgt = getWidget(this.TimeResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 1;
            this.MagnitudeResponseContainer = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();
            this.MagnitudeResponseContainer.ContainerTitle = m('Controllib:gui:strFrequencyResponse');
            wdgt = getWidget(this.MagnitudeResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 3;
            this.PhaseResponseContainer = ...
                controllib.widget.internal.cstprefs.PhaseResponseContainer('WrapPhase');
            this.PhaseResponseContainer.ShowContainerTitle = false;
            wdgt = getWidget(this.PhaseResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 4;
            % Parameters Tab
            this.ParametersTab = uitab(tabGroup);
            this.ParametersTab.Title = m('Controllib:gui:strParameters');
            parametersGrid = uigridlayout(this.ParametersTab);
            parametersGrid.RowHeight = {'fit','fit','fit','fit','fit'};
            parametersGrid.ColumnWidth = {'1x'};
            timeVectorLabel = uilabel(parametersGrid);
            timeVectorLabel.Layout.Row = 1;
            timeVectorLabel.Layout.Column = 1;
            timeVectorLabel.Text = m('Controllib:gui:strTimeVector');
            timeVectorLabel.FontWeight = 'bold';
            wdgt = createTimeVectorContainer(this);
            wdgt.Parent = parametersGrid;
            wdgt.Layout.Row = 2;
            freqVectorLabel = uilabel(parametersGrid);
            freqVectorLabel.Layout.Row = 4;
            freqVectorLabel.Layout.Column = 1;
            freqVectorLabel.Text = m('Controllib:gui:strFrequencyVector');
            freqVectorLabel.FontWeight = 'bold';
            wdgt = createFrequencyVectorContainer(this);
            wdgt.Parent = parametersGrid;
            wdgt.Layout.Row = 5;
            % Buttons
            buttonGrid = uigridlayout(parentGrid);
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
            buttonGrid.Padding = 10;
            buttonGrid.RowSpacing = 0;
            this.HelpButton = uibutton(buttonGrid);
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.Text = m('Controllib:general:strHelp');
            this.HelpButton.ButtonPushedFcn = @(es,ed) callbackHelpButton(this);
            this.OKButton = uibutton(buttonGrid);
            this.OKButton.Layout.Row = 1;
            this.OKButton.Layout.Column = 3;
            this.OKButton.Text = m('Controllib:general:strOK');
            this.OKButton.ButtonPushedFcn = @(es,ed) callbackOKButton(this);
            this.CancelButton = uibutton(buttonGrid);
            this.CancelButton.Layout.Row = 1;
            this.CancelButton.Layout.Column = 4;
            this.CancelButton.Text = m('Controllib:general:strCancel');
            this.CancelButton.ButtonPushedFcn = @(es,ed) callbackCancelButton(this);
            this.ApplyButton = uibutton(buttonGrid);
            this.ApplyButton.Layout.Row = 1;
            this.ApplyButton.Layout.Column = 5;
            this.ApplyButton.Text = m('Controllib:general:strApply');
            this.ApplyButton.ButtonPushedFcn = @(es,ed) callbackApplyButton(this);
            % Dialog size
            this.UIFigure.Position(3:4) = [480 380];
        end
        
        function connectUI(this)
            if ~isempty(this.Target) && isvalid(this.Target)
                L = addlistener(this.Target,'ObjectBeingDestroyed',@(es,ed) delete(this));
                registerUIListeners(this,L,{'TargetDestroyedListener'});
                L = addlistener(this.UnitsContainer,'PhaseUnits','PostSet',...
                    @(es,ed) callbackPhaseUnitsChanged(this,ed));
                registerUIListeners(this,L,{'PhaseUnitsChangedListener'});
                L = addlistener(this.UnitsContainer,'MagnitudeUnits','PostSet',...
                    @(es,ed) callbackMagnitudeUnitsChanged(this,ed));
                registerUIListeners(this,L,{'MagnitudeUnitsChangedListener'});
            end
        end
    end
    
    methods (Access = private)
        function initialize(this)
            % Get a copy of the toolbox preferences
            this.ToolboxPreferences    = cstprefs.tbxprefs;
            
            % Copy relevant toolbox preferences to viewer
            this.FrequencyUnits        = this.ToolboxPreferences.FrequencyUnits;
            this.FrequencyScale        = this.ToolboxPreferences.FrequencyScale;
            this.MagnitudeUnits        = this.ToolboxPreferences.MagnitudeUnits;
            this.MagnitudeScale        = this.ToolboxPreferences.MagnitudeScale;
            this.PhaseUnits            = this.ToolboxPreferences.PhaseUnits;
            this.TimeUnits             = this.ToolboxPreferences.TimeUnits;
            this.GridColor             = this.ToolboxPreferences.GridColor;
            this.Grid                  = this.ToolboxPreferences.Grid;
            this.TitleFontSize         = this.ToolboxPreferences.TitleFontSize;
            this.TitleFontWeight       = this.ToolboxPreferences.TitleFontWeight;
            this.TitleFontAngle        = this.ToolboxPreferences.TitleFontAngle;
            this.XYLabelsFontSize      = this.ToolboxPreferences.XYLabelsFontSize;
            this.XYLabelsFontWeight    = this.ToolboxPreferences.XYLabelsFontWeight;
            this.XYLabelsFontAngle     = this.ToolboxPreferences.XYLabelsFontAngle;
            this.AxesFontSize          = this.ToolboxPreferences.AxesFontSize;
            this.AxesFontWeight        = this.ToolboxPreferences.AxesFontWeight;
            this.AxesFontAngle         = this.ToolboxPreferences.AxesFontAngle;
            this.IOLabelsFontSize      = this.ToolboxPreferences.IOLabelsFontSize;
            this.IOLabelsFontWeight    = this.ToolboxPreferences.IOLabelsFontWeight;
            this.IOLabelsFontAngle     = this.ToolboxPreferences.IOLabelsFontAngle;
            this.AxesForegroundColor   = this.ToolboxPreferences.AxesForegroundColor;
            this.SettlingTimeThreshold = this.ToolboxPreferences.SettlingTimeThreshold;
            this.RiseTimeLimits        = this.ToolboxPreferences.RiseTimeLimits;
            this.UnwrapPhase           = this.ToolboxPreferences.UnwrapPhase;
            this.PhaseWrappingBranch   = this.ToolboxPreferences.PhaseWrappingBranch;
            this.MinGainLimit          = this.ToolboxPreferences.MinGainLimit;
            this.TimeVector            = []; % auto range
            if strcmpi(this.ToolboxPreferences.TimeUnits,'auto')
                this.TimeVectorUnits = 'seconds';
            else
                this.TimeVectorUnits = this.ToolboxPreferences.TimeUnits;
            end
            this.FrequencyVector       = []; % auto range
            if strcmpi(this.ToolboxPreferences.FrequencyUnits,'auto')
                this.FrequencyVectorUnits = 'rad/s';
            else
                this.FrequencyVectorUnits = this.ToolboxPreferences.FrequencyUnits;
            end
            this.Version               = this.ToolboxPreferences.Version;
        end
        
        function updateData(this)
            this.FrequencyUnits        = this.UnitsContainer.FrequencyUnits;
            this.FrequencyScale        = this.UnitsContainer.FrequencyScale;
            this.MagnitudeUnits        = this.UnitsContainer.MagnitudeUnits;
            this.MagnitudeScale        = this.UnitsContainer.MagnitudeScale;
            this.PhaseUnits            = this.UnitsContainer.PhaseUnits;
            this.TimeUnits             = this.UnitsContainer.TimeUnits;
            this.Grid                  = this.GridContainer.Value;
            this.TitleFontSize         = this.FontsContainer.TitleFontSize;
            this.TitleFontWeight       = this.FontsContainer.TitleFontWeight;
            this.TitleFontAngle        = this.FontsContainer.TitleFontAngle;
            this.XYLabelsFontSize      = this.FontsContainer.XYLabelsFontSize;
            this.XYLabelsFontWeight    = this.FontsContainer.XYLabelsFontWeight;
            this.XYLabelsFontAngle     = this.FontsContainer.XYLabelsFontAngle;
            this.AxesFontSize          = this.FontsContainer.AxesFontSize;
            this.AxesFontWeight        = this.FontsContainer.AxesFontWeight;
            this.AxesFontAngle         = this.FontsContainer.AxesFontAngle;
            this.IOLabelsFontSize      = this.FontsContainer.IOLabelsFontSize;
            this.IOLabelsFontWeight    = this.FontsContainer.IOLabelsFontWeight;
            this.IOLabelsFontAngle     = this.FontsContainer.IOLabelsFontAngle;
            this.AxesForegroundColor   = this.ColorContainer.Value;
            this.SettlingTimeThreshold = this.TimeResponseContainer.SettlingTimeThreshold;
            this.RiseTimeLimits        = this.TimeResponseContainer.RiseTimeLimits;
            this.UnwrapPhase           = this.PhaseResponseContainer.UnwrapPhase;
            this.PhaseWrappingBranch   = this.PhaseResponseContainer.PhaseWrappingBranch;
            this.MinGainLimit          = this.MagnitudeResponseContainer.MinGainLimit;
            switch this.TimeVectorContainer.ButtonGroup.SelectedObject.Tag
                case 'timeauto'
                    this.TimeVector = [];
                    if strcmp(this.TimeUnits,'auto')
                        this.TimeVectorUnits = 'seconds';
                    else
                        this.TimeVectorUnits = this.TimeUnits;
                    end
                case 'timestop'
                    this.TimeVector = this.TimeVectorContainer.StopTimeEditField.Value;
                    this.TimeVectorUnits = this.TimeVectorContainer.StopTimeUnitsDropDown.Value;
                case 'timevector'
                    this.TimeVectorString = this.TimeVectorContainer.VectorEditField.Value;
                    this.TimeVector = eval(this.TimeVectorString);
                    this.TimeVectorUnits = this.TimeVectorContainer.VectorUnitsDropDown.Value;
            end
            switch this.FrequencyVectorContainer.ButtonGroup.SelectedObject.Tag
                case 'freqauto'
                    this.FrequencyVector = [];
                    if strcmp(this.FrequencyUnits,'auto')
                        this.FrequencyVectorUnits = 'rad/s';
                    else
                        this.FrequencyVectorUnits = this.FrequencyUnits;
                    end
                case 'freqrange'
                    this.FrequencyVector = {this.FrequencyVectorContainer.RangeStartEditField.Value,...
                        this.FrequencyVectorContainer.RangeStopEditField.Value};
                    this.FrequencyVectorUnits = this.FrequencyVectorContainer.RangeUnitsDropDown.Value;
                case 'freqvector'
                    this.FrequencyVectorString = this.FrequencyVectorContainer.VectorEditField.Value;
                    this.FrequencyVector = eval(this.FrequencyVectorString);
                    this.FrequencyVectorUnits = this.FrequencyVectorContainer.VectorUnitsDropDown.Value;
            end
        end
        
        function callbackHelpButton(this)
            ctrlguihelp('viewer_preferences');
        end
        
        function callbackApplyButton(this)
            updateData(this);
        end
        
        function callbackOKButton(this)
            callbackApplyButton(this);
            close(this);
        end
        
        function callbackCancelButton(this)
            close(this);
        end
        
        function callbackPhaseUnitsChanged(this,ed)
            this.PhaseResponseContainer.PhaseUnits = ed.AffectedObject.PhaseUnits;
        end
        
        function callbackMagnitudeUnitsChanged(this,ed)
            this.MagnitudeResponseContainer.MagnitudeUnits = ed.AffectedObject.MagnitudeUnits;
        end
        
        function callbackTimeVectorSelectionChanged(this)
            switch this.TimeVectorContainer.ButtonGroup.SelectedObject.Tag
                case 'timeauto'
                    this.TimeVectorContainer.StopTimeEditField.Enable = false;
                    this.TimeVectorContainer.StopTimeUnitsDropDown.Enable = false;
                    this.TimeVectorContainer.VectorEditField.Enable = false;
                    this.TimeVectorContainer.VectorUnitsDropDown.Enable = false;
                case 'timestop'
                    this.TimeVectorContainer.StopTimeEditField.Enable = true;
                    this.TimeVectorContainer.StopTimeUnitsDropDown.Enable = true;
                    this.TimeVectorContainer.VectorEditField.Enable = false;
                    this.TimeVectorContainer.VectorUnitsDropDown.Enable = false;
                case 'timevector'
                    this.TimeVectorContainer.StopTimeEditField.Enable = false;
                    this.TimeVectorContainer.StopTimeUnitsDropDown.Enable = false;
                    this.TimeVectorContainer.VectorEditField.Enable = true;
                    this.TimeVectorContainer.VectorUnitsDropDown.Enable = true;
            end
        end
        
        function callbackTimeVectorEditFieldChanged(this,~,ed)
            timeVector = evaluateTimeVectorString(ed.Value,inf);
            if isempty(timeVector)
                this.TimeVectorContainer.VectorEditField.Value = this.TimeVectorString;
            elseif ~isequal(this.TimeVector,timeVector)
                this.TimeVectorString = makeTimeVectorString(timeVector);
                this.TimeVectorContainer.VectorEditField.Value = this.TimeVectorString;
            end
        end
        
        function callbackFrequencyVectorSelectionChanged(this)
            switch this.FrequencyVectorContainer.ButtonGroup.SelectedObject.Tag
                case 'freqauto'
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = false;
                    this.FrequencyVectorContainer.ToLabel.Enable = false;
                    this.FrequencyVectorContainer.RangeStopEditField.Enable = false;
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = false;
                    this.FrequencyVectorContainer.RangeUnitsDropDown.Enable = false;
                    this.FrequencyVectorContainer.VectorEditField.Enable = false;
                    this.FrequencyVectorContainer.VectorUnitsDropDown.Enable = false;
                case 'freqrange'
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = true;
                    this.FrequencyVectorContainer.ToLabel.Enable = true;
                    this.FrequencyVectorContainer.RangeStopEditField.Enable = true;
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = true;
                    this.FrequencyVectorContainer.RangeUnitsDropDown.Enable = true;
                    this.FrequencyVectorContainer.VectorEditField.Enable = false;
                    this.FrequencyVectorContainer.VectorUnitsDropDown.Enable = false;
                case 'freqvector'
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = false;
                    this.FrequencyVectorContainer.ToLabel.Enable = false;
                    this.FrequencyVectorContainer.RangeStopEditField.Enable = false;
                    this.FrequencyVectorContainer.RangeStartEditField.Enable = false;
                    this.FrequencyVectorContainer.RangeUnitsDropDown.Enable = false;
                    this.FrequencyVectorContainer.VectorEditField.Enable = true;
                    this.FrequencyVectorContainer.VectorUnitsDropDown.Enable = true;
            end
        end
        
        function callbackFrequencyRangeStartChanged(this,~,ed)
            this.FrequencyVectorContainer.RangeStopEditField.Limits(1) = ed.Value;
        end
        
        function callbackFrequencyRangeStopChanged(this,~,ed)
            this.FrequencyVectorContainer.RangeStartEditField.Limits(2) = ed.Value;
        end
        
        function callbackFrequencyVectorEditFieldChanged(this,~,ed)
            newval = evaluateFrequencyVectorString(ed.Value,inf);
            if isempty(newval)
                this.FrequencyVectorContainer.VectorEditField.Value = this.FrequencyVectorString;
            elseif ~isequal(this.FrequencyVector,newval)
                frequencyVectorString = makeFrequencyVectorString(newval);
                this.FrequencyVectorContainer.VectorEditField.Value = frequencyVectorString;
            end
        end
        
        function gridLayout = createTimeVectorContainer(this)
            gridLayout = uigridlayout('Parent',[]);
            gridLayout.RowHeight = {25,25,25};
            gridLayout.ColumnWidth = {5,175,'1x','1x'};
            gridLayout.Padding = 0;
            % Button Group
            buttongroup = uibuttongroup(gridLayout);
            buttongroup.Layout.Row = [1 3];
            buttongroup.Layout.Column = 2;
            buttongroup.BorderType = 'none';
            buttongroup.SelectionChangedFcn = ...
                @(es,ed) callbackTimeVectorSelectionChanged(this);
            autoradiobutton = uiradiobutton(buttongroup);
            autoradiobutton.Text = m('Controllib:gui:strGenerateAutomatically');
            autoradiobutton.Position = [2 72 175 22];
            autoradiobutton.Tag = 'timeauto';
            autoradiobutton.Enable = ~this.HasSparseModels;
            stoptimeradiobutton = uiradiobutton(buttongroup);
            stoptimeradiobutton.Text = m('Controllib:gui:strDefineStopTime');
            stoptimeradiobutton.Position = [2 37 175 22];
            stoptimeradiobutton.Tag = 'timestop';
            vectorradiobutton = uiradiobutton(buttongroup);
            vectorradiobutton.Text = m('Controllib:gui:strDefineVector');
            vectorradiobutton.Position = [2 2 175 22];
            vectorradiobutton.Tag = 'timevector';
            % Stop Time
            stoptimeeditfield = uieditfield(gridLayout,'numeric');
            stoptimeeditfield.Layout.Row = 2;
            stoptimeeditfield.Layout.Column = 3;
            stoptimeeditfield.Enable = false;
            stoptimeeditfield.Value = 1;
            stoptimeeditfield.Limits = [0 Inf];
            stoptimeeditfield.LowerLimitInclusive = 'off';
            stoptimeeditfield.UpperLimitInclusive = 'off';
            stoptimeunitsdropdown = uidropdown(gridLayout);
            stoptimeunitsdropdown.Layout.Row = 2;
            stoptimeunitsdropdown.Layout.Column = 4;
            stoptimeunitsdropdown.Enable = false;
            validUnits = controllibutils.utGetValidTimeUnits;
            stoptimeunitsdropdown.ItemsData = validUnits(:,1);
            stoptimeunitsdropdown.Items = cellfun(@(x) m(x),validUnits(:,2),...
                'UniformOutput',false);
            stoptimeunitsdropdown.Value = this.TimeVectorUnits;
            % Time Vector
            vectoreditfield = uieditfield(gridLayout);
            vectoreditfield.Layout.Row = 3;
            vectoreditfield.Layout.Column = 3;
            vectoreditfield.Enable = false;
            vectoreditfield.HorizontalAlignment = 'right';
            vectoreditfield.Value = this.TimeVectorString;
            vectoreditfield.ValueChangedFcn = @(es,ed)...
                callbackTimeVectorEditFieldChanged(this,es,ed);
            vectorunitsdropdown = uidropdown(gridLayout);
            vectorunitsdropdown.Layout.Row = 3;
            vectorunitsdropdown.Layout.Column = 4;
            vectorunitsdropdown.Enable = false;
            vectorunitsdropdown.ItemsData = validUnits(:,1);
            vectorunitsdropdown.Items = cellfun(@(x) m(x),validUnits(:,2),...
                'UniformOutput',false);
            vectorunitsdropdown.Value = this.TimeVectorUnits;
            
            this.TimeVectorContainer.ButtonGroup = buttongroup;
            this.TimeVectorContainer.AutoRadioButton = autoradiobutton;
            this.TimeVectorContainer.StopTimeRadioButton = stoptimeradiobutton;
            this.TimeVectorContainer.VectorRadioButton = vectorradiobutton;
            this.TimeVectorContainer.StopTimeEditField = stoptimeeditfield;
            this.TimeVectorContainer.StopTimeUnitsDropDown = stoptimeunitsdropdown;
            this.TimeVectorContainer.VectorEditField = vectoreditfield;
            this.TimeVectorContainer.VectorUnitsDropDown = vectorunitsdropdown;

            callbackTimeVectorSelectionChanged(this);
        end
        
        function gridLayout = createFrequencyVectorContainer(this)
            gridLayout = uigridlayout('Parent',[]);
            gridLayout.RowHeight = {25,25,25};
            gridLayout.ColumnWidth = {5,175,'0.4x',20,'0.4x','1x'};
            gridLayout.Padding = 0;
            % Button Group
            buttongroup = uibuttongroup(gridLayout);
            buttongroup.Layout.Row = [1 3];
            buttongroup.Layout.Column = 2;
            buttongroup.BorderType = 'none';
            buttongroup.SelectionChangedFcn = ...
                @(es,ed) callbackFrequencyVectorSelectionChanged(this);
            autoradiobutton = uiradiobutton(buttongroup);
            autoradiobutton.Text = m('Controllib:gui:strGenerateAutomatically');
            autoradiobutton.Position = [2 72 175 22];
            autoradiobutton.Tag = 'freqauto';
            autoradiobutton.Enable = ~this.HasSparseModels;
            rangeradiobutton = uiradiobutton(buttongroup);
            rangeradiobutton.Text = m('Controllib:gui:strDefinerange');
            rangeradiobutton.Position = [2 37 175 22];
            rangeradiobutton.Tag = 'freqrange';
            rangeradiobutton.Enable = ~this.HasSparseModels;
            vectorradiobutton = uiradiobutton(buttongroup);
            vectorradiobutton.Text = m('Controllib:gui:strDefineVector');
            vectorradiobutton.Position = [2 2 175 22];
            vectorradiobutton.Tag = 'freqvector';
            % Range
            rangestarteditfield = uieditfield(gridLayout,'numeric');
            rangestarteditfield.Layout.Row = 2;
            rangestarteditfield.Layout.Column = 3;
            rangestarteditfield.Enable = false;
            rangestarteditfield.Limits = [0 1000];
            rangestarteditfield.Value = 1;
            rangestarteditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyRangeStartChanged(this,es,ed);
            label = uilabel(gridLayout,'Text',m('Controllib:gui:strTo'));
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 2;
            label.Layout.Column = 4;
            label.Enable = false;
            rangestopeditfield = uieditfield(gridLayout,'numeric');
            rangestopeditfield.Layout.Row = 2;
            rangestopeditfield.Layout.Column = 5;
            rangestopeditfield.Enable = false;
            rangestopeditfield.Limits = [1 Inf];
            rangestopeditfield.Value = 1000;
            rangestopeditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyRangeStopChanged(this,es,ed);
            rangeunitsdropdown = uidropdown(gridLayout);
            rangeunitsdropdown.Layout.Row = 2;
            rangeunitsdropdown.Layout.Column = 6;
            rangeunitsdropdown.Enable = false;
            validUnits = controllibutils.utGetValidFrequencyUnits;
            rangeunitsdropdown.ItemsData = validUnits(:,1);
            rangeunitsdropdown.Items = cellfun(@(x) m(x),validUnits(:,2),...
                'UniformOutput',false);
            rangeunitsdropdown.Value = this.FrequencyVectorUnits;
            % Time Vector
            vectoreditfield = uieditfield(gridLayout);
            vectoreditfield.Layout.Row = 3;
            vectoreditfield.Layout.Column = [3 5];
            vectoreditfield.Enable = false;
            vectoreditfield.Value = this.FrequencyVectorString;
            vectoreditfield.ValueChangedFcn = ...
                @(es,ed) callbackFrequencyVectorEditFieldChanged(this,es,ed);
            vectorunitsdropdown = uidropdown(gridLayout);
            vectorunitsdropdown.Layout.Row = 3;
            vectorunitsdropdown.Layout.Column = 6;
            vectorunitsdropdown.Enable = false;
            vectorunitsdropdown.ItemsData = validUnits(:,1);
            vectorunitsdropdown.Items = cellfun(@(x) m(x),validUnits(:,2),...
                'UniformOutput',false);
            vectorunitsdropdown.Value = this.FrequencyVectorUnits;
            
            this.FrequencyVectorContainer.ButtonGroup = buttongroup;
            this.FrequencyVectorContainer.ToLabel = label;
            this.FrequencyVectorContainer.AutoRadioButton = autoradiobutton;
            this.FrequencyVectorContainer.RangeRadioButton = rangeradiobutton;
            this.FrequencyVectorContainer.VectorRadioButton = vectorradiobutton;
            this.FrequencyVectorContainer.RangeStartEditField = rangestarteditfield;
            this.FrequencyVectorContainer.RangeStopEditField = rangestopeditfield;
            this.FrequencyVectorContainer.RangeUnitsDropDown = rangeunitsdropdown;
            this.FrequencyVectorContainer.VectorEditField = vectoreditfield;
            this.FrequencyVectorContainer.VectorUnitsDropDown = vectorunitsdropdown;
        end
        
        function selectTimeVectorRadioButton(this)
            if isempty(this.TimeVector) && ~this.HasSparseModels
                this.TimeVectorContainer.AutoRadioButton.Value = true;
            elseif isscalar(this.TimeVector)
                this.TimeVectorContainer.StopTimeRadioButton.Value = true;
                this.TimeVectorContainer.StopTimeEditField.Value = this.TimeVector;
            else
                this.TimeVectorContainer.VectorRadioButton.Value = true;
                if ~isempty(this.TimeVector)
                    this.TimeVectorString = makeTimeVectorString(this.TimeVector);
                end
                this.TimeVectorContainer.VectorEditField.Value = this.TimeVectorString;
            end
            callbackTimeVectorSelectionChanged(this);
        end
        
        function selectFrequencyVectorRadioButton(this)
            if isempty(this.FrequencyVector) && ~this.HasSparseModels
                this.FrequencyVectorContainer.AutoRadioButton.Value = true;
            elseif numel(this.FrequencyVector) == 2 && ~this.HasSparseModels
                this.FrequencyVectorContainer.RangeRadioButton.Value = true;
                this.FrequencyVectorContainer.RangeStartEditField.Value = this.FrequencyVector(1);
                this.FrequencyVectorContainer.RangeStopEditField.Value = this.FrequencyVector(2);
            else
                this.FrequencyVectorContainer.VectorRadioButton.Value = true;
                if ~isempty(this.FrequencyVector)
                    this.FrequencyVectorString = makeFrequencyVectorString(this.FrequencyVector);
                end
                this.FrequencyVectorContainer.VectorEditField.Value = this.FrequencyVectorString;
            end
            callbackFrequencyVectorSelectionChanged(this);
        end
        
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            % Tabs
            widgets.Tabs.TabGroup = this.TabGroup;
            widgets.Tabs.Units = this.UnitsTab;
            widgets.Tabs.Style = this.StyleTab;
            widgets.Tabs.Options = this.OptionsTab;
            widgets.Tabs.Parameters = this.ParametersTab;
            % Buttons
            widgets.Buttons.Help = this.HelpButton;
            widgets.Buttons.OK = this.OKButton;
            widgets.Buttons.Apply = this.ApplyButton;
            widgets.Buttons.Cancel = this.CancelButton;
            % Containers/Panels
            widgets.Units = qeGetWidgets(this.UnitsContainer);
            widgets.Grid = qeGetWidgets(this.GridContainer);
            widgets.Fonts = qeGetWidgets(this.FontsContainer);
            widgets.Color = qeGetWidgets(this.ColorContainer);
            widgets.TimeResponse = qeGetWidgets(this.TimeResponseContainer);
            widgets.MagnitudeResponse = qeGetWidgets(this.MagnitudeResponseContainer);
            widgets.PhaseResponse = qeGetWidgets(this.PhaseResponseContainer);
            widgets.TimeVector = this.TimeVectorContainer;
            widgets.FrequencyVector = this.FrequencyVectorContainer;
        end
        
        function selectedTab = qeGetSelectedTab(this)
            selectedTab = this.TabGroup.SelectedTab;
        end
        
        function selectTab(this,tabName)
            arguments
                this
                tabName char {mustBeMember(tabName,{'Units','Style','Options',...
                                                    'Parameters'})} = 'Units'
            end
            if this.IsWidgetValid
                switch tabName
                    case 'Units'
                        this.TabGroup.SelectedTab = this.UnitsTab;
                    case 'Style'
                        this.TabGroup.SelectedTab = this.StyleTab;
                    case 'Options' 
                        this.TabGroup.SelectedTab = this.OptionsTab;
                    case 'Parameters'
                        this.TabGroup.SelectedTab = this.ParametersTab;
                end
            end
        end
    end
end

function val = evaluateTimeVectorString(str,n)
% Evaluate string val
if ~isempty(str)
    val = evalin('base',str,'[]');
    if ~isnumeric(val) | ~(isreal(val) & isfinite(val))
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

function val = evaluateFrequencyVectorString(str,n)
% Evaluate string val
if ~isempty(str)
    val = evalin('base',str,'[]');
    if ~isnumeric(val) | ~(isreal(val) & isfinite(val))
        val = [];
    else
        val = val(:);
        %---Case: val must be same length as n
        if n<inf && length(val)==n
            %---Make sure val is >0
            if val<=0
                val = [];
            end
            %---Case: val is vector (length>2)
        elseif n==inf && length(val)>2
            %---Make sure all of val is >0
            if ~all(val>0)
                val = [];
            end
        else
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
    tol    = 100*eps*max(val);
    tol10  = 100*eps*max(val10);
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
