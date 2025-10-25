% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the base class for providing information for an import type.  It
% has an abstract method, getImportCode, which needs to be implemented.

% Copyright 2020-2024 The MathWorks, Inc.

classdef ImportProvider < matlab.internal.commonimport.BaseImportTask
    properties
        FileType string = strings(0);
        SelectedVarNames string = strings(0);
        SynchronousImport logical = false;
        ResolveVariableNames logical = false;
        HeaderComment string = strings(0);
        
        % Whether this import provider supports the "Don't show again for this file type" preference
        SupportsSkippingDialog (1,1) logical = false;
    end

    methods
        function this = ImportProvider(fileToImport)
            % Creates an ImportProvider instance

            arguments
                fileToImport (1,1) string;
            end

            this = this@matlab.internal.commonimport.BaseImportTask("Parent", uifigure("Visible", "off"));

            % Set the Directory/Filename from the argument
            [path, file, ext] = fileparts(fileToImport);
            this.Directory = path;
            this.Filename = file + ext;
        end

        function [varNames, vars] = getVariables(this)
            % Return the variable names and variables  created by the generated
            % code.  This is done by creating the variables by eval'ing the
            % code, and returning the names and variables in cell arrays

            arguments
                this matlab.internal.importdata.ImportProvider
            end

            try
                eval(this.getImportCode);
                w = who;

                % Ignore the 'this' variable, as it belongs to this function
                w(w == "this") = [];

                vars = cell(length(w), 1);
                varNames = cell(length(w), 1);

                for idx = 1:length(w)
                    varName = w{idx};
                    vars{idx} = eval(varName);
                    varNames{idx} = varName;
                end
            catch
                % Ignore failures when opening -- the same failures will appear in the live task
                % or upon actual import
                vars = {};
                varNames = {};
            end
        end

        function updateShowDialogPref(this, newValue)
            % Sets the preference setting for whether to show this dialog or not
            % to the new preference setting

            arguments
                this matlab.internal.importdata.ImportProvider
                newValue logical
            end

            % preference setting will start with the fileType, like:
            % audioShowDialog
            prefSetting = this.FileType + "ShowDialog";
            s = settings;
            if hasSetting(s.matlab.importtool, prefSetting)
                st = s.matlab.importtool.(prefSetting);
                st.PersonalValue = newValue;
            else
                addSetting(s.matlab.importtool, prefSetting, "PersonalValue", newValue);
            end
        end

        function v = getShowDialogPref(this)
            % Return the current setting for whether to show the import data
            % dialog or not, for the given filetype

            arguments
                this matlab.internal.importdata.ImportProvider
            end

            prefSetting = this.FileType + "ShowDialog";
            s = settings;
            if hasSetting(s.matlab.importtool, prefSetting)
                st = s.matlab.importtool.(prefSetting);
                v = st.PersonalValue;
            else
                v = true;
            end
        end

        function state = getTaskState(task)
            state = struct;

            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox)
                % Future - no need to save lastCode
                state.lastCode = task.LastCode;

                % Future - only set this if it isn't the default value
                % if ~task.ImportDataCheckBox.Value  
                    state.importDataCheckBox = task.ImportDataCheckBox.Value;
                % end
            end
        end

        function setTaskState(task, state)
            if isfield(state, "importDataCheckBox")
                task.ImportDataCheckBox.Value = state.importDataCheckBox;
            else
                task.ImportDataCheckBox.Value = true;
            end
        end

        function reset(~)
            % Reset all options for currently selected file.  By default there
            % are no additional options, but override if there are.
        end

        function code = initializeCode(task, ~)
            arguments (Output)
                code (1,1) string
            end

            code = task.getImportCode();
        end

        function code = updateCodeForOutputOptions(task, code)
            arguments (Input)
                task
                code string % treat all code as strings
            end

            arguments (Output)
                code (1,1) string
            end

            if strlength(task.HeaderComment) > 0
                code = task.HeaderComment + newline + code;
            end
            code = code + newline;
        end

        function fileSelected(task, accordionParent, ~)
            task.getVariables();

            %
            % Create Display Results accordion section
            %
            [task.ResultsPanel, resultsGrid] = task.createAccordionPanel( ...
                accordionParent, getString(message("MATLAB:datatools:importlivetask:DisplayResultsLabel")), {'fit'}, 1);
            task.ResultsPanel.collapse();
            task.addOutputSection(resultsGrid);
        end

        function addOutputSection(task, resultsGrid)
            % Output panel - Row 1 in Display results section
            task.OutputGrid = task.createGrid(resultsGrid, {'fit'}, {'1x'});
            task.OutputGrid.ColumnSpacing = 20;
            task.OutputGrid.Padding = [0 0 0 0];
            task.OutputGrid.Layout.Row = 1;
            task.OutputGrid.Layout.Column = 1;

            % Create ImportDataCheckBox
            task.ImportDataCheckBox = uicheckbox(task.OutputGrid);
            task.ImportDataCheckBox.Text = getString(message("MATLAB:datatools:importlivetask:ImportedDataCheckbox"));
            task.ImportDataCheckBox.Layout.Row = 1;
            task.ImportDataCheckBox.Layout.Column = 1;
            task.ImportDataCheckBox.Value = true;
            task.ImportDataCheckBox.ValueChangedFcn = @(~,~) task.notifyChange();
        end

        function outputs = getOutputs(~, lhs)
            outputs = {lhs};
        end

        function code = generateVisualizationCode(task, lhs)
            arguments (Output)
                code (1,1) string
            end

            if isempty(task.ImportDataCheckBox) || ~isvalid(task.ImportDataCheckBox)
                code = "";
            elseif task.ImportDataCheckBox.Value
                code = string(lhs);
            else
                code = "";
            end
        end
    end

    methods(Abstract)
        % Called to get the code to execute to import this.Filename
        code = getImportCode(this);
    end

    methods(Access = protected)
        function v = getUniqueVarName(this, varName)
            % Can be used to generate unique variable names, based on the
            % content in the base workspace

            arguments
                this matlab.internal.importdata.ImportProvider
                varName (1,1) string
            end

            if ~this.ResolveVariableNames || this.SynchronousImport
                % Don't resolve against contents of the user's workspace
                v = matlab.lang.makeUniqueStrings(...
                    matlab.lang.makeValidName(varName), ...
                    {}, namelengthmax);
            else
                v = matlab.lang.makeUniqueStrings(...
                    matlab.lang.makeValidName(varName), ...
                    evalin("base", "who"), namelengthmax);
            end
        end

        function code = getPlotTitleCodeForFilename(task, tag)
            [~, fname, ext] = fileparts(string(task.Filename));
            if matches(fname, asManyOfPattern(alphanumericsPattern | "." | "-"))
                code = "title(""" + getString(message("MATLAB:datatools:importdata:" + tag, fname + ext)) + """);";
            else
                % Generate code to set the interpreter as well if the
                % filename contains non-alpha/numeric or - characters.
                % The other characters (like underscore) can be
                % interpreted as tex characters (which is the default
                % interpreter)
                code = "title(""" + getString(message("MATLAB:datatools:importdata:" + tag, fname + ext)) + """, ""Interpreter"", ""none"");";
            end
        end
    end
end
