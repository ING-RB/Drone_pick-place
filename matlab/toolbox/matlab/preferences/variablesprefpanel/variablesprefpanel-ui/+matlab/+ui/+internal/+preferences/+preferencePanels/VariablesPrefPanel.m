classdef VariablesPrefPanel < handle
    % VARIABLESPREFPANEL class defines the preference panel for 'Variables'
    % This class creates a UIFigure and uses the UIGridLayout in order to
    % author an M preference panel to be plugged in JS MATLAB.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties
        UIFigure
    end
    
    properties(Access = private)
        ShowMATLABCode (1,1) matlab.ui.control.CheckBox
        MoveFocusOnEnterKey (1,1) matlab.ui.control.CheckBox
        DirectionOnEnterKeyDropdown (1,1) matlab.ui.control.DropDown
        ArrayFormatDropDown (1,1) matlab.ui.control.DropDown
        MissingPlacementDropDown (1,1) matlab.ui.control.DropDown
        ShowSparklines (1,1) matlab.ui.control.CheckBox
        ShowStatistics (1,1) matlab.ui.control.CheckBox
        TextElementMaxTB (1,1) matlab.ui.control.NumericEditField
    end
    
    methods
        function obj = VariablesPrefPanel()            
            % Outer grid for all sections
            panelGrid = uigridlayout(uifigure, [5 1]);
            obj.UIFigure = panelGrid.Parent;
            panelGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
            obj.buildPanelSections(panelGrid);
        end
        
        % Commits the PrefPanel UI Values to the settings.
        function result = commit(this)
            s = settings; 
            % ArrayFormat Settings
            s.matlab.desktop.variables.ArrayEditor_CS_Format.PersonalValue = this.ArrayFormatDropDown.Value;
            
            % Editing settings
            s.matlab.desktop.variables.editing.ArrayEditorEMoves.PersonalValue = this.MoveFocusOnEnterKey.Value;
            s.matlab.desktop.variables.editing.ArrayEditorEDirection.PersonalValue = this.DirectionOnEnterKeyDropdown.Value;

            % Sorting settings
            s.matlab.desktop.variables.sorting.MissingValuePlacement.PersonalValue = this.MissingPlacementDropDown.Value;

            % VECmdLineCodeGenEnabled settings
            s.matlab.desktop.arrayeditor.VECmdLineCodeGenEnabled.PersonalValue = this.ShowMATLABCode.Value;
            result = true;

            % Sparklines settings
            s.matlab.desktop.variables.sparklines.ShowSparklines.PersonalValue = this.ShowSparklines.Value;

            % Statistics settings
            s.matlab.desktop.variables.statistics.ShowStatistics.PersonalValue = this.ShowStatistics.Value;

            % Stats/Sparklines Text Element Limit
            s.matlab.desktop.variables.statistics.TextElementLimit.PersonalValue = this.TextElementMaxTB.Value;
        end
        
        function delete(this)
            delete(this.UIFigure);
        end
    end
    
    methods(Access='private')
        function buildPanelSections(this, panelGrid)
            s = settings;
            
            formatGrid = uigridlayout(panelGrid, [2, 1]);
            formatGrid.Padding(2) = 0;
            formatGrid.Padding(4) = 0;
            formatGrid.RowHeight = {'fit', 'fit'};
            formatGrid.ColumnWidth = {'fit'};
            formatGrid.RowSpacing = 0;
            
            formatSectionTitle = uilabel(formatGrid);
            formatSectionTitle.Text = this.getPrefLabelForDisplay('Format');
            formatSectionTitle.FontWeight = 'bold';
            
            % 2 Format Section to toggle Number Display Format
            arrayFormatGrid = uigridlayout(formatGrid, [1, 3]);
            arrayFormatGrid.RowHeight = {'fit'};
            arrayFormatGrid.ColumnWidth = {'fit', 'fit'};
            arrayFormatGrid.Padding(1) = 0;
            
            numDisplayFormat = s.matlab.desktop.variables.ArrayEditor_CS_Format;
            
            arrayFormatLabel = uilabel(arrayFormatGrid);
            arrayFormatLabel.Text = this.getPrefLabelForDisplay('DefaultArrayFormat');
                  
            this.ArrayFormatDropDown =  uidropdown(arrayFormatGrid, 'Items', ...
                {'short', 'long', 'short e', 'long e', 'short g', 'long g', 'short eng', 'long eng', 'bank', '+', 'hex', 'rational'}, ...
                'ItemsData', ...
                ["short", "long", "shortE", "longE", "shortG", "longG", "shortEng", "longEng", "bank", "+", "hex", "rational"]);
            this.ArrayFormatDropDown.Value = numDisplayFormat.ActiveValue;
            this.ArrayFormatDropDown.Tag = 'ArrayFormat';

            % Editing Section
            editingGrid = uigridlayout(panelGrid, [2, 1]);
            editingGrid.Padding(2) = 0;
            editingGrid.Padding(4) = 0;
            editingGrid.RowHeight = {'fit', 'fit'};
            editingGrid.ColumnWidth = {'fit'};
            editingGrid.RowSpacing = 0;

            % 1 Edit Section Title
            editSectionTitle = uilabel(editingGrid);
            editSectionTitle.Text = this.getPrefLabelForDisplay('Editing');
            editSectionTitle.FontWeight = 'bold';
            
            % 2 Edit Section Preference for direction change on enter key
            % press.
            directionChangeGrid = uigridlayout(editingGrid, [2, 1]);
            directionChangeGrid.RowHeight = {'fit', 'fit'};
            directionChangeGrid.ColumnWidth = {'fit'};
            directionChangeGrid.Padding(1) = 0;

            shouldMoveFocus = s.matlab.desktop.variables.editing.ArrayEditorEMoves;
            this.MoveFocusOnEnterKey = uicheckbox(directionChangeGrid);
            this.MoveFocusOnEnterKey.Text = this.getPrefLabelForDisplay('ShouldMoveFocus');
            this.MoveFocusOnEnterKey.Value = shouldMoveFocus.ActiveValue;
            this.MoveFocusOnEnterKey.Tag = 'MoveFocusOnEnterKey';
            
            directionChangeDropdownGrid = uigridlayout(directionChangeGrid, [1, 2]);
            directionChangeDropdownGrid.RowHeight = {'fit'};
            directionChangeDropdownGrid.ColumnWidth = {'fit', 'fit'};
            directionChangeDropdownGrid.Padding(2) = 0;
            directionChangeDropdownGrid.Padding(4) = 0;
            directionOnEnter = s.matlab.desktop.variables.editing.ArrayEditorEDirection;
            directionChangeLabel = uilabel(directionChangeDropdownGrid);
            directionChangeLabel.Text = this.getPrefLabelForDisplay('DirectionChangeLabel');
                  
            this.DirectionOnEnterKeyDropdown =  uidropdown(directionChangeDropdownGrid, 'Items', ...
                [string(this.getPrefLabelForDisplay('Down')), string(this.getPrefLabelForDisplay('Right')), ...
                string(this.getPrefLabelForDisplay('Up')), string(this.getPrefLabelForDisplay('Left'))], ...
                'ItemsData', ...
                ["down", "right", "up", "left"]);
            this.DirectionOnEnterKeyDropdown.Value = directionOnEnter.ActiveValue;
            this.DirectionOnEnterKeyDropdown.Tag = 'DirectionOnEnterKey';

            % Sorting Section
            sortingPreferenceGrid = uigridlayout(panelGrid, [2, 1]);
            sortingPreferenceGrid.Padding(2) = 0;
            sortingPreferenceGrid.Padding(4) = 0;
            sortingPreferenceGrid.RowHeight = {'fit', 'fit'};
            sortingPreferenceGrid.ColumnWidth = {'fit'};
            sortingPreferenceGrid.RowSpacing = 0;

            sortingSectionTitle = uilabel(sortingPreferenceGrid);
            sortingSectionTitle.Text = this.getPrefLabelForDisplay('Sorting');
            sortingSectionTitle.FontWeight = 'bold';

            % Sorting Preferences
            missingPlacementValue = s.matlab.desktop.variables.sorting.MissingValuePlacement;
            missingPlacementGrid = uigridlayout(sortingPreferenceGrid, [1, 2]);
            missingPlacementGrid.RowHeight = {'fit'};
            missingPlacementGrid.ColumnWidth = {'fit', 'fit'};
            missingPlacementGrid.Padding(1) = 0;

            missingPlacementLabel = uilabel(missingPlacementGrid);
            missingPlacementLabel.Text = this.getPrefLabelForDisplay('MissingPlacement');

            this.MissingPlacementDropDown =  uidropdown(missingPlacementGrid, 'Items', ...
                {'auto (default)', 'first', 'last'}, ...
                'ItemsData', ["auto", "first", "last"]);
            this.MissingPlacementDropDown.Value = missingPlacementValue.ActiveValue;
            this.MissingPlacementDropDown.Tag = 'MissingPlacementOnSort';
            
            % 3 Show MATLAB Code For operations
            isCodeGenEnabled = s.matlab.desktop.arrayeditor.VECmdLineCodeGenEnabled;

            codeGenGrid = uigridlayout(panelGrid, [2, 1]);
            codeGenGrid.RowHeight = {'fit', 'fit'};
            codeGenGrid.ColumnWidth = {'fit'};
            
            codeGenTitle = uilabel(codeGenGrid);
            codeGenTitle.Text = this.getPrefLabelForDisplay('ShowGeneratedCode');
            codeGenTitle.FontWeight = 'bold';
            
            this.ShowMATLABCode = uicheckbox(codeGenGrid);
            this.ShowMATLABCode.Text = this.getPrefLabelForDisplay('ShowCode');
            this.ShowMATLABCode.Value = isCodeGenEnabled.ActiveValue;
            this.ShowMATLABCode.Tag = 'ShowMatlabCode';

            % Tabular Variable Display
            tablularDisplayGridLayout = uigridlayout(panelGrid, [5, 2]);
            tablularDisplayGridLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
            tablularDisplayGridLayout.ColumnWidth = {'fit', 'fit'};

            areSparklinesEnabled = s.matlab.desktop.variables.sparklines.ShowSparklines;
            areStatisticsEnabled = s.matlab.desktop.variables.statistics.ShowStatistics;
            textElementLimit = s.matlab.desktop.variables.statistics.TextElementLimit;

            tabularDisplayLabel = uilabel(tablularDisplayGridLayout);
            tabularDisplayLabel.Text = this.getPrefLabelForDisplay('TabularDisplayGroup');
            tabularDisplayLabel.FontWeight = 'bold';
            tabularDisplayLabel.Layout.Row = 1;
            tabularDisplayLabel.Layout.Column = [1,2];
            
            % Show Sparklines
            this.ShowSparklines = uicheckbox(tablularDisplayGridLayout);
            this.ShowSparklines.Text = this.getPrefLabelForDisplay('ShowSparklines');
            this.ShowSparklines.Value = areSparklinesEnabled.ActiveValue;
            this.ShowSparklines.Tag = 'ShowSparklines';
            this.ShowSparklines.Layout.Row = 2;
            this.ShowSparklines.Layout.Column = [1,2];

            % Show Statistics
            this.ShowStatistics = uicheckbox(tablularDisplayGridLayout);
            this.ShowStatistics.Text = this.getPrefLabelForDisplay('ShowStatistics');
            this.ShowStatistics.Value = areStatisticsEnabled.ActiveValue;
            this.ShowStatistics.Tag = 'ShowStatistics';
            this.ShowStatistics.Layout.Row = 3;
            this.ShowStatistics.Layout.Column = [1,2];

            % Text Limits
            maxTextElementsLabel = uilabel(tablularDisplayGridLayout);
            maxTextElementsLabel.Text = this.getPrefLabelForDisplay('MaxTextlementsForStats');
            maxTextElementsLabel.Layout.Row = 5;
            maxTextElementsLabel.Layout.Column = 1;

            this.TextElementMaxTB = uieditfield(tablularDisplayGridLayout, "numeric", "Limits", [0, inf]);
            this.TextElementMaxTB.Value = textElementLimit.ActiveValue;
            this.TextElementMaxTB.Tag = 'MaxTextlementsForStats';
            this.TextElementMaxTB.Layout.Row = 5;
            this.TextElementMaxTB.Layout.Column = 2;
        end
        
        function prefLabel = getPrefLabelForDisplay(~, key)
            prefLabel = getString(message(sprintf('MATLAB:datatools:prefpanel:variablesprefpanel:%s', key)));
        end
    end
end

