classdef ToolboxPreferencePanel < matlab.mixin.SetGet
% Preferences panel for Control System and System Identification toolbox
%
% dlg = controllib.widget.internal.cstrefs.ToolboxPreferencePanel

% Copyright 2020-2023 The MathWorks, Inc.

    properties
        UIFigure
    end
    
    properties (SetObservable,AbortSet)
        ToolboxPreferences
    end
    
    properties (Hidden)
        Listeners
    end
    
    properties (Access = private) 
        TabGroup                    matlab.ui.container.TabGroup
        UnitsTab                    matlab.ui.container.Tab
        UnitsContainer              controllib.widget.internal.cstprefs.UnitsContainer
        StyleTab                    matlab.ui.container.Tab
        GridContainer               controllib.widget.internal.cstprefs.GridContainer
        FontsContainer              controllib.widget.internal.cstprefs.FontsContainer
        ColorContainer              controllib.widget.internal.cstprefs.ColorContainer
        OptionsTab                  matlab.ui.container.Tab
        TimeResponseContainer       controllib.widget.internal.cstprefs.TimeResponseContainer    
        MagnitudeResponseContainer  controllib.widget.internal.cstprefs.MagnitudeResponseContainer
        PhaseResponseContainer      controllib.widget.internal.cstprefs.PhaseResponseContainer
        CSDTab                      matlab.ui.container.Tab
        CompensatorFormatContainer  controllib.widget.internal.cstprefs.CompensatorFormatContainer
        BodeOptionsContainer        controllib.widget.internal.cstprefs.BodeOptionsContainer
        RestoreUnitsButton          matlab.ui.control.Button
        RestoreStyleButton          matlab.ui.control.Button
        RestoreOptionsButton        matlab.ui.control.Button
        RestoreCSDButton            matlab.ui.control.Button
    end
    
    methods
        function this = ToolboxPreferencePanel(tbxprefs,showDialog)
            arguments
                tbxprefs = cstprefs.tbxprefs
                showDialog = true
            end
            initialize(this,tbxprefs);
            buildUI(this,showDialog);
            addListeners(this);
        end
        
        function commitPrefsChanges(this)
            this.ToolboxPreferences.FrequencyUnits        = this.UnitsContainer.FrequencyUnits;
            this.ToolboxPreferences.FrequencyScale        = this.UnitsContainer.FrequencyScale;
            this.ToolboxPreferences.MagnitudeUnits        = this.UnitsContainer.MagnitudeUnits;
            this.ToolboxPreferences.MinGainLimit          = this.MagnitudeResponseContainer.MinGainLimit;
            this.ToolboxPreferences.MagnitudeScale        = this.UnitsContainer.MagnitudeScale;
            this.ToolboxPreferences.PhaseUnits            = this.UnitsContainer.PhaseUnits;
            this.ToolboxPreferences.PhaseWrappingBranch   = this.PhaseResponseContainer.PhaseWrappingBranch;
            this.ToolboxPreferences.TimeUnits             = this.UnitsContainer.TimeUnits;
            this.ToolboxPreferences.Grid                  = this.GridContainer.Value;
            this.ToolboxPreferences.TitleFontSize         = this.FontsContainer.TitleFontSize;
            this.ToolboxPreferences.TitleFontWeight       = this.FontsContainer.TitleFontWeight;
            this.ToolboxPreferences.TitleFontAngle        = this.FontsContainer.TitleFontAngle;
            this.ToolboxPreferences.XYLabelsFontSize      = this.FontsContainer.XYLabelsFontSize;
            this.ToolboxPreferences.XYLabelsFontWeight    = this.FontsContainer.XYLabelsFontWeight;
            this.ToolboxPreferences.XYLabelsFontAngle     = this.FontsContainer.XYLabelsFontAngle;
            this.ToolboxPreferences.AxesFontSize          = this.FontsContainer.AxesFontSize;
            this.ToolboxPreferences.AxesFontWeight        = this.FontsContainer.AxesFontWeight;
            this.ToolboxPreferences.AxesFontAngle         = this.FontsContainer.AxesFontAngle;
            this.ToolboxPreferences.IOLabelsFontSize      = this.FontsContainer.IOLabelsFontSize;
            this.ToolboxPreferences.IOLabelsFontWeight    = this.FontsContainer.IOLabelsFontWeight;
            this.ToolboxPreferences.IOLabelsFontAngle     = this.FontsContainer.IOLabelsFontAngle;
            this.ToolboxPreferences.AxesForegroundColor   = this.ColorContainer.Value;
            this.ToolboxPreferences.SettlingTimeThreshold = this.TimeResponseContainer.SettlingTimeThreshold;
            this.ToolboxPreferences.RiseTimeLimits        = this.TimeResponseContainer.RiseTimeLimits;
            this.ToolboxPreferences.UnwrapPhase           = this.PhaseResponseContainer.UnwrapPhase;
            this.ToolboxPreferences.CompensatorFormat     = this.CompensatorFormatContainer.Value;
            this.ToolboxPreferences.ShowSystemPZ          = this.BodeOptionsContainer.Value;
            save(this.ToolboxPreferences);
        end

        function result = commit(this)
            % API is based on MATLAB Preferences Panel integration
            % standards.
            try
                commitPrefsChanges(this)
                result = true;
            catch ME
                result = false;
            end
        end

        function reset(this)
            %% Reset the tab contents.

            setUnitsToCurrentPrefValues(this)
            setStyleToCurrentPrefValues(this)
            setResponseToCurrentPrefValues(this)
            setCSDToCurrentPrefValues(this)
        end

        function setUnitsToCurrentPrefValues(this)
            %% Sets unit tab contents to current preference values.

            % Update unit contents.
            this.UnitsContainer.FrequencyUnits = this.ToolboxPreferences.FrequencyUnits;
            this.UnitsContainer.FrequencyScale = this.ToolboxPreferences.FrequencyScale;
            this.UnitsContainer.MagnitudeUnits = this.ToolboxPreferences.MagnitudeUnits;
            this.UnitsContainer.MagnitudeScale = this.ToolboxPreferences.MagnitudeScale;
            this.UnitsContainer.PhaseUnits = this.ToolboxPreferences.PhaseUnits;
            this.UnitsContainer.TimeUnits = this.ToolboxPreferences.TimeUnits;            

            % Unit dependents
            this.MagnitudeResponseContainer.MinGainLimit = this.ToolboxPreferences.MinGainLimit;
            this.PhaseResponseContainer.PhaseWrappingBranch = this.ToolboxPreferences.PhaseWrappingBranch;
        end

        function setStyleToCurrentPrefValues(this)
            %% Sets style tab contents to current preference values.

            % Update grid container.
            this.GridContainer.Value = this.ToolboxPreferences.Grid;

            % Update font container.
            this.FontsContainer.TitleFontSize = this.ToolboxPreferences.TitleFontSize;
            this.FontsContainer.TitleFontWeight = this.ToolboxPreferences.TitleFontWeight;
            this.FontsContainer.TitleFontAngle = this.ToolboxPreferences.TitleFontAngle;
            this.FontsContainer.XYLabelsFontSize = this.ToolboxPreferences.XYLabelsFontSize;
            this.FontsContainer.XYLabelsFontWeight = this.ToolboxPreferences.XYLabelsFontWeight;
            this.FontsContainer.XYLabelsFontAngle = this.ToolboxPreferences.XYLabelsFontAngle;
            this.FontsContainer.AxesFontSize = this.ToolboxPreferences.AxesFontSize;
            this.FontsContainer.AxesFontWeight = this.ToolboxPreferences.AxesFontWeight;
            this.FontsContainer.AxesFontAngle = this.ToolboxPreferences.AxesFontAngle;
            this.FontsContainer.IOLabelsFontSize = this.ToolboxPreferences.IOLabelsFontSize;
            this.FontsContainer.IOLabelsFontWeight = this.ToolboxPreferences.IOLabelsFontWeight;
            this.FontsContainer.IOLabelsFontAngle = this.ToolboxPreferences.IOLabelsFontAngle;

            % Update color container.
            this.ColorContainer.Value = this.ToolboxPreferences.AxesForegroundColor;
        end

        function setResponseToCurrentPrefValues(this)
            %% Sets response tab contents to current preference values.

            % Update time response container.
            this.TimeResponseContainer.SettlingTimeThreshold = this.ToolboxPreferences.SettlingTimeThreshold;
            this.TimeResponseContainer.RiseTimeLimits = this.ToolboxPreferences.RiseTimeLimits;

            % Update magnitude response container.
            this.MagnitudeResponseContainer.MinGainLimit = this.ToolboxPreferences.MinGainLimit;
            
            % Update phase response container.
            this.PhaseResponseContainer.UnwrapPhase = this.ToolboxPreferences.UnwrapPhase;
            this.PhaseResponseContainer.PhaseWrappingBranch = this.ToolboxPreferences.PhaseWrappingBranch;            
        end

        function setCSDToCurrentPrefValues(this)
            %% Sets response tab contents to current preference values.

            % Update compensator format container.            
            this.CompensatorFormatContainer.Value = this.ToolboxPreferences.CompensatorFormat;

            % Update bode options container.            
            this.BodeOptionsContainer.Value = this.ToolboxPreferences.ShowSystemPZ;
        end
        
        function restoreUnitPreferences(this)
            %% Restore unit preferences to default factory values.
            
            % Update unit contents.
            units = this.ToolboxPreferences.GraphicsSettings.units;

            this.UnitsContainer.FrequencyUnits = units.FrequencyUnits.FactoryValue;
            this.UnitsContainer.FrequencyScale = units.FrequencyScale.FactoryValue;
            this.UnitsContainer.MagnitudeUnits = units.MagnitudeUnits.FactoryValue;
            this.UnitsContainer.MagnitudeScale = units.MagnitudeScale.FactoryValue;
            this.UnitsContainer.PhaseUnits = units.PhaseUnits.FactoryValue;
            this.UnitsContainer.TimeUnits = units.TimeUnits.FactoryValue;            

            % Unit dependents
            minGainLimit.MinGain = this.ToolboxPreferences.GraphicsSettings.response.MinimumGainValue.FactoryValue;
            minGainLimit.Enable = this.ToolboxPreferences.GraphicsSettings.response.MinimumGainEnabled.FactoryValue;
            this.MagnitudeResponseContainer.MinGainLimit = minGainLimit;
            this.PhaseResponseContainer.PhaseWrappingBranch = ...
                this.ToolboxPreferences.GraphicsSettings.response.PhaseWrappingBranch.FactoryValue;
        end
        
        function restoreStylePreferences(this)
            %% Restore style preferences to default factory values.
            
            style = this.ToolboxPreferences.GraphicsSettings.style;

            % Update grid container.
            this.GridContainer.Value = style.Grid.FactoryValue;

            % Update font container.
            this.FontsContainer.TitleFontSize = this.ToolboxPreferences.TitleFontSizeFactoryValue;
            this.FontsContainer.TitleFontWeight = this.ToolboxPreferences.TitleFontWeightFactoryValue;
            this.FontsContainer.TitleFontAngle = style.TitleFontAngle.FactoryValue;
            this.FontsContainer.XYLabelsFontSize = this.ToolboxPreferences.XYLabelsFontSizeFactoryValue;
            this.FontsContainer.XYLabelsFontWeight = style.XYLabelsFontWeight.FactoryValue;
            this.FontsContainer.XYLabelsFontAngle = style.XYLabelsFontAngle.FactoryValue;
            this.FontsContainer.AxesFontSize = this.ToolboxPreferences.AxesFontSizeFactoryValue;
            this.FontsContainer.AxesFontWeight = style.AxesFontWeight.FactoryValue;
            this.FontsContainer.AxesFontAngle = style.AxesFontAngle.FactoryValue;
            this.FontsContainer.IOLabelsFontSize = this.ToolboxPreferences.IOLabelsFontSizeFactoryValue;
            this.FontsContainer.IOLabelsFontWeight = style.IOLabelsFontWeight.FactoryValue;
            this.FontsContainer.IOLabelsFontAngle = style.IOLabelsFontAngle.FactoryValue;

            % Update color container.
            this.ColorContainer.Value = style.AxesForegroundColor.FactoryValue;
        end

        function restoreResponsePreferences(this)
            %% Restore response preferences to default factory values.
            response = this.ToolboxPreferences.GraphicsSettings.response;

            % Update time response container.
            this.TimeResponseContainer.SettlingTimeThreshold = response.SettlingTimeThreshold.FactoryValue;
            this.TimeResponseContainer.RiseTimeLimits = response.RiseTimeLimits.FactoryValue;

            % Update magnitude response container.
            minGainLimit.MinGain = this.ToolboxPreferences.GraphicsSettings.response.MinimumGainValue.FactoryValue;
            minGainLimit.Enable = this.ToolboxPreferences.GraphicsSettings.response.MinimumGainEnabled.FactoryValue;
            this.MagnitudeResponseContainer.MinGainLimit = minGainLimit;
            
            % Update phase response container.
            if strcmp(response.PhaseWrappingEnabled.FactoryValue,'on')
                this.PhaseResponseContainer.UnwrapPhase = 'off';
            else
                this.PhaseResponseContainer.UnwrapPhase = 'on';
            end
            this.PhaseResponseContainer.PhaseWrappingBranch = response.PhaseWrappingBranch.FactoryValue;            
        end        

        function restoreCSDPreferences(this)
            %% Restore CSD preferences to default factory values.
            csdesigner = this.ToolboxPreferences.GraphicsSettings.csdesigner;
            
            % Update compensator format container.            
            this.CompensatorFormatContainer.Value = csdesigner.CompensatorFormat.FactoryValue;

            % Update bode options container.            
            this.BodeOptionsContainer.Value = csdesigner.ShowSystemPZ.FactoryValue;
        end        

        function delete(this)
            delete(this.Listeners)
            delete(this.UIFigure);
        end

        function buttons = getRestoreDefaultButtons(this)
            buttons.RestoreUnitsButton = this.RestoreUnitsButton;
            buttons.RestoreStyleButton = this.RestoreStyleButton;
            buttons.RestoreOptionsButton = this.RestoreOptionsButton;
            buttons.RestoreCSDButton = this.RestoreCSDButton;
        end
    end
    
    methods (Access = private)
        function buildUI(this,showDialog)
            this.UIFigure = uifigure("Visible",showDialog);
            this.UIFigure.Position(3:4) = [430 360];
            % Parent Grid (UITabGroup and Buttons)
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'1x'};
            parentGrid.ColumnWidth = {'1x'};
            parentGrid.Padding = [0 0 0 0];
            parentGrid.RowSpacing = 0;
            % UITabGroup
            tabGroup = uitabgroup(parentGrid);
            this.TabGroup = tabGroup;
            % Units tab
            this.UnitsTab = uitab(tabGroup);
            this.UnitsTab.Title = getString(message('Controllib:gui:strUnits'));
            unitsGrid = uigridlayout(this.UnitsTab);
            unitsGrid.RowHeight = {'fit','1x','fit'};
            unitsGrid.ColumnWidth = {'1x','fit'};
            unitsGrid.Padding = [10 10 10 10];
            this.UnitsContainer = controllib.widget.internal.cstprefs.UnitsContainer(...
                                    'FrequencyUnits','FrequencyScale',...
                                    'MagnitudeUnits','MagnitudeScale',...
                                    'TimeUnits','PhaseUnits');
            wdgt = getWidget(this.UnitsContainer);
            wdgt.Parent = unitsGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = [1 2];
            this.RestoreUnitsButton = createRestoreDefaultButton(unitsGrid,3,2);
            this.RestoreUnitsButton.ButtonPushedFcn = @(s,e)restoreUnitPreferences(this);
            % Style tab
            this.StyleTab = uitab(tabGroup);
            this.StyleTab.Title = getString(message('Controllib:gui:strStyle'));
            styleGrid = uigridlayout(this.StyleTab);
            styleGrid.RowHeight = {'fit','fit','fit','fit','fit','1x','fit'};
            styleGrid.ColumnWidth = {'1x','fit'};
            styleGrid.Padding = [10 10 10 10];
            this.GridContainer = controllib.widget.internal.cstprefs.GridContainer();
            wdgt = getWidget(this.GridContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = [1 2];
            this.FontsContainer = controllib.widget.internal.cstprefs.FontsContainer();
            wdgt = getWidget(this.FontsContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 3;
            wdgt.Layout.Column = [1 2];
            this.ColorContainer = controllib.widget.internal.cstprefs.ColorContainer();
            wdgt = getWidget(this.ColorContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 5;
            wdgt.Layout.Column = [1 2];
            this.RestoreStyleButton = createRestoreDefaultButton(styleGrid,7,2);
            this.RestoreStyleButton.ButtonPushedFcn = @(s,e)restoreStylePreferences(this);
            % Options Tab
            this.OptionsTab = uitab(tabGroup);
            this.OptionsTab.Title = getString(message('Controllib:gui:strResponse'));
            optionsGrid = uigridlayout(this.OptionsTab);
            optionsGrid.RowHeight = {'fit','fit','fit','fit','1x','fit'};
            optionsGrid.ColumnWidth = {'1x','fit'};
            optionsGrid.Padding = [10 10 10 10];
            this.TimeResponseContainer = controllib.widget.internal.cstprefs.TimeResponseContainer();
            wdgt = getWidget(this.TimeResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = [1 2];
            this.MagnitudeResponseContainer = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();
            this.MagnitudeResponseContainer.ContainerTitle = ...
                getString(message('Controllib:gui:strFrequencyResponse'));
            wdgt = getWidget(this.MagnitudeResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 3;
            wdgt.Layout.Column = [1 2];
            this.PhaseResponseContainer = ...
                controllib.widget.internal.cstprefs.PhaseResponseContainer('WrapPhase');
            this.PhaseResponseContainer.ShowContainerTitle = false;
            wdgt = getWidget(this.PhaseResponseContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 4;
            wdgt.Layout.Column = [1 2];
            this.RestoreOptionsButton = createRestoreDefaultButton(optionsGrid,6,2);
            this.RestoreOptionsButton.ButtonPushedFcn = @(s,e)restoreResponsePreferences(this);
            % CSD Tab
            this.CSDTab = uitab(tabGroup);
            this.CSDTab.Title = getString(message('Control:designerapp:strToolTitleShort'));
            csdGrid = uigridlayout(this.CSDTab);
            csdGrid.RowHeight = {'fit','fit','1x','fit'};
            csdGrid.ColumnWidth = {'1x','fit'};
            csdGrid.Padding = [10 10 10 10];
            this.CompensatorFormatContainer = ...
                controllib.widget.internal.cstprefs.CompensatorFormatContainer();
            wdgt = getWidget(this.CompensatorFormatContainer);
            wdgt.Parent = csdGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = [1 2];
            this.BodeOptionsContainer = ...
                controllib.widget.internal.cstprefs.BodeOptionsContainer();
            wdgt = getWidget(this.BodeOptionsContainer);
            wdgt.Parent = csdGrid;
            wdgt.Layout.Row = 2;
            wdgt.Layout.Column = [1 2];
            this.RestoreCSDButton = createRestoreDefaultButton(csdGrid,4,2);
            this.RestoreCSDButton.ButtonPushedFcn = @(s,e)restoreCSDPreferences(this);
        end

        function initialize(this,tbxprefs)
            % Get a copy of the toolbox preferences
            this.ToolboxPreferences    = tbxprefs;
        end
        
        function addListeners(this)
            this.Listeners = [this.Listeners, ...
                              addlistener(this.UnitsContainer,'PhaseUnits','PostSet',...
                                        @(es,ed) callbackPhaseUnitsChanged(this,ed));...
                              addlistener(this.UnitsContainer,'MagnitudeUnits','PostSet',...
                                        @(es,ed) callbackMagnitudeUnitsChanged(this,ed))];
        end
        
        function callbackPhaseUnitsChanged(this,ed)
            this.PhaseResponseContainer.PhaseUnits = ed.AffectedObject.PhaseUnits;
        end

        function callbackMagnitudeUnitsChanged(this,ed)
            this.MagnitudeResponseContainer.MagnitudeUnits = ed.AffectedObject.MagnitudeUnits;
        end
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            % Tabs
            widgets.Tabs.TabGroup = this.TabGroup;
            widgets.Tabs.Units = this.UnitsTab;
            widgets.Tabs.Style = this.StyleTab;
            widgets.Tabs.Options = this.OptionsTab;
            widgets.Tabs.CSD = this.CSDTab;
            % Restore buttons
            widgets.RestoreButtons = getRestoreDefaultButtons(this);
            % Containers/Panels
            widgets.Units = qeGetWidgets(this.UnitsContainer);
            widgets.Grid = qeGetWidgets(this.GridContainer);
            widgets.Fonts = qeGetWidgets(this.FontsContainer);
            widgets.Color = qeGetWidgets(this.ColorContainer);
            widgets.TimeResponse = qeGetWidgets(this.TimeResponseContainer);
            widgets.MagnitudeResponse = qeGetWidgets(this.MagnitudeResponseContainer);
            widgets.PhaseResponse = qeGetWidgets(this.PhaseResponseContainer);
            widgets.CompensatorFormat = qeGetWidgets(this.CompensatorFormatContainer);
            widgets.BodeOptions = qeGetWidgets(this.BodeOptionsContainer);
        end
        
        function selectedTab = qeGetSelectedTab(this)
            selectedTab = this.TabGroup.SelectedTab;
        end
    end
end

function button = createRestoreDefaultButton(layout,row,column)
button = uibutton(layout,...
    "Text",getString(message('Controllib:gui:strRestoreDefaultValues')));
button.Layout.Row = row;
button.Layout.Column = column;
end

function layout = createTabLayout(tab,n)
    layout = uigridlayout(tab);
    layout.RowHeight = [repmat({'fit'},[1 n]) '1x' 'fit'];
    layout.ColumnWidth = {'1x','fit'};
    layout.Padding = 10;
end