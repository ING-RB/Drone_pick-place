% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides a common implementation for tabular file import in the
% Live Editor.

% Copyright 2022-2024 The MathWorks, Inc.

classdef TabularImportTask < matlab.internal.commonimport.BaseImportTask

    properties
        OutputPanel matlab.ui.container.internal.AccordionPanel
        ConfigureGrid matlab.ui.container.GridLayout
        OutputLabel matlab.ui.control.Label
        OutputTypeDropDown matlab.ui.control.DropDown
        ReturnImportOptionsCB matlab.ui.control.CheckBox
        ShowImportOptionsCB matlab.ui.control.CheckBox
        UseVarsFromFileCB matlab.ui.control.CheckBox

        % The last importOptions used to import the tabular data file
        LastImportOptions

        % The last output type selected
        LastOutputType (1,1) string = "table";

        % The DataModel used for importing
        DataModel

        % The ViewModel used for importing
        ViewModel

        % The last selection in the imported file
        LastSelection string

        % The import type for the selected file
        ImportType (1,1) string
    end

    properties(Hidden)
        CodeContainsImportOptions (1,1) logical = true;

        InitialValidNames = false;
    end

    methods(Abstract)
        % Get the code generator class used for code generation for the imported
        % file.
        codeGenerator = getCodeGenerator(task)

        opts = recreateImportOptsFromStruct(optsStruct)
    end

    methods
        function this = TabularImportTask()
            % Creates a TabularImportTask instance
            this = this@matlab.internal.commonimport.BaseImportTask("Parent", uifigure("Visible", "off"));
        end

        function summary = getTaskSummary(task)
            % Implementation of the abstract getSummary method.  Returns the
            % summary to display for the tabular file import.

            if isempty(task.LastImportOptions)
                summary = '';
            else
                switch(char(task.LastOutputType))
                    case "table"
                        outputType = gs("OutputTypeTable");
                    case "numericarray"
                        outputType = gs("OutputTypeNumericArray");
                    case "cellarray"
                        outputType = gs("OutputTypeCellArray");
                    case "stringarray"
                        outputType = gs("OutputTypeStringArray");
                    case "timetable"
                        outputType = gs("OutputTypeTimetable");
                    otherwise
                        outputType = gs("OutputTypeTable");
                end

                if task.LastOutputType == "columnvector"
                    summary = gs("SummaryLabelColVectors", ...
                        length(task.LastImportOptions.SelectedVariableNames), ...
                        "`" +  task.Filename + "`");
                else
                    summary = gs("SummaryLabelSingleVar", ...
                        outputType, ...
                        length(task.LastImportOptions.SelectedVariableNames), ...
                        "`" +  task.Filename + "`");
                end
            end
        end

        function state = getTaskState(task)
            % Implementation of the abstract addToState method.  Adds tabular
            % file content to the state object.

            arguments
                task
            end

            state = struct;

            % Future - start of block to remove
            opts = task.LastImportOptions;
            durationColInfo = [];
            durationIdx = [];
            if ~isempty(opts)
                durationIdx = opts.VariableTypes == "duration";
                if any(durationIdx)
                    numcols = length(opts.VariableTypes);
                    for idx = 1:numcols
                        durationColInfo(idx).idx = idx;
                        if opts.VariableTypes(idx) == "duration"
                            durationColInfo(idx).format = opts.VariableOptions(idx).InputFormat;
                        else
                            durationColInfo(idx).format = '';
                        end
                    end
                    opts = setvartype(opts, durationIdx, "string");
                end
            end

            if ~isempty(durationColInfo)
                state.durationColInfo = durationColInfo;
            end
            state.durationIdx = durationIdx;
            state.lastImportOptions = opts;
            state.lastCode = task.LastCode;
            state.codeContainsImportOptions = task.CodeContainsImportOptions;
            % Future - end of block to remove
            
            state.lastOutputType = task.LastOutputType;
            state.lastVarName = task.LastVarName;
            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox)
                % Future: Set these if they are not the default values
                % if ~task.ImportDataCheckBox.Value
                    state.showImportData = task.ImportDataCheckBox.Value;
                % end
                % if task.ReturnImportOptionsCB.Value
                    state.returnImportOptions = task.ReturnImportOptionsCB.Value;
                % end
                % if task.ShowImportOptionsCB.Value
                    state.showImportOptions = task.ShowImportOptionsCB.Value;
                % end
                % if ~task.UseVarsFromFileCB.Value
                    state.useVarsFromFile = task.UseVarsFromFileCB.Value;
                % end
            end
        end

        function setTaskState(task, state)
            % Implementation of the setTaskState method.  Restores the state of
            % this import task.

            arguments
                task
                state struct
            end

            % Recreate the task based on the saved task state
            if isfield(state, "showImportData")
                task.ImportDataCheckBox.Value = state.showImportData;
            else
                task.ImportDataCheckBox.Value = true;
            end
            if isfield(state, "showImportOptions")
                task.ShowImportOptionsCB.Value = state.showImportOptions;
            else
                task.ShowImportOptionsCB.Value = false;
            end
            if isfield(state, "returnImportOptions")
                task.ReturnImportOptionsCB.Value = state.returnImportOptions;
            else
                task.ReturnImportOptionsCB.Value = false;
            end
            task.setReturnImportOptionsEnabled(task.ReturnImportOptionsCB.Value);
            task.ShowImportOptionsCB.Enable = task.CodeContainsImportOptions;
            task.LastOutputType = state.lastOutputType;
            task.OutputTypeDropDown.Value = task.LastOutputType;
            task.LastVarName = state.lastVarName;

            if isfield(state, "useVarsFromFile")
                % Need to check for this field, since it was added after
                % initial release
                task.UseVarsFromFileCB.Value = state.useVarsFromFile;
            else
                task.UseVarsFromFileCB.Value = true;
            end
            outputType = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(state.lastOutputType);
            task.setUseVarsFromFileEnabled(outputType.isTabular());
        end

        function reset(task)
            % Implementation of the abstract reset method.  Resets this import
            % task.
            task.OutputPanel.Visible = "off";
            task.ResultsPanel.Visible = "off";
            task.LastImportOptions = [];
        end

        function code = updateCodeForOutputOptions(task, code)
            % Implementation of the abstract updateCodeForOutputOptions method.
            % Adds code to 'clear opts' if the opts object is not selected to be
            % shown as output.

            arguments
                task
                code string
            end

            if task.CodeContainsImportOptions && ~task.returnImportOptions
                % Add in logic to clear opts if it was created
                if ~endsWith(code, newline)
                    code = code + newline;
                end
                code = code + newline + "% " + getString(message("MATLAB:codetools:importtool:Codgen_ClearVars")) + ...
                    newline + "clear opts";
            end
        end

        function outputs = getOutputs(task, lhs)
            % Implementation of the abstract getOutputs method.  Returns the lhs
            % argument and optionally opts, if it is selected as output.

            arguments
                task
                lhs string
            end

            if task.LastOutputType == "columnvector"
                outputs = string(task.LastImportOptions.SelectedVariableNames);
            else
                outputs = lhs;
            end

            if task.returnImportOptions
                outputs(end+1) = "opts";
            end

            outputs = cellstr(outputs);
        end

        function code = generateVisualizationCode(task, lhs)
            % Implementation of the abstract method, adds in the lhs and/or the
            % opts variable, depending on the output selected.

            arguments
                task
                lhs string
            end

            if task.LastOutputType == "columnvector"
                outputVars = strjoin(string(task.LastImportOptions.SelectedVariableNames), ", ");
            else
                outputVars = lhs;
            end

            if isempty(task.ImportDataCheckBox) || ~isvalid(task.ImportDataCheckBox)
                code = "";
            elseif task.ImportDataCheckBox.Value && task.showImportOptions
                code = outputVars + ", opts";
            elseif task.ImportDataCheckBox.Value
                code = outputVars;
            elseif task.showImportOptions
                code = "opts";
            else
                code = "";
            end
        end

        function filetype = getFormatForFile(~, filename)
            % Returns the file format to display.  Does a lookup of common formats based on extension.
            % If no translated string is available, just returns the extension.
            [~, ~, ext] = fileparts(filename);
            extension = upper(extractAfter(ext, "."));

            try
                filetype = gs("FileFormat" + extension);
            catch
                filetype = extension;
            end
        end
    end

    methods(Access = protected)
        function addOutputVarTypeSection(task, accordionParent)
            [task.OutputPanel, outputGrid] = task.createAccordionPanel(accordionParent, ...
                gs("SpecifyOutputLabel"), {'fit'}, 3);

            %
            % Output Type - Row 1 in Output and Options
            %
            task.ConfigureGrid = task.createGrid(outputGrid, {'fit', 'fit'}, {'fit'});
            task.ConfigureGrid.Padding = [0 0 0 0];
            task.ConfigureGrid.Layout.Row = 1;
            task.ConfigureGrid.Layout.Column = 1;

            task.OutputLabel = uilabel(task.ConfigureGrid);
            task.OutputLabel.Layout.Row = 1;
            task.OutputLabel.Layout.Column = 1;
            task.OutputLabel.Text = gs("OutputLabel");

            task.OutputTypeDropDown = uidropdown(task.ConfigureGrid);
            task.OutputTypeDropDown.Items = {...
                gs("OutputTypeTable"), gs("OutputTypeTimetable"), ...
                gs("OutputTypeColumnVectors"), gs("OutputTypeNumericArray"), ...
                gs("OutputTypeStringArray"), gs("OutputTypeCellArray")};
            task.OutputTypeDropDown.ItemsData = {'table', 'timetable', 'columnvector', 'numericarray', 'stringarray', 'cellarray'};
            task.OutputTypeDropDown.Layout.Row = 1;
            task.OutputTypeDropDown.Layout.Column = 2;
            task.OutputTypeDropDown.ValueChangedFcn = @(~,~) task.outputTypeChanged();

            % Create "Data has variable names" checkbox
            task.UseVarsFromFileCB = uicheckbox(outputGrid);
            task.UseVarsFromFileCB.Text = gs("UseVarsFromFile");
            task.UseVarsFromFileCB.Value = true;
            task.UseVarsFromFileCB.Layout.Row = 2;
            task.UseVarsFromFileCB.Layout.Column = 1;
            task.UseVarsFromFileCB.ValueChangedFcn = @(~,~) task.useVarsFromFileChanged();

            % Create ReturnImportOptionsCB
            task.ReturnImportOptionsCB = uicheckbox(outputGrid);
            task.ReturnImportOptionsCB.Text = gs("ImportOptionsCheckbox");
            task.ReturnImportOptionsCB.Value = false;
            task.ReturnImportOptionsCB.Layout.Row = 3;
            task.ReturnImportOptionsCB.Layout.Column = 1;
            task.ReturnImportOptionsCB.ValueChangedFcn = @(~,~) task.returnImportOptionsChanged();
        end

        function addDisplayResultsSection(task, accordionParent)
            [task.ResultsPanel, resultsGrid] = task.createAccordionPanel(accordionParent, ...
                gs("DisplayResultsLabel"), {'fit'}, 1);
            task.ResultsPanel.collapse();

            % Output panel - Row 1 in Display results section
            task.OutputGrid = task.createGrid(resultsGrid, {'fit', 'fit'}, {'1x'});
            task.OutputGrid.ColumnSpacing = 20;
            task.OutputGrid.Padding = [0 0 0 0];
            task.OutputGrid.Layout.Row = 1;
            task.OutputGrid.Layout.Column = 1;

            % Create ImportDataCheckBox
            task.ImportDataCheckBox = uicheckbox(task.OutputGrid);
            task.ImportDataCheckBox.Text = gs("ImportedDataCheckbox");
            task.ImportDataCheckBox.Layout.Row = 1;
            task.ImportDataCheckBox.Layout.Column = 1;
            task.ImportDataCheckBox.Value = true;
            task.ImportDataCheckBox.ValueChangedFcn = @(~,~) task.notifyChange();

            % Create ShowImportOptionsCB
            task.ShowImportOptionsCB = uicheckbox(task.OutputGrid);
            task.ShowImportOptionsCB.Text = gs("ShowImportOptionsCheckbox");

            task.ShowImportOptionsCB.Enable = false;
            task.ShowImportOptionsCB.Value = false;
            task.ShowImportOptionsCB.Layout.Row = 1;
            task.ShowImportOptionsCB.Layout.Column = 2;
            task.ShowImportOptionsCB.ValueChangedFcn = @(~,~) task.notifyChange();
        end

        function b = startsWithDateDuration(~, opts)
            % Check if the imported table starts with a datetime or duration
            varType = opts.VariableTypes(1);
            b = any(varType == ["duration", "datetime"]);
        end

        function setTimetableOutput(task, opts, tvm)
            % Sets up the import for timetable
            defaultOutputType = "timetable";
            rowTimesColumn = opts.VariableNames{1};
            rowTimesType = "column";

            tvm.setTableModelProperties(...
                "OutputVariableType", defaultOutputType, ...
                "DefaultOutputType", defaultOutputType, ...
                "RowTimesType", rowTimesType, ...
                "RowTimesColumn", rowTimesColumn);

            % Select timetable in the dropdown
            task.OutputTypeDropDown.Value = 'timetable';
        end

        function outputTypeChanged(task)
            % Called when the output type changes
            task.LastOutputType = task.OutputTypeDropDown.Value;

            outputType = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(task.LastOutputType);
            outputType.initOutputArgsFromProperties(task.ViewModel);
            if task.LastOutputType == "stringarray" || task.LastOutputType == "numericarray"
                updatedTypes = outputType.getColumnClasses(task.LastImportOptions.VariableTypes);
                task.LastImportOptions = setvartype(task.LastImportOptions, updatedTypes);
            else
                task.LastImportOptions = setvartype(task.LastImportOptions, task.ViewModel.ColumnClasses);
                colsToTrim = task.DataModel.FileImporter.getTrimNonNumericCols(task.LastImportOptions.VariableTypes);
                if any(colsToTrim)
                    task.LastImportOptions = setvaropts(task.LastImportOptions, colsToTrim, "TrimNonNumeric", true);
                end

            end

            task.setUseVarsFromFileEnabled(outputType.isTabular());

            [c, codeDescription] = task.generateScriptForOutputType(outputType);
            task.updateAfterOptionsChange(c, codeDescription);
        end

        function updateAfterOptionsChange(task, code, codeDescription)
            % Update the task after options have changed with affect the
            % generated code
            task.CodeContainsImportOptions = codeDescription.containsImportOptions;
            task.setReturnImportOptionsEnabled(task.CodeContainsImportOptions);
            task.setShowImportOptionsEnabled();
            task.LastCode = task.getResolvedCode(code);
            task.notifyChange();
        end

        function returnImportOptionsChanged(task)
            task.setShowImportOptionsEnabled();
            task.notifyChange();
        end

        function useVarsFromFileChanged(task)
            % Called when the "Data has variable names" checkbox changes.
            % This has the affect of updating the imported table/timetable
            % variable names, and changing the selection of the imported
            % data to include or not include the header row.
            [r, c] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(task.LastSelection);
            task.ViewModel.setSelection(r, c);

            if task.UseVarsFromFileCB.Value
                task.ViewModel.updateIncludesVarNamesRow(true);
                state = task.DataModel.getState();
                task.LastImportOptions.VariableNames = state.CurrentValidVariableNames;
            else
                task.ViewModel.updateIncludesVarNamesRow(false);
                task.LastImportOptions.VariableNames = "Var" + (1:length(task.LastImportOptions.VariableNames));
            end

            outputType = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(task.LastOutputType);
            outputType.initOutputArgsFromProperties(task.ViewModel);
            [c, codeDescription] = task.generateScriptForOutputType(outputType);
            task.updateAfterOptionsChange(c, codeDescription);
        end

        function [c, codeDescription] = generateScriptForOutputType(task, outputType)
            codeGenerator = task.getCodeGenerator();
            selection = task.resolveSelectionWithOutput(...
                task.DataModel.FileImporter.getInitialSelection, outputType);

            [c, codeDescription] = codeGenerator.generateScript(task.LastImportOptions, ...
                "Filename", task.getFullFilename, ...
                "VarName", task.LastVarName, ...
                "OutputType", outputType, ...
                "OriginalOpts", task.DataModel.FileImporter.OriginalOpts, ...
                "InitialSelection", selection, ...
                "DataLines", {[selection(1), inf]}, ...
                "ArbitraryVarNames", task.isArbitraryVarNames, ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);
        end

        function arbitraryVarNames = isArbitraryVarNames(task)
            if task.UseVarsFromFileCB.Value
                arbitraryVarNames = ~task.InitialValidNames;
            else
                arbitraryVarNames = false;
            end
        end

        function b = returnImportOptions(task)
            % Returns true if "Return import options" is valid, enabled,
            % and checked.
            b = ~isempty(task.ReturnImportOptionsCB) && ...
                isvalid(task.ReturnImportOptionsCB) && ...
                task.ReturnImportOptionsCB.Enable && ...
                task.ReturnImportOptionsCB.Value;
        end

        function b = showImportOptions(task)
            % Returns true if "Show import options" is valid, enabled, and
            % checked.
            b = ~isempty(task.ShowImportOptionsCB) && ...
                isvalid(task.ShowImportOptionsCB) && ...
                task.ShowImportOptionsCB.Enable && ...
                task.ShowImportOptionsCB.Value;
        end

        function setReturnImportOptionsEnabled(task, enabled)
            % Sets "Return import options" enabled.  Sets a tooltip when it
            % is disabled.

            arguments
                task
                enabled (1,1) logical
            end

            task.ReturnImportOptionsCB.Enable = enabled;
            if enabled
                task.ReturnImportOptionsCB.Tooltip = '';
            else
                task.ReturnImportOptionsCB.Tooltip = gs("ImportOptionsCheckboxTooltip");
            end
        end

        function setUseVarsFromFileEnabled(task, enabled)
            % Sets "Data has variable names" enabled.  Sets a tooltip when
            % it is disabled.

            arguments
                task
                enabled (1,1) logical
            end

            task.UseVarsFromFileCB.Enable = enabled;
            if enabled
                task.UseVarsFromFileCB.Tooltip = '';
            else
                task.UseVarsFromFileCB.Tooltip = gs("UseVarsFromFileTooltip");
            end
        end

        function setShowImportOptionsEnabled(task)
            % Sets "Show import options" enabled based on whether "Return
            % import options" is checked
            task.ShowImportOptionsCB.Enable = task.returnImportOptions();
        end

        function currSel = resolveSelectionWithOutput(task, currSel, outputType)
            % Resolve selection with the "Data has variable names" checkbox
            % value.  The effect of this checkbox is to move the selection
            % up a row, if it currently includes the variable names row.
            rows = [currSel(1), currSel(3)];
            cols = [currSel(2), currSel(4)];
            isTabularOutput = outputType.isTabular();
            hasVarNameRow = task.UseVarsFromFileCB.Value;
            if isTabularOutput && ~isempty(rows) && ~isempty(cols) && ...
                    size(rows,2) == 2 && ~any(rows == 0, "all") && ~any(cols == 0, "all")
                rows = sortrows(rows);
                varNamesRow = task.ViewModel.getTableModelProperty("VariableNamesRow");
                if isempty(varNamesRow)
                    varNamesRow = 1;
                end
                if hasVarNameRow && rows(1) <= varNamesRow && rows(2) > varNamesRow
                    % Reset the selection by moving the selection to be below
                    % the variable names row.
                    currSel(1) = varNamesRow + 1;
                elseif ~hasVarNameRow && rows(1) > 1
                    currSel(1) = max([rows(1) - 1, 1, varNamesRow]);
                end
            end
        end
    end

    methods(Static, Hidden)
        function code = getResolvedCode(c)
            % strip of header comments and remove section breaks
            firstCode = find(~startsWith(c, "%"));
            if ~isempty(firstCode)
                firstCode = firstCode(1);
                c = c(firstCode-1:end);
                c = strrep(c, "%%", "%");

                clearCmd = strtrim(extractBefore(c(end), "opts") + extractAfter(c(end), "opts"));
                if strcmp(clearCmd, "clear")
                    % Remove clear opts line and comment above it
                    code = strjoin(c(1:end-2), newline);
                elseif ismissing(clearCmd)
                    code = c;
                else
                    code = strjoin(c(1:end-1), newline) + newline + clearCmd;
                end
            else
                code = c;
            end

            if ~isscalar(code)
                code = strjoin(code, newline);
            end
        end
    end
end

function s = gs(msg, varargin)
    if nargin == 1
        s = getString(message("MATLAB:datatools:importlivetask:" + msg));
    else
        s = getString(message("MATLAB:datatools:importlivetask:" + msg, varargin{:}));
    end
end

