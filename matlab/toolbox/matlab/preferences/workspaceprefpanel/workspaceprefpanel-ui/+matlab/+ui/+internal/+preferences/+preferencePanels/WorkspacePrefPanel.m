classdef WorkspacePrefPanel < handle
    % WORKSPACEPREFPANEL class defines the preference panel for 'Workspace'
    % This class creates a UIFigure and uses the UIGridLayout in order to
    % author an M preference panel to be plugged in JS MATLAB.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties
        UIFigure
    end
    
    properties(Access = private)
        MaxArraySizeText          (1,1) matlab.ui.control.NumericEditField
        MaximumNestingLevelText   (1,1) matlab.ui.control.NumericEditField
        ArrayFormattingOption     (1,1) matlab.ui.control.RadioButton
        ArrayDimsIn2DPages1       (1,1) matlab.ui.control.NumericEditField
        ArrayDimsIn2DPages2       (1,1) matlab.ui.control.NumericEditField
        MaxCharPerLineText        (1,1) matlab.ui.control.NumericEditField
        StatCalculationsValue     (1,1) matlab.ui.control.Spinner
        HandlingNaNOptionValues   (1,1) matlab.ui.control.RadioButton
        LimitArraySizeRAMOption   (1,1) matlab.ui.control.CheckBox
        LimitArraySizeSliderValue (1,1) matlab.ui.control.Slider
    end
    
    methods
        function obj = WorkspacePrefPanel()            
            % Outer grid for all sections
            panelGrid = uigridlayout(uifigure, [3 1]);
            obj.UIFigure = panelGrid.Parent;
            panelGrid.RowHeight = {'fit', 'fit', 'fit'};
            obj.buildPanelSections(panelGrid);
        end
        
        % Commits the PrefPanel UI Values to the settings.
        function result = commit(this)
            s = settings;
            
            % savevariablestoscript settings
            s.matlab.desktop.workspace.savevariablestoscript.MaximumArraySize.PersonalValue = this.MaxArraySizeText.Value;
            s.matlab.desktop.workspace.savevariablestoscript.MaximumNestingLevel.PersonalValue = this.MaximumNestingLevelText.Value;
            s.matlab.desktop.workspace.savevariablestoscript.Using2Dslice.PersonalValue = this.ArrayFormattingOption.Value;
            s.matlab.desktop.workspace.savevariablestoscript.ArrayDimensionsFor2Dslice.PersonalValue = [this.ArrayDimsIn2DPages1.Value this.ArrayDimsIn2DPages2.Value];
            s.matlab.desktop.workspace.savevariablestoscript.MaximumTextWidth.PersonalValue = this.MaxCharPerLineText.Value;

            % statisticalcalculations settings
            s.matlab.desktop.workspace.statisticalcalculations.WorkspaceBrowserUseNaNs.PersonalValue = this.HandlingNaNOptionValues.Value;
            s.matlab.desktop.workspace.statisticalcalculations.WorkspaceBrowserStatNumelLimit.PersonalValue = this.StatCalculationsValue.Value;

            % ArraySizeLimit settings
            s.matlab.desktop.workspace.ArraySizeLimitEnabled.PersonalValue = this.LimitArraySizeRAMOption.Value;
            s.matlab.desktop.workspace.ArraySizeLimit.PersonalValue = round(this.LimitArraySizeSliderValue.Value);
            result = true;
        end
        
        function delete(this)
            delete(this.UIFigure);
        end
    end
    
    methods(Access='private')
        function buildPanelSections(this, panelGrid)
            s = settings;
            
            % 1. Saving Variables Grid
            savingVariablesGrid = uigridlayout(panelGrid, [4, 1]);
            savingVariablesGrid.Padding(2) = 0;
            savingVariablesGrid.Padding(4) = 0;
            savingVariablesGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            savingVariablesGrid.RowSpacing = 0;
            saveVariablesSettings = s.matlab.desktop.workspace.savevariablestoscript;
            
            savingVarLabel = uilabel(savingVariablesGrid);
            savingVarLabel.Text = this.getPrefLabelForDisplay('SaveVariablesAsScripts');
            savingVarLabel.FontWeight = 'bold';
            
            % 1.a Saving Variables Threshhold
            savingVarThreshholdGrid = uigridlayout(savingVariablesGrid, [3, 1]);
            savingVarThreshholdGrid.RowSpacing = 5;
            savingVarThreshholdGrid.RowHeight = {'fit', 'fit', 'fit'};
            
            savingVarThreshholdLabel = uilabel(savingVarThreshholdGrid);
            savingVarThreshholdLabel.Text = this.getPrefLabelForDisplay('SaveVariablesThreshhold');
            savingVarThreshholdLabel.FontWeight = 'bold';
            
            savingVarThreshholdHelperText = uilabel(savingVarThreshholdGrid);
            savingVarThreshholdHelperText.Text = this.getPrefLabelForDisplay('SaveVariablesThreshholdHelper');
            
            % 1.a.i Maximum Array Size for save
            maxValues = uigridlayout(savingVarThreshholdGrid, [2,2]);
            maxValues.RowSpacing = 4;          
            maxValues.RowHeight = {'fit', 'fit'};
            maxValues.ColumnWidth = {'fit', 'fit'};
            maxValues.Padding = 0;
            maximumArraySizeLabel = uilabel(maxValues);
            maximumArraySizeLabel.Text = this.getPrefLabelForDisplay('MaxArraySize');
            maximumArraySizeLabel.Layout.Row = 1;
            maximumArraySizeLabel.Layout.Column = 1;
            
            % The value for 'MaximumArraySize' must be a positive integer within the range 1 to 10000.
            this.MaxArraySizeText = uieditfield(maxValues,'numeric', 'Limits', [1 10000], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d');
            this.MaxArraySizeText.Value = saveVariablesSettings.MaximumArraySize.ActiveValue;
            this.MaxArraySizeText.Layout.Row = 1;
            this.MaxArraySizeText.Layout.Column = 2;
            this.MaxArraySizeText.Tag = 'MaxArraySizeText';
            
            % 1.a.ii Maximum struct/object nesting levels
            
            maxNestinglevelLabel = uilabel(maxValues);
            maxNestinglevelLabel.Text = this.getPrefLabelForDisplay('MaxNestingValue');
            maxNestinglevelLabel.Layout.Row = 2;
            maxNestinglevelLabel.Layout.Column = 1;
            
            % The value for 'MaximumNestingLevel' must be a positive integer within the range 1 to 200.
            this.MaximumNestingLevelText = uieditfield(maxValues,'numeric', 'Limits', [1 200], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d');
            this.MaximumNestingLevelText.Value = saveVariablesSettings.MaximumNestingLevel.ActiveValue;
            this.MaximumNestingLevelText.Layout.Row = 2;
            this.MaximumNestingLevelText.Layout.Column = 2;
            this.MaximumNestingLevelText.Tag = 'MaximumNestingLevelText';
            
            % 1.b MultiDimensional Array Formatting
            multiDimFormattingGrid = uigridlayout(savingVariablesGrid, [3, 1]);
            multiDimFormattingGrid.RowSpacing = 4;
            multiDimFormattingGrid.RowHeight = {'fit', 45, 'fit'};
            
            multiDimFormattingLabel = uilabel(multiDimFormattingGrid);
            multiDimFormattingLabel.Text = this.getPrefLabelForDisplay('MultiDimArrayFormatting');
            multiDimFormattingLabel.FontWeight = 'bold';
            
            % 1.b.i Array Formatting Options
            bg = uibuttongroup(multiDimFormattingGrid, 'BorderType', 'none');
            bg.Layout.Row = 2;
            bg.Layout.Column = 1;
            ArrayFormatValue = saveVariablesSettings.Using2Dslice.ActiveValue;
            
            this.ArrayFormattingOption = uiradiobutton(bg);
            this.ArrayFormattingOption.Text = this.getPrefLabelForDisplay('RowVectorReshape');
            this.ArrayFormattingOption.Position = [1 25 400 22];
            this.ArrayFormattingOption.Tag = 'ArrayFormattingOption';
            
            dimsForSavingPagesButton = uiradiobutton(bg);
            dimsForSavingPagesButton.Text = this.getPrefLabelForDisplay('DimsForSaving2DPages');
            dimsForSavingPagesButton.Position = [1 1 400 22];
            
            this.ArrayFormattingOption.Value = ArrayFormatValue;

            % 1.b.ii Array Dimension in 2-D Pages
            ArrayDimensionsGrid = uigridlayout(multiDimFormattingGrid, [1, 5]);
            ArrayDimensionsGrid.RowSpacing = 0;
            ArrayDimensionsGrid.Padding = 0;
            ArrayDimensionsGrid.ColumnWidth = {'fit', 'fit', 'fit'};
            ArrayDimensionsLabel = uilabel(ArrayDimensionsGrid);
            ArrayDimensionsLabel.Text = this.getPrefLabelForDisplay('ArrayDimsFor2DPages');
            
            % The array values for 'MultidimensionalFormat' must be positive integers and must fall between 1 and 32, ...
            % and the first array value must be smaller than the second.
            arrayDimsValues = saveVariablesSettings.ArrayDimensionsFor2Dslice.ActiveValue;
            this.ArrayDimsIn2DPages1 = uieditfield(ArrayDimensionsGrid,'numeric', 'Limits', [1 32], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d');
            this.ArrayDimsIn2DPages1.Value = arrayDimsValues(1);
            this.ArrayDimsIn2DPages1.Layout.Row = 1;
            this.ArrayDimsIn2DPages1.Layout.Column = 2;
            this.ArrayDimsIn2DPages1.Tag = 'ArrayDimsIn2DPages1';
            this.ArrayDimsIn2DPages1.ValueChangedFcn = @(es,ed)this.validateArrayDimensions(es,ed);
            
            this.ArrayDimsIn2DPages2 = uieditfield(ArrayDimensionsGrid,'numeric', 'Limits', [1 32], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d');
            this.ArrayDimsIn2DPages2.Value = arrayDimsValues(2);
            this.ArrayDimsIn2DPages2.Layout.Row = 1;
            this.ArrayDimsIn2DPages2.Layout.Column = 3;
            this.ArrayDimsIn2DPages2.Tag = 'ArrayDimsIn2DPages2';
            this.ArrayDimsIn2DPages2.ValueChangedFcn = @(es,ed)this.validateArrayDimensions(es,ed);
            
            % Temporary tooltip to notify constriants to users until
            % validate is fully functional.
            this.ArrayDimsIn2DPages1.Tooltip = this.getPrefLabelForDisplay('ArrayLimitTooltip');
            this.ArrayDimsIn2DPages2.Tooltip = this.getPrefLabelForDisplay('ArrayLimitTooltip');
            
            % 1.c File Formatting
            fileformattingGrid = uigridlayout(savingVariablesGrid, [2, 1]);
            fileformattingGrid.RowSpacing = 4;
            fileformattingGrid.RowHeight = {'fit', 'fit'};
            fileFormattingLabel = uilabel(fileformattingGrid);
            fileFormattingLabel.Text = this.getPrefLabelForDisplay('FileFormatting');
            fileFormattingLabel.FontWeight = 'bold';
            
            % 1.c.i Maximum Characters Per Line
            maxCharGrid = uigridlayout(fileformattingGrid, [1, 2]);
            maxCharGrid.RowSpacing = 0;
            maxCharGrid.Padding = 0;
            maxCharGrid.RowHeight = {'fit'};
            maxCharLabel = uilabel(maxCharGrid);
            maxCharLabel.Text = this.getPrefLabelForDisplay('MaxCharactersPerLine');
            
            % The value for 'MaximumTextWidth' must be a positive integer within the range 32 to 256.'
            this.MaxCharPerLineText = uieditfield(maxCharGrid,'numeric', 'Limits', [32 256], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d');
            this.MaxCharPerLineText.Value = saveVariablesSettings.MaximumTextWidth.ActiveValue;
            this.MaxCharPerLineText.Layout.Column = 2;
            this.MaxCharPerLineText.Tag = 'MaxCharPerLineText';
            
            % 2. Statistical Calculations
            statCalculationGrid = uigridlayout(panelGrid, [3, 1]);
            statCalculationGrid.RowSpacing = 5;
            statCalculationGrid.Padding(2) = 0;
            statCalculationGrid.Padding(4) = 0;
            statCalculationGrid.RowHeight = {'fit','fit','fit'};
            
            fileFormattingLabel = uilabel(statCalculationGrid);
            fileFormattingLabel.Text = this.getPrefLabelForDisplay('StatisticalCalc');
            fileFormattingLabel.FontWeight = 'bold';
            
            % 2.a Array Numel Limit to show statistics
            statNumelLimitGrid = uigridlayout(statCalculationGrid, [1, 4]);
            statNumelLimitGrid.RowSpacing = 0;
            statNumelLimitGrid.ColumnWidth = {'fit', 'fit'};
            statNumelLimitGrid.RowHeight = {'fit'};
            statCalculationSettings = s.matlab.desktop.workspace.statisticalcalculations;
            
            statNumelLimitLabel = uilabel(statNumelLimitGrid);
            statNumelLimitLabel.HorizontalAlignment = 'left';
            statNumelLimitLabel.Layout.Row = 1;
            statNumelLimitLabel.Layout.Column = 2;
            statNumelLimitLabel.Text = this.getPrefLabelForDisplay('ShowArrayStatsHelper');
            
            this.StatCalculationsValue = uispinner(statNumelLimitGrid, 'ValueDisplayFormat', '%d', ...
                'RoundFractionalValues', 'on');
            this.StatCalculationsValue.Limits = [0 Inf];
            this.StatCalculationsValue.Layout.Row = 1;
            this.StatCalculationsValue.Layout.Column = 1;
            this.StatCalculationsValue.Value = statCalculationSettings.WorkspaceBrowserStatNumelLimit.ActiveValue;
            this.StatCalculationsValue.Tag = 'StatCalculationsValue';
            
            % 2.b Use/Ignore NaN's while calculating statistics
            statIgnoreNaNGrid = uigridlayout(statCalculationGrid, [2, 1]);
            statIgnoreNaNGrid.RowSpacing = 0;
            statIgnoreNaNGrid.Padding(4) = 0;
            statIgnoreNaNGrid.RowHeight = {'fit', 45};
            
            handleNaNLabel = uilabel(statIgnoreNaNGrid);
            handleNaNLabel.Text = this.getPrefLabelForDisplay('HandleNaNInCalculations');
            
            ignoreNaNButtonGroup = uibuttongroup(statIgnoreNaNGrid, 'BorderType', 'none');
            ignoreNaNButtonGroup.Layout.Row = 2;
            ignoreNaNButtonGroup.Layout.Column = 1;
            
            statShowNanSetting = statCalculationSettings.WorkspaceBrowserUseNaNs.ActiveValue;
            this.HandlingNaNOptionValues = uiradiobutton(ignoreNaNButtonGroup);
            this.HandlingNaNOptionValues.Text = this.getPrefLabelForDisplay('UseNansInCalculatingStats');
            this.HandlingNaNOptionValues.Position = [10 22 400 22];
            this.HandlingNaNOptionValues.Tag = 'HandlingNaNOptionValues';
            
            ignoreNaNButton = uiradiobutton(ignoreNaNButtonGroup);
            ignoreNaNButton.Text = this.getPrefLabelForDisplay('IgnoreNansWhenCalculatingSttas');
            ignoreNaNButton.Position = [10 1 400 22];
            
            this.HandlingNaNOptionValues.Value = statShowNanSetting;
            
            % 3 MATLAB Array Size Limit
            arraySizeLimitGrid = uigridlayout(panelGrid, [3, 1]);
            arraySizeLimitGrid.RowHeight = {'fit', 'fit', 'fit'};
            arraySizeLimitGrid.RowSpacing = 4;
            arraySizeLimitGrid.Padding(2) = 0;
            arraySizeLimitGrid.Padding(4) = 0;

            arraySizeLimitLabel = uilabel(arraySizeLimitGrid);
            arraySizeLimitLabel.Text = this.getPrefLabelForDisplay('ArraySizeLimit');
            arraySizeLimitLabel.FontWeight = 'bold';
            arraySizeLimitEnabledSetting = s.matlab.desktop.workspace.ArraySizeLimitEnabled;

            % 3.a Limit Maximum Array Size to RAM Percentage
            this.LimitArraySizeRAMOption = uicheckbox(arraySizeLimitGrid);
            this.LimitArraySizeRAMOption.Text = this.getPrefLabelForDisplay('LimitMaxArarySizeToRam');
            this.LimitArraySizeRAMOption.Value = arraySizeLimitEnabledSetting.ActiveValue;
            this.LimitArraySizeRAMOption.Tag = 'LimitArraySizeRAMOption';
            
            arraySizeSliderGrid =  uigridlayout(arraySizeLimitGrid, [1, 1]);
            arraySizeSliderGrid.ColumnWidth = {200};
            arraySizeSliderGrid.RowSpacing = 0;
            arraySizeLimitSetting = s.matlab.desktop.workspace.ArraySizeLimit;
            
            this.LimitArraySizeSliderValue = uislider(arraySizeSliderGrid);
            this.LimitArraySizeSliderValue.MajorTicks = [1 50 100];
            this.LimitArraySizeSliderValue.Limits = [1 100];
            this.LimitArraySizeSliderValue.MajorTickLabels = {'1%', '50%', '100%'};
            this.LimitArraySizeSliderValue.MinorTicks = [1, 10:10:100];
            this.LimitArraySizeSliderValue.Value = double(arraySizeLimitSetting.ActiveValue);
            this.LimitArraySizeSliderValue.Tag = 'LimitArraySizeSliderValue';
            this.LimitArraySizeSliderValue.Step = 1;
        end
        
        % If ArrayDimsIn2DPages1 value is > ArrayDimsIn2DPages2, Revert the
        % edit operation. Ideally, this should be handled in 'validate',
        % but since that will prevent a commit without notifying currently,
        % adding this pre-validation.
        function validateArrayDimensions(this, es, ed)
            if (this.ArrayDimsIn2DPages1.Value > this.ArrayDimsIn2DPages2.Value)
                es.Value = ed.PreviousValue;
            end
        end
        
        function prefLabel = getPrefLabelForDisplay(~, key)
            prefLabel = getString(message(sprintf('MATLAB:datatools:prefpanel:workspaceprefpanel:%s', key)));
        end
    end
end

