% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides the implementation for the Import Live Task in the Live
% Editor.

% Copyright 2022-2025 The MathWorks, Inc.

classdef (Hidden = true, Sealed = true) ImportTask < matlab.task.LiveTask

    properties (Access = public, Transient, Hidden)
        UIFigure matlab.ui.Figure
    end

    properties (Access = public)
        Accordion matlab.ui.container.internal.Accordion
        SourcePanel matlab.ui.container.internal.AccordionPanel

        FileGrid matlab.ui.container.GridLayout
        SourceGrid matlab.ui.container.GridLayout
        BrowseButton matlab.ui.control.Button
        FileEditField matlab.ui.control.EditField
        FileEditFieldLabel matlab.ui.control.Label
        FormatSizeLabel matlab.ui.control.Label
    end

    properties (Access = {?matlab.internal.importlivetask.ImportTask, ?matlab.unittest.TestCase})
        LastCode string
        LastVarName

        Directory string  = strings(0);
        Filename string = strings(0);

        StateChangedListener
        PropertyChangedListener

        % Keep track of the previously selected file, so state can be
        % reverted on errors.
        PreviousFile string = strings(0);

        % Track whether the file exists after loading the live task via a
        % new task state, and save the state from the previous load.
        FileExistsAfterLoad (1,1) logical = true;
        LastLoadedState = [];
    end

    properties
        Summary
        State
        Workspace = "base"
    end

    properties(Hidden)
        CurrentSubTask;
        ImportersByType
        ImportersByExtension
    end

    events
        LogDDUX
    end

    methods
        function task = ImportTask(fig, workspace)
            arguments
                fig = uifigure;
                workspace = "base";
            end
            task@matlab.task.LiveTask("Parent", fig);
            task.UIFigure = fig;
            task.Workspace = workspace;

            [a, b] = matlab.internal.commonimport.DataImporters.getLiveTaskDataImporters();
            task.ImportersByExtension = a;
            task.ImportersByType = b;
        end

        function delete(task)
            % Delete the CurrentSubTask
            if ~isempty(task.CurrentSubTask)
                delete(task.CurrentSubTask);
            end

            % Check for open Import Tools
            titm = internal.matlab.importtool.peer.TextImportToolManager.getInstance;
            textIT = titm.getSetInstances("/ImportLiveTask", []);
            if ~isempty(textIT)
                textIT.browserWindowClosed();
            end

            sitm = internal.matlab.importtool.peer.SpreadsheetImportToolManager.getInstance;
            spreadsheetIT = sitm.getSetInstances("/ImportLiveTask", []);
            if ~isempty(spreadsheetIT)
                spreadsheetIT.browserWindowClosed();
            end
        end

        function summary = get.Summary(task)
            if isempty(task.CurrentSubTask)
                summary = getString(message("MATLAB:datatools:importlivetask:ImportSummary"));
            else
                summary = task.CurrentSubTask.Summary;
            end
        end

        function state = get.State(task)
            state = struct;

            state.path = task.Directory;
            state.filename = task.Filename;

            if ~isempty(task.CurrentSubTask)
                state.currentImportTask = string(class(task.CurrentSubTask));

                subTaskState = task.CurrentSubTask.State;
                f = fieldnames(subTaskState);
                for idx = 1:length(f)
                    fname = f{idx};
                    state.(fname) = subTaskState.(fname);
                end
            end
        end

        function set.State(task, state)
            task.setTaskState(state);
        end

        function setTaskState(task, state)
            task.Filename = state.filename;
            task.Directory = state.path;
            task.FileEditField.Value = task.getFullFilename();

            if ~isempty(task.Filename) && strlength(task.Filename) > 0
                fname = fullfile(task.Directory, task.Filename);
                task.CurrentSubTask = task.createTaskFromName(state.currentImportTask);
                task.CurrentSubTask.Filename = task.Filename;
                task.CurrentSubTask.Directory = task.Directory;

                if exist(fname, 'file') == 0
                    % The file in the saved state doesn't exist.  Show a
                    % message in the task, but allow the task to load with
                    % its saved state.
                    task.FileExistsAfterLoad = false;
                    task.LastLoadedState = state;
                    task.createFormatSizeLabel();
                    task.FormatSizeLabel.Text = getString(message("MATLAB:datatools:importlivetask:FileNotFound", fname));
                    task.FormatSizeLabel.FontColor = [1, 0, 0];
                else
                    task.FileExistsAfterLoad = true;
                    task.addFormatAndSize();
                end

                % Remove any content added by the subtasks that may exist
                % in the task.  Calling fileSelected below will add in the
                % content using the new task state.  (Anything past the
                % first section is added by the subtask).
                task.removeAddedContent();

                task.CurrentSubTask.fileSelected(task.Accordion, task.SourceGrid);
                % last code isn't used
                % task.LastCode = state.lastCode;
                try
                    % Load the current state, and handle any errors that
                    % may occur if the file didn't exist.
                    task.CurrentSubTask.setTaskState(state);
                    if isa(task.CurrentSubTask, "matlab.internal.importdata.ImportProvider")
                        task.CurrentSubTask.getImportCode();
                    end
                    task.LastCode = task.CurrentSubTask.LastCode;
                catch
                end
                task.addEventListeners();
            end
        end

        function [code, outputs] = generateCode(task)
            [code, outputs] = generateScript(task);
            vcode = generateVisualizationScript(task);
            if strlength(vcode) > 0
                if ~endsWith(code, newline)
                    code = code + newline;
                end
                if ~endsWith(code, newline + "" + newline)
                    code = code + newline;
                end
                code = code + vcode;
            end

            % standardize on always returning a string array
            code = string(code);
        end

        function [code, outputs] = generateScript(task)
            % LastCode could be empty (strings(0))) or ""
            if isempty(task.LastCode) || strlength(task.LastCode) == 0
                code = "";
                outputs = {};
            else
                code = task.LastCode;

                if ~isempty(task.CurrentSubTask)
                    code = task.CurrentSubTask.updateCodeForOutputOptions(code);
                end
                lhs = task.getLHS();
                if isempty(lhs)
                    outputs = {};
                else
                    outputs = task.CurrentSubTask.getOutputs(lhs);
                end
            end
        end

        function code = generateVisualizationScript(task)
            arguments (Output)
                code (1,1) string
            end

            code = "";

            if ~isempty(task.CurrentSubTask)
                code = task.CurrentSubTask.generateVisualizationCode(task.getLHS());
                if strlength(code) > 0
                    code = "% " + getString(message("MATLAB:datatools:importlivetask:DisplayResultsComment")) + newline + code;
                end
            end
        end

        function reset(task, ~, ~)
            task.setChangeFilesEnabled(false);
            if ~isempty(task.CurrentSubTask)
                task.CurrentSubTask.reset();
                task.fileSelected();
            end
            task.setChangeFilesEnabled(true);
        end
    end

    methods (Access = protected)
        function setup(task)
            createComponents(task);
            doUpdate(task);
        end

        function createComponents(task)
            % task.LayoutManager is GridLayout
            task.Accordion = matlab.ui.container.internal.Accordion('Parent', task.LayoutManager);

            %
            % Select Source Accordion Panel
            %
            [task.SourcePanel, task.SourceGrid] = matlab.internal.commonimport.BaseImportTask.createAccordionPanel( ...
                task.Accordion, getString(message("MATLAB:datatools:importlivetask:SelectSource")), {'fit'}, 2);
            task.SourceGrid.Padding = [0 10 0 10];

            %
            % FileGrid - Row 1 in Select Source
            %
            task.FileGrid = matlab.internal.commonimport.BaseImportTask.createGrid( ...
                task.SourceGrid, {'fit', 400, 'fit'}, {'fit'});
            task.FileGrid.Layout.Row = 1;
            task.FileGrid.Layout.Column = 1;
            task.FileGrid.Padding = [8 0 0 0];

            % Create FileEditFieldLabel
            task.FileEditFieldLabel = uilabel(task.FileGrid);
            task.FileEditFieldLabel.HorizontalAlignment = "right";
            task.FileEditFieldLabel.Layout.Row = 1;
            task.FileEditFieldLabel.Layout.Column = 1;
            task.FileEditFieldLabel.Text = getString(message("MATLAB:datatools:importlivetask:FileLabel"));

            % Create FileEditField
            task.FileEditField = uieditfield(task.FileGrid, "text");
            task.FileEditField.Placeholder = getString(message("MATLAB:datatools:importlivetask:SelectFile"));
            task.FileEditField.Layout.Row = 1;
            task.FileEditField.Layout.Column = 2;
            task.FileEditField.ValueChangedFcn = @(~,~) task.fileTextFieldChanged();

            % Create BrowseButton
            task.BrowseButton = uibutton(task.FileGrid, 'push');
            task.BrowseButton.ButtonPushedFcn = @(~,~) task.browseButtonPushed();
            task.BrowseButton.Layout.Row = 1;
            task.BrowseButton.Layout.Column = 3;
            task.BrowseButton.Text = getString(message("MATLAB:datatools:importlivetask:BrowseButton"));
        end

        function doUpdate(~, ~, ~)
            % use src.Tag to figure out what changed
        end

        % Button pushed function: BrowseButton
        function browseButtonPushed(task)
            task.setChangeFilesEnabled(false);
            filter = matlab.internal.commonimport.DataImporters.getUIGetFileFilter(...
                matlab.internal.commonimport.DataImporters.getLiveTaskDataImporters);
            title = getString(message("MATLAB:datatools:importlivetask:FileSelectionTitle"));
            if isempty(task.Directory)
                [file, path] = uigetfile(filter, title);
            else
                [file, path] = uigetfile(filter, title, task.Directory);
            end

            if ~isequal(file, 0)
                f = fullfile(path, file);
                d = dir(fullfile(f));
                if d.bytes == 0
                    task.showErrorAndRevert("MATLAB:codetools:uiimport:CannotImportFromEmptyFile", ...
                        task.FileEditField.Value);
                    return;
                end

                task.handleFileChanged(f, path, file);
            else
                task.setChangeFilesEnabled(true);
            end
        end

        function fileTextFieldChanged(task)
            task.setChangeFilesEnabled(false);
            textEntered = strtrim(task.FileEditField.Value);
            currentFile = task.getFullFilename();

            if exist(fullfile(textEntered), "file") == 2
                % User entered a valid file

                if exist(fullfile(pwd, textEntered), "file") == 2
                    % User entered a partial path starting with pwd
                    textEntered = fullfile(pwd, textEntered);
                end
                [path, name, extension] = fileparts(fullfile(textEntered));
                if isempty(path)
                    w = which(textEntered);
                    if ~isempty(w)
                        [path, name, extension] = fileparts(w);
                    end
                end

                f = fullfile(path, string(name) + extension);
                d = dir(f);
                if d.bytes == 0
                    task.showErrorAndRevert("MATLAB:codetools:uiimport:CannotImportFromEmptyFile", ...
                        currentFile);
                    return;
                end

                task.handleFileChanged(f, path, string(name) + extension);
            else
                task.showErrorAndRevert("MATLAB:datatools:importlivetask:InvalidFile", ...
                    currentFile);
            end
        end
    end

    methods (Access = {?matlab.internal.importlivetask.ImportTask, ?matlab.unittest.TestCase})

        function setChangeFilesEnabled(task, enabled)
            % Called to set the browse button and text field enabled or
            % disabled.  They will be disabled while the file selection
            % dialog is open and when the task is updating for a new file
            % being selected.
            arguments
                task
                enabled (1,1) logical
            end
            task.BrowseButton.Enable = enabled;
            task.FileEditField.Enable = enabled;
        end
    end

    methods (Access = private)
        function lhs = getLHS(task)
            lhs = task.getVarNameFromFileName(task.Filename);
        end

        function fullFilename = getFullFilename(task)
            % Directory always has forward slashes
            fullFilename = fullfile(task.Directory, task.Filename);
        end

        function initializeCode(task)
            filename = task.getFullFilename;
            task.LastCode = task.CurrentSubTask.initializeCode(filename);
            notify(task, "StateChanged");
        end

        function notifyEmptyCode(task)
            % Called to notify the Live Script of a state change where the
            % code is empty.  This is needed in some cases so that
            % identical code will be executed (for example if the user has
            % a file open, clears the workspace, and then picks the same
            % file again).
            task.LastCode = "";
            notify(task, "StateChanged");
        end

        function handleFileChanged(task, fullPathFile, path, filename)
            % Called when the file changed either by selection from the
            % browse button, or if the user types in the textfield.
            setFileDefaults = true;
            task.notifyEmptyCode();
            if ~task.FileExistsAfterLoad && ~isempty(task.LastLoadedState) && ...
                    strcmp(task.LastLoadedState.filename, filename)
                % If the current file didn't exist after loading from the
                % task state, and the user only changed the path (the
                % filename remained the same), then update the saved state
                % to the new path, and reload the task from it.  This
                % allows users to share scripts with this task, and they
                % can just update the path to the filename.
                task.LastLoadedState.lastCode = strrep(task.LastLoadedState.lastCode, task.LastLoadedState.path, path);
                task.LastLoadedState.path = path;
                task.setTaskState(task.LastLoadedState);
                setFileDefaults = false;
                notify(task, "StateChanged");
                task.setChangeFilesEnabled(true);
            else
                task.Directory = path;
                task.Filename = filename;
                task.FileEditField.Value = fullPathFile;
            end

            task.Directory = path;
            task.Filename = filename;
            task.FileEditField.Value = fullPathFile;
            task.FileEditField.Tooltip = fullPathFile;

            if setFileDefaults
                task.fileSelected();
            end
            task.PreviousFile = task.FileEditField.Value;
            task.FileExistsAfterLoad = true;
            task.LastLoadedState = [];
            task.setChangeFilesEnabled(true);
        end

        function fileSelected(task)
            task.CurrentSubTask = [];
            fullFileName = task.getFullFilename;
            [~, ~, ext] = fileparts(fullFileName);
            ext = extractAfter(ext, ".");

            if isKey(task.ImportersByExtension, ext)
                task.CurrentSubTask = task.createTaskFromName(task.ImportersByExtension(ext));
            end

            if isempty(task.CurrentSubTask)
                % Repeat the loop, check file types.  Calling finfo takes time,
                % so file extensions are checked first.
                filetype = finfo(char(fullFileName));
                if isKey(task.ImportersByType, filetype)
                    task.CurrentSubTask = task.createTaskFromName(task.ImportersByType(filetype));
                end

                if isempty(task.CurrentSubTask)
                    % No sub-tasks were found which support this file extension
                    % or type, so import using the text import task
                    task.CurrentSubTask = matlab.internal.importlivetask.TextImportTask;
                end
            end
            
            % Log file selected DDUX event for sub-tasks
            task.logDDUXSubtask(ext);

            % Reset the code to prevent any previously selected file's code
            % from being executed.  It will be updated for the currently
            % selected file below when initializeCode is called.
            task.LastCode = "";
            task.CurrentSubTask.LastCode = "";

            if ~isempty(task.StateChangedListener)
                delete(task.StateChangedListener);
                delete(task.PropertyChangedListener);
                delete(task.Accordion.Children(2:end));
                delete(task.SourceGrid.Children(2:end));
            end
            task.addEventListeners();
            task.CurrentSubTask.Filename = task.Filename;
            task.CurrentSubTask.Directory = task.Directory;
            drawnow;

            % Set autorun when a new file is selected
            task.AutoRun = true;

            task.addFormatAndSize();

            try
                task.CurrentSubTask.fileSelected(task.Accordion, task.SourceGrid);
                task.initializeCode();
            catch
                task.showErrorAndRevert("MATLAB:codetools:importtool:ImportError", task.PreviousFile);
                if isempty(task.Filename) || strlength(task.Filename) == 0
                    task.FormatSizeLabel.Text = "";
                    task.removeAddedContent();
                end
            end
        end

        function removeAddedContent(task)
            % Called to remove any content added to the task by the
            % sub-tasks.  First, remove any additional accordion panels
            % which were added.
            childCount = length(task.Accordion.Children);
            if childCount > 1
                for idx = childCount:-1:2
                    delete(task.Accordion.Children(idx));
                end
            end

            % Next, remove any content added to the source panel by the
            % sub-tasks.  (For example, spreadsheet import adds the 'sheet'
            % menu to the source panel)
            sourceGrid = task.SourcePanel.Children;
            if ~isempty(sourceGrid)
                sourceChildCount = length(sourceGrid.Children);
                if sourceChildCount > 2
                    for idx = sourceChildCount:-1:2
                        if ~isequal(sourceGrid.Children(idx), task.FormatSizeLabel.Parent)
                            delete(sourceGrid.Children(idx));
                        end
                    end
                end
            end
        end

        function addFormatAndSize(task)
            % Add in the format and size display
            filename = task.getFullFilename();
            filetype = task.CurrentSubTask.getFormatForFile(filename);
            fileInfo = dir(filename);
            if isempty(fileInfo)
                return;
            end
            fileSize = matlab.internal.importlivetask.ImportTask.getFileSizeStr(fileInfo.bytes);

            task.createFormatSizeLabel();
            task.FormatSizeLabel.Interpreter = "html";
            fmtLabel = getString(message("MATLAB:datatools:importlivetask:FormatLabel"));
            sizeLabel = getString(message("MATLAB:datatools:importlivetask:SizeLabel"));
            task.FormatSizeLabel.Text = "<b>" + fmtLabel + "</b> " + filetype + ", <b>" + sizeLabel + "</b> " + fileSize;
        end

        function createFormatSizeLabel(task)
            % Create the format/size label
            grid = matlab.internal.commonimport.BaseImportTask.createGrid(...
                task.SourceGrid, {'fit'}, {'fit'});
            grid.Layout.Row = 2;
            grid.Layout.Column = 1;
            grid.Padding = [9 0 0 3];

            task.FormatSizeLabel = uilabel(grid);
            task.FormatSizeLabel.Layout.Row = 2;
            task.FormatSizeLabel.Layout.Column = 1;
        end

        function stateChanged(task, ~, ~)
            task.LastCode = task.CurrentSubTask.LastCode;
            notify(task, "StateChanged");
        end

        function propertyChanged(task, ~, ed)
            % Act on any specific properties which may be set (currently
            % only AutoRun is supported)
            if isfield(ed.State, "AutoRun")
                task.AutoRun = ed.State.AutoRun;
            end
        end

        function addEventListeners(task)
            task.StateChangedListener = event.listener(task.CurrentSubTask, ...
                "StateChanged", @(es, ed) task.stateChanged(es, ed));
            task.PropertyChangedListener = event.listener(task.CurrentSubTask, ...
                "PropertyChanged", @(es, ed) task.propertyChanged(es, ed));
        end

        function showErrorAndRevert(task, errorMsg, previousFile)
            % Show the specified error message errorMsg, and revert the Live Task
            % to the previousFile.
            fig = ancestor(task.LayoutManager, "figure");
            if fig.Visible
                uialert(fig, getString(message(errorMsg)), ...
                    getString(message("MATLAB:datatools:importlivetask:ErrorTitle")));
            end

            task.FileEditField.Value = previousFile;
            [path, name, extension] = fileparts(previousFile);
            task.Directory = path;
            task.Filename = string(name) + extension;
            if ~isempty(previousFile) && strlength(previousFile) > 0
                % Reset the subtask too, if there was a file selected previously
                task.fileSelected();
                task.stateChanged();
            else
                % Otherwise clear out the SubTask, and call notifyEmptyCode to clear out
                % the code and task summary.
                task.CurrentSubTask = [];
                task.notifyEmptyCode();
            end

            task.setChangeFilesEnabled(true);
        end
        
        function logDDUXSubtask(task, fileExt)
            evtData = matlab.internal.editor.DDUXEventData();
            evtData.AppID = class(task);
            evtData.ActionID = "rtc_liveapps_importlivetask_fileselected";
            evtData.Metadata1 = class(task.CurrentSubTask);
            evtData.Metadata2 = fileExt;
            notify(task, 'LogDDUX', evtData);
        end
    end

    methods(Static)
        function varName = getVarNameFromFileName(filename)
            arguments
                filename string
            end
            if ~isempty(filename) && strlength(filename) > 0
                [~, varName, ~] = fileparts(filename);
                varName = matlab.lang.makeUniqueStrings(...
                    matlab.lang.makeValidName(varName), ...
                    {}, namelengthmax);
            else
                varName = "";
            end
        end

        function fileSizeStr = getFileSizeStr(fileSize)
            values   = [1, 1024, 1024, 1024, 1024];
            suffixes = ["bytes", "Kb", "Mb", "Gb", "Tb"];

            % Create a dictionary to map suffixes to the translated display
            xlations = ["FileSizeBytes", "FileSizeKB", "FileSizeMB", "FileSizeGB", "FileSizeTB"];
            d = dictionary(suffixes, xlations);

            suff = suffixes(1);

            for i = 1:length(values)
                if abs(fileSize) >= values(i)
                    suff = suffixes(i);
                    fileSize = fileSize ./ values(i);
                else
                    break;
                end
            end

            if strcmp(suff, suffixes(1))
                fmt = "%4.0f";
            elseif strcmp(suff, suffixes(2))
                fmt = "%4.0f";
                fileSize = ceil(fileSize);
            else
                fmt = "%4.2f";
            end

            fileSizeStr = gs(d(suff), strtrim(sprintf(fmt, fileSize)));
        end

        function currentSubTask = createTaskFromName(taskClassName)
            arguments
                taskClassName string
            end

            constructor = str2func(taskClassName);
            currentSubTask = constructor();
            currentSubTask.SupportsVariableRename = true;
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

