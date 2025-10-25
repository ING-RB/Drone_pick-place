% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for MAT file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef MATFileImportProvider < matlab.internal.importdata.ImportVarSelectionProvider & matlab.internal.importdata.FilterableProvider
    properties
        MATFileVarNames string = strings(0);
    end

    properties (Hidden)
        VariablesTable = [];
        SelectAllCheckBox = [];
    end

    properties (Constant)
        % 500 MB
        LARGE_MAT_FILE = 1024*1024*500;
    end

    methods
        function this = MATFileImportProvider(filename)
            % Create an instance of an MATFileImportProvider

            arguments
                filename (1,1) string = "";
            end

            this = this@matlab.internal.importdata.ImportVarSelectionProvider(filename);

            this.FileType = "MAT";
            this.HeaderComment = "% " + getString(message("MATLAB:datatools:importdata:CodeCommentMAT"));
        end

        function lst = getSupportedFileExtensions(~)
            lst = "mat";
        end

        function summary = getTaskSummary(task)
            if isempty(task.Filename) || strlength(task.Filename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.Filename);
                summary = getString(message("MATLAB:datatools:importdata:MATSummary", "`" + file + ext + "`"));
            end
        end

        function outputs = getOutputs(task, ~)
            outputs = cellstr(task.SelectedVarNames);
        end

        function code = generateVisualizationCode(task, ~)
            if isempty(task.ImportDataCheckBox) || ~isvalid(task.ImportDataCheckBox)
                code = '';
            elseif task.ImportDataCheckBox.Value
                code = strjoin(task.SelectedVarNames, ",");
            else
                code = '';
            end
        end

        function fileSelected(task, accordionParent, ~)
            % Called when a file is selected for the Import Live Task.
            [varNames, variables] = task.getVariables();

            % Create a table to display the variables from the MAT file.
            w = matlab.internal.datatoolsservices.getWorkspaceDisplay(variables);

            if ~isempty(w)
                t = struct2table(w);
                t = removevars(t, "IsSummary");
                t.(1) = varNames;
            else
                t = table([], [], [], []);
            end

            t.Properties.VariableNames = {...
                getString(message("MATLAB:codetools:variableeditor:Name")), ...
                getString(message("MATLAB:codetools:variableeditor:Size")), ...
                getString(message("MATLAB:codetools:variableeditor:Class")), ...
                getString(message("MATLAB:codetools:variableeditor:Value"))};

            t = addvars(t, true(height(t), 1), 'Before', 1);
            t.Properties.VariableNames{1} = getString(message("MATLAB:datatools:importdata:ImportCheckbox"));

            [~, tableGrid] = task.createAccordionPanel( ...
                accordionParent, getString(message("MATLAB:datatools:importlivetask:MATVariableSelection")), {'fit'}, 2);
            task.SelectAllCheckBox = uicheckbox("Parent", tableGrid, ...
                "Text", getString(message("MATLAB:datatools:importdata:SelectAllLabel")), ...
                "Value", true);
            task.SelectAllCheckBox.ValueChangedFcn = @(es, ed) task.SelectAllCheckBoxValueChanged();

            task.VariablesTable = uitable("Parent", tableGrid);
            task.VariablesTable.Data = t;
            task.VariablesTable.ColumnName = t.Properties.VariableNames;
            task.VariablesTable.ColumnEditable = [true, false(1,4)];
            task.VariablesTable.CellEditCallback = @(es, ed) task.updateCodeAndNotifyChange();
            task.VariablesTable.Visible = 'on';

            %
            % Create Display Results accordion section
            %
            [task.ResultsPanel, resultsGrid] = task.createAccordionPanel( ...
                accordionParent, getString(message("MATLAB:datatools:importlivetask:DisplayResultsLabel")), {'fit'}, 1);
            task.ResultsPanel.collapse();
            task.addOutputSection(resultsGrid);
        end

        function state = getTaskState(task)
            % Get the task state.  Adds in the selected variable names, on top
            % of the common task state.
            state = getTaskState@matlab.internal.importdata.ImportProvider(task);

            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox)
                state.selectedVarNames = task.SelectedVarNames;
            end
        end

        function setTaskState(task, state)
            % Set the task state.  Uses the selected variable names from the
            % state to populate the table.
            setTaskState@matlab.internal.importdata.ImportProvider(task, state);
            task.SelectedVarNames = state.selectedVarNames;

            % Update the table to only show the selected Variable Names
            varNames = task.VariablesTable.Data.(2);
            task.VariablesTable.Data.(1) = contains(varNames, state.selectedVarNames);
        end

        function code = getImportCode(this)
            % Called to get the import code for importing from a MAT file.

            if isempty(this.SelectedVarNames)
                % No variables are selected, return empty
                code = strings(0);
            elseif this.SupportsVariableRename
                % Generate code which supports variable rename -- so it
                % includes explict assignments to the variables.  This is
                % done by using the output struct of the load function.
                code = this.getLoadImportCodeWithAssignment();
            else
                % Generate code which uses load directly (without output
                % arguments)
                code = this.getLoadImportCode();
            end
        end

        function code = getLoadImportCodeWithAssignment(this)
            % Called to get the import code for importing from a MAT file.
            % Code is generated using the output struct, and explicit
            % assignment is done.  For example:
            %
            % matlab = load("matlab.mat", "x", "y");
            % x = matlab.x;
            % y = matlab.y;
            % clear matlab;

            arguments
                this (1,1) matlab.internal.importdata.MATFileImportProvider
            end

            % Create the struct name using the filename, but make sure it
            % is unique in regards to the variables being loaded.
            [~, varName, ~] = fileparts(this.getFullFilename);
            structVarName = matlab.lang.makeUniqueStrings(...
                matlab.lang.makeValidName(varName), ...
                this.SelectedVarNames, namelengthmax);

            if isequal(this.SelectedVarNames, this.MATFileVarNames)
                % All variables are selected, generate code with just the
                % filename, capturing the output struct.

                code = structVarName + " = load(""" + this.getFullFilename + """);";
            else
                % A subset of variables are selected, generate code with the
                % filename and selected variables, capturing the output struct

                code = structVarName + " = load(""" + this.getFullFilename + """, """ + join(this.SelectedVarNames, """, """) + """);";
            end

            for idx = 1:length(this.SelectedVarNames)
                code = code + newline + this.SelectedVarNames(idx) + " = " + structVarName + "." + this.SelectedVarNames(idx) + ";";
            end
            code = code + newline + "clear " + structVarName + ";";

            this.LastCode = code;
        end

        function code = getLoadImportCode(this)
            % Called to get the import code for importing from a MAT file.  If
            % all variables are selected, the code will be load filename.mat,
            % otherwise it will be something like load filename.mat X Y

            arguments
                this (1,1) matlab.internal.importdata.MATFileImportProvider
            end

            if isequal(this.SelectedVarNames, this.MATFileVarNames)
                % All variables are selected, generate code with just the
                % filename.

                if contains(this.getFullFilename, " ")
                    % If the filename contains a space, we need to call load
                    % using function syntax, for example:
                    % load("filename.mat")
                    code = "load(""" + this.getFullFilename + """)";
                else
                    % Call the load function using command syntax, for example:
                    % load filename.mat
                    code = "load " + this.getFullFilename;
                end
            else
                % A subset of variables are selected, generate code with the
                % filename and selected variables

                if contains(this.getFullFilename, " ")
                    % If the filename contains a space, we need to call load
                    % using function syntax, for example:
                    % load("filename.mat", "X", "Y")
                    code = "load(""" + this.getFullFilename + """, """ + join(this.SelectedVarNames, """, """) + """)";
                else
                    % Call the load function using command syntax, for example:
                    % load filename.mat X Y
                    code = "load " + this.getFullFilename + " " + join(this.SelectedVarNames, " ");
                end
            end
            this.LastCode = code;
        end

        function [varNames, vars] = getVariables(this)
            % Called to get the variables to display.  Use the matfile object to
            % get the variables from the file.

            arguments
                this (1,1) matlab.internal.importdata.MATFileImportProvider
            end

            if this.isLargeMATFile()
                % Create a matfile object for the MAT file
                mfile = matfile(this.getFullFilename);

                % Get the variables from the matfile object
                varNames = who(mfile);
            else
                % For smaller MAT files it is orders of magnitude quicker
                % to just load the variables.  (This is what was done in
                % the Java Desktop)
                try
                    mfile = load(this.getFullFilename);

                    % Get the variables from the struct which contains the
                    % loaded variables
                    varNames = fieldnames(mfile);
                catch
                    % Ignore errors when getting the code.  The same errors will appear
                    % in the Live Task or when actually imported.
                    varNames = {};
                end
            end

            vars = {};
            origVarNames = varNames;
            varNames = string(varNames);
            if iscell(this.FilterFunction)
                filterFuncs = this.FilterFunction;
            else
                filterFuncs = {this.FilterFunction};
            end

            w = warning("off", "MATLAB:load:cannotInstantiateLoadedVariable");
            c = onCleanup(@() warning(w));

            for idx = 1:length(origVarNames)

                try
                    varName = origVarNames{idx};

                    % Get the variable from the workspace
                    var = mfile.(varName);

                    addVar = this.isValidForFilter(var, filterFuncs);
                catch
                    % There was a filter function, where the variable failed to
                    % meet the criteria.
                    addVar = false;
                end

                if addVar
                    % If we've reached this line, then either there was no
                    % filter function, or the variable passes the filter
                    % function's criteria
                    vars{end+1} = var; %#ok<AGROW>
                else
                    varNames(varNames == varName) = [];
                end
            end

            this.MATFileVarNames = string(varNames);
            this.SelectedVarNames = this.MATFileVarNames;
        end
    end

    methods (Access = private)
        function b = isLargeMATFile(this)
            try
                d = dir(this.getFullFilename);
                b = d.bytes > this.LARGE_MAT_FILE;
            catch
                % Don't worry about errors at this time -- they will be
                % seen when the code is actually executed.
                b = false;
            end
        end

        function SelectAllCheckBoxValueChanged(this)
            % Callback for the Select All checkbox, sets the first column of the
            % table data to all true or false.
            value = this.SelectAllCheckBox.Value;
            tb = this.VariablesTable.Data;
            if value
                tb.(1) = true(height(tb), 1);
            else
                tb.(1) = false(height(tb), 1);
            end
            this.VariablesTable.Data = tb;
            this.updateCodeAndNotifyChange();
        end

        function updateCodeAndNotifyChange(this)
            % Called when the table is edited (only the first column is
            % editable), and when the select all checkbox changes.  Updates the
            % selected variable names and generated code, and notifies of the
            % change.
            this.SelectedVarNames = this.MATFileVarNames(this.VariablesTable.Data.(1));
            this.SelectAllCheckBox.Value = all(this.VariablesTable.Data.(1));
            this.getImportCode();
            this.notifyChange();
        end
    end
end
