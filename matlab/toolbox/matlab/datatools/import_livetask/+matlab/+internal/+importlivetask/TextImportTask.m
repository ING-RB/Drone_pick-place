% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides a implementation for text file import in the Live Editor.

% Copyright 2022-2024 The MathWorks, Inc.

classdef TextImportTask < matlab.internal.importlivetask.TabularImportTask

    methods
        function task = TextImportTask()
            task.ImportType = "text";
            task.IsDefaultImporter = true;
        end

        function lst = getSupportedFileExtensions(~)
            lst = [".csv", ".txt"];
        end

        function fileSelected(task, accordionParent, ~)
            % Output Variable Type section
            task.addOutputVarTypeSection(accordionParent);

            % Display Results accordion section
            task.addDisplayResultsSection(accordionParent);
        end

        function code = initializeCode(task, filename)
            varName = matlab.internal.importlivetask.ImportTask.getVarNameFromFileName(task.Filename);

            tfi = internal.matlab.importtool.server.TextFileImporter(struct("FileName", filename));
            tfi.UseNumericVarNames = true;
            task.DataModel = internal.matlab.importtool.server.TabularImportDataModel(tfi);
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
            codeGenerator = internal.matlab.importtool.server.TextCodeGenerator(false);
            codeGenerator.ShortCircuitCode = true;
        end

        function setTaskState(task, state)
            setTaskState@matlab.internal.importlivetask.TabularImportTask(task, state);

            % Recreate the ViewModel/DataModel, using the saved import
            % options
            tfi = internal.matlab.importtool.server.TextFileImporter(...
                struct("FileName", task.getFullFilename(), ...
                "ImportOptions", task.LastImportOptions));
            task.DataModel = internal.matlab.importtool.server.TabularImportDataModel(tfi);
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
            opts = delimitedTextImportOptions("NumVariables", length(optsStruct.VariableNames));
            opts.VariableNames = optsStruct.VariableNames;
            opts.VariableTypes = optsStruct.VariableTypes;
            if isrow(optsStruct.DataLines)
                opts.DataLines = optsStruct.DataLines;
            else
                opts.DataLines = optsStruct.DataLines';
            end
        end
    end
end
