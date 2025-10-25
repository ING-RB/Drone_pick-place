% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides a implementation for spreadsheet file import in the Live Editor.

% Copyright 2022-2024 The MathWorks, Inc.

classdef SpreadsheetImportTask < matlab.internal.importlivetask.TabularImportTask

    properties
        SheetsGrid matlab.ui.container.GridLayout
        SheetsLabel matlab.ui.control.Label
        SheetDropDown matlab.ui.control.DropDown
        SheetName string = strings(0);
    end

    methods
        function task = SpreadsheetImportTask()
            task.ImportType = "spreadsheet";
        end

        function lst = getSupportedFileExtensions(~)
            lst = [matlab.io.internal.xlsreadSupportedExtensions, '.ods'];
        end

        function fileSelected(task, accordionParent, sourceGrid)
            %
            % Sheet Selection - Row 2 in Select Source
            %
            task.SheetsGrid = task.createGrid(sourceGrid, {'fit', 'fit'}, 0);
            task.SheetsGrid.Padding = [10 0 10 0];
            task.SheetsGrid.Layout.Row = 3;
            task.SheetsGrid.Layout.Column = 1;

            task.SheetsLabel = uilabel(task.SheetsGrid);
            task.SheetsLabel.Layout.Row = 1;
            task.SheetsLabel.Layout.Column = 1;
            task.SheetsLabel.Text = gs("SheetLabel");
            task.SheetsLabel.Visible = "off";

            task.SheetDropDown = uidropdown(task.SheetsGrid);
            task.SheetDropDown.Layout.Row = 1;
            task.SheetDropDown.Layout.Column = 2;
            task.SheetDropDown.Visible = "off";
            task.SheetDropDown.ValueChangedFcn = @(~,~) task.sheetChanged();

            % Reset the task's SheetName.  It will get reinitialized when the
            % sheets list is updated.
            task.SheetName = strings(0);

            % Output Variable Type section
            task.addOutputVarTypeSection(accordionParent);

            % Display Results accordion section
            task.addDisplayResultsSection(accordionParent);
        end

        function code = initializeCode(task, filename)
            varName = matlab.internal.importlivetask.ImportTask.getVarNameFromFileName(task.Filename);
            sheets = internal.matlab.importtool.server.ImportUtils.getSheetNames(filename);
            if isempty(task.SheetName)
                task.SheetName = sheets(1);
            end
            task.SheetsLabel.Visible = "on";
            task.SheetDropDown.Items = sheets;
            task.SheetDropDown.Visible = "on";
            task.SheetsGrid.RowHeight = {'fit'};
            task.ImportType = "spreadsheet";

            sfi = internal.matlab.importtool.server.SpreadsheetFileImporter(struct("FileName", filename, "SheetName", task.SheetName));
            sfi.UseNumericVarNames = true;
            task.DataModel = internal.matlab.importtool.server.TabularImportDataModel(sfi);
            task.ViewModel = internal.matlab.importtool.server.TabularImportViewModel(task.DataModel, true);
            state = task.DataModel.getState();
            task.InitialValidNames = isequal(state.CurrentArbitraryVariableNames, state.CurrentValidVariableNames);

            outputType = task.ViewModel.getTableModelProperty("OutputVariableType");
            if ~isempty(outputType)
                task.LastOutputType = outputType;
            end

            sel = task.DataModel.getInitialSelection;
            sel = task.resolveSelectionWithOutput(sel, ...
                internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(outputType));

            range = internal.matlab.importtool.server.ImportUtils.toExcelRange(sel(1), sel(3), sel(2), sel(4));
            task.LastSelection = range;
            task.ViewModel.setTableModelProperty("excelSelection", range);

            [opts, ~, ~] = task.ViewModel.getImportOptions(range);
            if startsWithDateDuration(task, opts)
                setTimetableOutput(task, opts, task.ViewModel);
            end
            [c, ~, codeDescription] = task.ViewModel.generateScriptCode(varName, false, true);
            task.CodeContainsImportOptions = codeDescription.containsImportOptions;
            task.setReturnImportOptionsEnabled(task.CodeContainsImportOptions);
            task.setShowImportOptionsEnabled();

            task.LastImportOptions = opts;
            task.LastCode = task.getResolvedCode(c);
            task.LastVarName = varName;

            code = task.LastCode;
        end

        function codeGenerator = getCodeGenerator(~)
            codeGenerator = internal.matlab.importtool.server.SpreadsheetCodeGenerator(false);
            codeGenerator.ShortCircuitCode = true;
        end

        function state = getTaskState(task)
            state = getTaskState@matlab.internal.importlivetask.TabularImportTask(task);
            state.sheetName = task.SheetName;

            % Future:  don't save sheets in the state
            if isvalid(task.SheetDropDown)
                state.sheets = string(task.SheetDropDown.Items);
            end
        end

        function setTaskState(task, state)
            setTaskState@matlab.internal.importlivetask.TabularImportTask(task, state);

            % Restore the sheets dropdown contents and value
            task.SheetsLabel.Visible = "on";
            task.SheetDropDown.Items = cellstr(sheetnames(task.getFullFilename()));
            task.SheetDropDown.Value = state.sheetName;
            task.SheetDropDown.Visible = "on";
            task.SheetsGrid.RowHeight = {'fit'};
            task.SheetName = state.sheetName;

            % Recreate the ViewModel/DataModel, using the saved import
            % options
            sfi = internal.matlab.importtool.server.SpreadsheetFileImporter(...
                struct("FileName", task.getFullFilename(), ...
                "SheetName", task.SheetName, ...
                "ImportOptions", task.LastImportOptions));
            task.DataModel = internal.matlab.importtool.server.TabularImportDataModel(sfi);
            task.ViewModel = internal.matlab.importtool.server.TabularImportViewModel(task.DataModel, true);
            dmState = task.DataModel.getState();
            task.InitialValidNames = isequal(dmState.CurrentArbitraryVariableNames, dmState.CurrentValidVariableNames);

            sel = task.DataModel.getInitialSelection;
            sel = task.resolveSelectionWithOutput(sel, ...
                internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(task.LastOutputType));
            range = internal.matlab.importtool.server.ImportUtils.toExcelRange(sel(1), sel(3), sel(2), sel(4));
            task.LastSelection = range;
            task.ViewModel.setTableModelProperty("excelSelection", range);

            [opts, ~, ~] = task.ViewModel.getImportOptions(range);
            [c, ~, codeDescription] = task.ViewModel.generateScriptCode(state.lastVarName, false, true);
            task.CodeContainsImportOptions = codeDescription.containsImportOptions;
            task.setReturnImportOptionsEnabled(task.CodeContainsImportOptions);
            task.setShowImportOptionsEnabled();
            task.LastImportOptions = opts;
            task.LastCode = task.getResolvedCode(c);
        end

        function opts = recreateImportOptsFromStruct(~, optsStruct)
            opts = spreadsheetImportOptions("NumVariables", length(optsStruct.VariableNames));
            opts.VariableNames = optsStruct.VariableNames;
            opts.VariableTypes = optsStruct.VariableTypes;
            opts.DataRange = optsStruct.DataRange;
            opts.Sheet = optsStruct.Sheet;
        end
    end

    methods(Access = protected)
        function sheetChanged(task)
            task.SheetName = task.SheetDropDown.Value;
            task.initializeCode(task.getFullFilename);

            % Changing the sheet resets the output type to its detected
            % type (table or timetable), so make sure the dropdown reflects
            % this
            task.OutputTypeDropDown.Value = task.LastOutputType;

            task.notifyChange();
        end

        function [c, codeDescription] = generateScriptForOutputType(task, outputType)
            codeGenerator = task.getCodeGenerator();
            selection = task.resolveSelectionWithOutput(...
                task.DataModel.FileImporter.getInitialSelection, outputType);

            % Spreadsheet selection always starts at column 1, even if the
            % data doesn't start there
            selection(2) = 1;
            [c, codeDescription] = codeGenerator.generateScript(task.LastImportOptions, ...
                "Filename", task.getFullFilename, ...
                "VarName", task.LastVarName, ...
                "OutputType", outputType, ...
                "OriginalOpts", task.DataModel.FileImporter.OriginalOpts, ...
                "InitialSelection", selection, ...
                "InitialSheet", task.SheetDropDown.Items{1}, ...
                "Range", internal.matlab.importtool.server.ImportUtils.toExcelRange(selection(1), selection(3), selection(2), selection(4)), ...
                "ArbitraryVarNames", task.isArbitraryVarNames, ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);
        end
    end
end

function s = gs(msg)
    s = getString(message("MATLAB:datatools:importlivetask:" + msg));
end

