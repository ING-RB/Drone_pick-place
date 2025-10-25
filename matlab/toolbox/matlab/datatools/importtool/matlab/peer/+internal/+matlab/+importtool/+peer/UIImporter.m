% This class is unsupported and might change or be removed without notice
% in a future version.

% This class provides an alternative to using the uiimportFile API to open the
% Import Tool.  The API was designed to work similar to functions like
% uigetfile, in which the API returns a value (or has callbacks), but does not
% return access to the window object doing the action.

% However, due to limitations around modality, there remain cases when clients
% need access to the Import Tool object itself.  This class provides that
% access.

% Copyright 2020-2024 The MathWorks, Inc.

classdef UIImporter < handle

    properties
        AppName string
    end

    properties(Hidden = true)
        ImportToolManager
        Manager
        ManagerKey string
        Title string
        ImportURL string
    end

    methods
        function this = UIImporter(filename, NameValueArgs)
            % Constructor, creates a UIImporter for the given filename and
            % arguments.  The arguments match those in the uiimportFile
            % function.

            arguments
                filename
                NameValueArgs.ImportType {mustBeMember(NameValueArgs.ImportType, ["spreadsheet", "text"])};
                NameValueArgs.AppName {mustBeA(NameValueArgs.AppName, ["string", "char"])} = '';
                NameValueArgs.DataImportedFcn function_handle = function_handle.empty
                NameValueArgs.WindowClosedFcn function_handle = function_handle.empty
                NameValueArgs.SelectionChangedFcn function_handle = function_handle.empty
                NameValueArgs.Title {mustBeText} = strings(0);
                NameValueArgs.ImportOptions {mustBeA(NameValueArgs.ImportOptions, ["matlab.io.ImportOptions", "double"])} = [];
                NameValueArgs.SupportedOutputTypes {mustBeMember(NameValueArgs.SupportedOutputTypes, ["table", "timetable", "numericarray", "cellarray", "stringarray", "columnvector"])};
                NameValueArgs.SupportedOutputActions {mustBeMember(NameValueArgs.SupportedOutputActions, ["importdata", "codegen"])};
                NameValueArgs.CloseOnImport logical = false;
                NameValueArgs.Position double {mustBePositive, mustBePosition(NameValueArgs.Position)};
                NameValueArgs.VariableName {mustBeText} = strings(0);
                NameValueArgs.InteractionMode {mustBeMember(NameValueArgs.InteractionMode, ["normal", "rangeOnly", "interactiveCodegen"])} = strings(0);
                NameValueArgs.InitialSelection {mustBeText} = strings(0);
                NameValueArgs.InitialSheet {mustBeText} = strings(0);
                NameValueArgs.ShowMsgOnOpen logical = true;
                NameValueArgs.InitialOutputType {mustBeMember(NameValueArgs.InitialOutputType, ["table", "timetable", "numericarray", "cellarray", "stringarray", "columnvector"])};
                NameValueArgs.UseDesktopTheme logical = false;
                NameValueArgs.PreserveVariableNames logical = false;
                NameValueArgs.GetImportURL logical = false;
            end

            args = NameValueArgs;
            if ~isfield(args, "SupportedOutputTypes")
                args.SupportedOutputTypes = strings(0);
            end
            if ~isfield(args, "SupportedOutputActions")
                args.SupportedOutputActions = strings(0);
            end
            if ~isfield(args, "Position")
                args.Position = [];
            end

            % Check if the file exists (and resolve partial paths).  Error if
            % the file can't be found.
            [fileExists, fileLength, filename] = internal.matlab.importtool.server.ImportUtils.checkFileExists(filename);
            if ~fileExists
                error(message('MATLAB:finfo:FileNotFound', filename))
            elseif fileLength == 0
                error(message("MATLAB:codetools:uiimport:CannotImportFromEmptyFile"));
            end

            % Initialize the AppName.  This gets used as a channel name, so to
            % make it valid, just make it a valid variable name, and make sure
            % it starts with a slash.
            if ~startsWith(args.AppName, "/")
                this.AppName = "/" + args.AppName;
            else
                this.AppName = args.AppName;
            end
            this.AppName = "/" + matlab.lang.makeValidName(extractAfter(this.AppName, "/"));
            args.AppName = this.AppName;
            this.ManagerKey = this.AppName + string(internal.matlab.importtool.peer.DesktopImportTool.getNextChannel(filename, args.ImportType));

            switch(args.ImportType)
                case "text"
                    this.ImportToolManager = internal.matlab.importtool.peer.TextImportToolManager.getInstance(this.AppName);

                case "spreadsheet"
                    this.ImportToolManager = internal.matlab.importtool.peer.SpreadsheetImportToolManager.getInstance(this.AppName);

                    if ~isempty(args.InitialSelection)
                        % Resolve the initial selection.  Set it to empty if it
                        % isn't a valid excel selection.
                        if ~internal.matlab.importtool.server.ImportUtils.isValidExcelRange(args.InitialSelection)
                            args.InitialSelection = "";
                        end
                    end

                    if ~isempty(args.InitialSheet)
                        % Error if the initial sheet is not one of the
                        % sheets of the spreadsheet
                        sheets = internal.matlab.importtool.server.ImportUtils.sheetnames(filename);
                        if ~any(sheets == args.InitialSheet)
                            error(message("MATLAB:codetools:importtool:ImportTool_Invalid_SheetName", args.InitialSheet));
                        end
                    end
            end

            % Setup the ImportMode and title if they are set
            if isfield(args, "ImportMode")
                this.ImportToolManager.ImportMode = args.ImportMode;
            end
            if isfield(args, "Title")
                this.Title = args.Title;
                this.ImportToolManager.Title = args.Title;
            end

            if strcmpi(args.InteractionMode, "rangeOnly")
                this.ImportToolManager.ImportMode = "rangeonly";
            elseif ~contains(args.SupportedOutputActions, "codegen")
                this.ImportToolManager.ImportMode = "nocodegen";
            end
            this.ImportToolManager.UseDesktopTheme = args.UseDesktopTheme;

            % Import and open the browser window
            this.ImportURL = this.ImportToolManager.importAndOpenBrowser(filename, args);
        end

        function delete(this)
            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            internal.matlab.importtool.server.ImportUtils.closeImportProgressWindow;
            if ~isempty(this.ImportToolManager) && isvalid(this.ImportToolManager)
                this.ImportToolManager.browserWindowClosed();
            end
        end

        function excelSelection = getSelection(this)
            % Returns the selection in the current sheet, of the currently
            % displayed file.  It will be in excel format, like "A2:D10".

            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            this.initManager;
            focusedSheet = this.Manager.FocusedDocument;
            excelSelection = string(focusedSheet.ViewModel.getTableModelProperty("excelSelection"));
        end

        function excelSelection = getInitialSelection(this)
            % Returns the initial selection in the current sheet, of the
            % currently displayed file.  It will be in excel format, like
            % "A2:D10".

            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            this.initManager;
            focusedSheet = this.Manager.FocusedDocument;
            sel = focusedSheet.ViewModel.getTableModelProperty("initialSelection");
            excelSelection = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                sel(1), sel(3), sel(2), sel(4));
        end

        function newExcelSelection = setSelection(this, excelSelection)
            % Set the selection of the current sheet, of the currently displayed
            % file.  The selection must be in excel rows/columns format, like
            % "A2:D10".  The new selection is returned, because out of range
            % selections will get resolved to something valid.

            arguments
                this internal.matlab.importtool.peer.UIImporter
                excelSelection string
            end

            this.initManager;
            [rows, cols] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelSelection);
            focusedSheet = this.Manager.FocusedDocument;

            % Assure that the selection is within range
            dims = focusedSheet.ViewModel.DataModel.getSheetDimensions();
            rows = min(rows, dims(2));
            cols = min(cols, dims(4));

            % Get the new excel selection from the updated rows/cols
            newExcelSelection = internal.matlab.importtool.server.ImportUtils.getExcelRangeArray(rows, cols);
            focusedSheet.ViewModel.forceUpdateSelection(newExcelSelection);
            focusedSheet.ViewModel.setSelection(rows, cols, 'server');
            if ~strcmp(excelSelection, newExcelSelection)
                % If the selection resolved to something different, notify of
                % the change
                eventData = internal.matlab.variableeditor.SelectionEventData;
                eventData.Selection = focusedSheet.ViewModel.getSelection;
                focusedSheet.ViewModel.notify("SelectionChanged", eventData);
            end
            changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            changeEventData.Column = 1:dims(end);
            focusedSheet.ViewModel.notify('TableMetaDataChanged', changeEventData);
        end

        function t = getTitle(this)
            % Return the title of the window displaying the Import Tool

            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            t = this.Title;
        end

        function setTitle(this, title)
            % Set the title of the window displaying the Import Tool

            arguments
                this internal.matlab.importtool.peer.UIImporter
                title string
            end

            window = [];
            wList = matlab.internal.webwindowmanager.instance().windowList;
            for idx = 1:length(wList)
                window = wList(idx);
                if window.Tag == this.AppName
                    break;
                end
            end

            this.Title = title;
            if ~isempty(window)
                window.Title = char(title);
            end
        end

        function sheetName = getCurrentSheetName(this)
            % Return the currently selected sheet name.  Returns strings(0) for
            % text files.

            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            this.initManager;
            state = this.Manager.FocusedDocument.ViewModel.DataModel.getState();
            if isfield(state, "SheetName")
                sheetName = string(state.SheetName);
            else
                sheetName = strings(0);
            end
        end

        function setCurrentSheetName(this, sheetName)
            % Set the currently selected sheet name.  This is a no-op for text
            % files.

            arguments
                this internal.matlab.importtool.peer.UIImporter
                sheetName string
            end

            this.initManager;

            state = this.Manager.FocusedDocument.ViewModel.DataModel.getState();
            if isfield(state, "SheetName")
                evt.data.sheetName = sheetName;
                this.Manager.openImportSheet(evt);
                docId = internal.matlab.importtool.peer.RemoteImportToolManager.getValidChannelId( ...
                    this.Manager.DataSource.FileName, true, sheetName);
                index = this.Manager.docIdIndex(docId);
                this.Manager.FocusedDocument = this.Manager.Documents(index);
            end
        end
    end

    methods(Access = private)
        function initManager(this)
            % Initialize the manager for the given AppName

            arguments
                this internal.matlab.importtool.peer.UIImporter
            end

            f = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance(this.AppName);
            mgrInst = f.getManagerInstances;

            if isKey(mgrInst, this.ManagerKey)
                this.Manager = mgrInst(this.ManagerKey);
            else
                idx = 6;
                while ~isKey(mgrInst, this.ManagerKey) && idx > 0
                    % wait and try to get it again.  Check a few times --
                    % we may need multiple yields for the Import Tool calls
                    % to complete
                    matlab.internal.yield;
                    pause(0.5);
                    idx = idx - 1;
                end

                % Don't check if it is a key first so that the error will
                % be thrown
                this.Manager = mgrInst(this.ManagerKey);
            end
        end
    end
end

function mustBePosition(pos)
    sz = size(pos);
    validSize = isequal(sz, [1,2]) || isequal(sz, [1,4]);
    if ~validSize
        error(message("MATLAB:codetools:importtool:ImportTool_Position_Numeric"));
    end
end

