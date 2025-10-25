% This class is unsupported and might change or be removed without notice in a
% future version.

% This is the base class for an import Live Task for the Live Editor.

% Copyright 2022-2023 The MathWorks, Inc.

classdef BaseImportTask < matlab.task.LiveTask

    properties
        % Last code generated
        LastCode string = strings(0);

        % Last variable name(s) generated
        LastVarName string = strings(0);

        % Directory for the selected file
        Directory string  = strings(0);

        % Filename (only) for the selected file
        Filename string = strings(0);

        % Whether this is the default import task or not
        IsDefaultImporter (1,1) logical = false;

        % Summary of the import
        Summary

        % State to save/restore for this specific import task
        State

        % Whether this configuration of import supports renaming variables
        SupportsVariableRename (1,1) logical = false;

        % If renaming is supported, whether the variables were renamed
        VariablesRenamed (1,1) logical = false;

        % If the "Display Results" section should be shown
        SupportsResultDisplay = true;
    end

    properties(Hidden)
        ResultsPanel matlab.ui.container.internal.AccordionPanel
        OutputGrid matlab.ui.container.GridLayout
        ImportDataCheckBox matlab.ui.control.CheckBox
    end

    events (NotifyAccess = protected)
        PropertyChanged
    end

    methods(Abstract)
        % Get the file extensions supported by this Import Task.  For example:
        % [".xls", ".xlsx"]
        lst = getSupportedFileExtensions(this, filename);

        % Get the summary text to display.  For example:
        % "Table with 5 columns imported from file.csv"
        summary = getTaskSummary(task);

        % Called when a file of the supported type for this ImportTask is
        % selected.  The UI for this task should be setup during this method.
        fileSelected(task, accordionParent, sourceGrid);

        % Called to initialize the code based on the selected filename.  Returns
        % the code generated for the import of the selected file.
        code = initializeCode(task, filename);

        % Called to update the generated code based on the selected output
        % options.  For example, the code may need to include a 'clear varname'
        % if an output checkbox for varname is not selected.
        code = updateCodeForOutputOptions(task, code);

        % Called to get the outputs for the task.  For example, the table name
        % being imported.
        outputs = getOutputs(task, lhs);

        % Called to generate any visualization code needed for the output.  For
        % example, if there is a checkbox to show output 'varname', then the
        % code 'varname' needs to be generated (without the semi-colon) so it
        % will show in the Live Task output.
        code = generateVisualizationCode(task, lhs);

        % Called to add content to the state which is to be saved.  state is a
        % struct, and new fields can be added to it.
        state = getTaskState(task);

        % Called when the state of the app is restored.
        setTaskState(task, state)
    end

    methods(Static)
        function [accordion, grid] = createAccordionPanel(accordionParent, ...
                panelTitle, columnWidths, numRows, rowHeights)
            % Convenience function to create an accordion panel with a grid
            % layout as its child.

            arguments
                accordionParent matlab.ui.container.internal.Accordion
                panelTitle (1,1) string
                columnWidths
                numRows (1,1) double %#ok<INUSA>
                rowHeights = repmat({'fit'}, 1, numRows);
            end

            accordion = matlab.ui.container.internal.AccordionPanel("Parent", accordionParent);
            accordion.Title = panelTitle;
            grid = matlab.internal.commonimport.BaseImportTask.createGrid(accordion, columnWidths, rowHeights);
        end

        function grid = createGrid(parent, columnWidths, rowHeights)
            grid = uigridlayout(parent, "ColumnWidth", ...
                columnWidths, "RowHeight", rowHeights);
        end
    end

    methods
        function fullFilename = getFullFilename(task)
            % Convenience function to get the full filename of the selected data
            % source

            fullFilename = fullfile(task.Directory, task.Filename);
        end

        function summary = get.Summary(task)
            summary = task.getTaskSummary();
        end

        function state = get.State(task)
            state = task.getTaskState();
        end

        function set.State(task, state)
            task.setTaskState(state);
        end

        function [code, outputs] = generateCode(task)
            [code, outputs] = generateScript(task);
            vcode = generateVisualizationScript(task);
            if ~isempty(vcode) && strlength(vcode) > 0
                code = code + newline + newline + vcode;
            end
        end

        function notifyChange(task)
            % Convenience method, call when the state of the task changes.
            notify(task, "StateChanged");
        end

        function notifyPropertyChange(task, property, value)
            % Convenience method, call when the state of the task changes.  If no property is 
            % specified, it is assumed that the state of the task changed and the generated 
            % code should be updated.  If a property is specified (for example 'AutoRun'), then 
            % just that task property is updated.

            arguments
                task
                property (1,1) string;
                value = [];
            end

            eventData = matlab.internal.commonimport.SubTaskEventData(property, value);
            notify(task, "PropertyChanged", eventData);
        end

        function fileType = getSupportedFileType(~)
            % Can be overwritten to specify a file type which is supported by
            % this subtask (where the file type is something returned from
            % finfo).  For example, instead of listing all image file
            % extensions, getSupportedFileType can just return 'image'.
            fileType = string.empty;
        end

        function filetype = getFormatForFile(~, filename)
            % Can be overwritten to specify the format to display for a given
            % file in the Live Task source selection section.  By default the
            % file extension will be shown, but can be overwritten to specify
            % something different.
            [~, ~, ext] = fileparts(filename);
            filetype = upper(extractAfter(ext, "."));
        end
    end

    methods (Access = protected)
        function setup(~)
        end
    end
end