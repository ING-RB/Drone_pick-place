function varargout = uiimportFile(filename, NameValueArgs)
    % This is called by uiimport to open the new Import Tool
    %
    % Text and Spreadsheet are handled separately because of the different
    % toolstrips -- they can no longer dock together
    %
    % uiimportFile(filename, "ImportType", "text|spreadsheet") imports the
    % specified file of the specified type.
    %
    % uiimportFile("-pastespecial") imports the clipboard data, by creating a
    % temporary file that contains the data.
    %
    %
    % uiimportFile Parameters:
    %
    % ImportType - "text" or "spreadsheet"
    %
    % DataImportedFcn - function handle which is called when the Import button
    %     is clicked.  The data passed to the function will be a struct
    %     containing the imported data, the user entered variable name, and the
    %     code generated for the import.
    %
    % WindowClosedFcn - function handle which is called when the Import Window
    %     is closed.
    %
    % AppName - Application Name, used for uniqueness
    %
    % SupportedOutputTypes - cell array or string array containing one or more
    %     of the following:
    %     ["table", "numericarray", "cellarray", "stringarray", "columnvector"]
    %
    % SupportedOutputActions - cell array or string array containing one or more
    %     of the following:
    %     ["importdata", "codegen"]
    %
    % Title - title of the Import Tool window.  If set, replaces the default
    %     title.
    %
    % CloseOnImport - Set to true to close the Import Tool when the user hits
    %     the Import button.
    %
    % ImportOptions - Import Options object (created by detectImportOptions)
    %     which should be used to open the Import Tool, instead of the Import
    %     Tool doing its default detection.
    %
    % VariableName - The default Variable Name to use in the Import Tool,
    %     instead of using the one generated from the filename.
    %
    % Position - Position to open the Import Tool at.  Can be specified as [x,y]
    %     coordinates, or [x,y,width,height]
    %
    % InteractionMode - The mode for the Import Tool  It supports "normal" and
    %     "rangeOnly".
    %
    % SelectionChangedFcn - function handle which is called when the selection
    %     changes in the Import Tool.
    %
    % InitialSelection - The initial selection to show in the Import Tool.  It
    %     should be in a format like:  "A1:C5"
    %
    % InitialSheet - The initial sheet to select in the Import Tool, for
    %     spreadsheets with multiple sheets.
    %
    % UseDesktopTheme - True if the Import Tool should use the desktop
    %     theme, and false if it should remain in Light theme regardless of the
    %     desktop setting.
    % 
    % PreserveVariableNames - True if the Import Tool should preserve variable
    %     names from the file.  This is false by default (meaning that the
    %     Import Tool sets the variable names to be valid MATLAB identifiers)

    % Copyright 2019-2024 The MathWorks, Inc.


    arguments
        filename
        NameValueArgs.ImportType {mustBeMember(NameValueArgs.ImportType, ["spreadsheet", "text", "mat"])};
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

    import internal.matlab.importtool.server.ImportUtils;

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
    if ~isfield(args, "ImportType")
        args.ImportType = "";
    end

    % Determine the import file type
    importType = args.ImportType;

    % Handle pastespecial first, since this will write out the file to be
    % imported from the clipboard content
    if filename == "-pastespecial"
        % Create a file with the clipboard content
        [status, filename, importType] = handleClipboardContent();
        if ~isempty(status)
            return;
        end

        if isempty(args.VariableName)
            % By default, use a variable name of "data", rather than the
            % uniquely generated filename for the clipboard content
            args.VariableName = matlab.lang.makeUniqueStrings(...
                "data", evalin("base", "who"), namelengthmax);
        end
    else
        % Make sure the file exists, error if it doesn't.  Use checkFileExists
        % like uiimport, which uses 'which' to handle when only a file name or
        % partial path is passed in, and verifies the file isn't empty.
        [fileExists, fileLength, resolvedFilename] = internal.matlab.importtool.server.ImportUtils.checkFileExists(filename);

        if ~fileExists
            error(message('MATLAB:finfo:FileNotFound', filename))
        elseif fileLength == 0
            error(message("MATLAB:codetools:uiimport:CannotImportFromEmptyFile"));
        else
            filename = resolvedFilename;
        end
    end

    % Initialize the AppName.  This gets used as a channel name, so to make it
    % valid, just make it a valid variable name, and make sure it starts with a
    % slash.
    if isempty(args.AppName)
        args.AppName = "/ImportAPI" + round(abs(randn*100000));
    elseif ~startsWith(args.AppName, "/")
        args.AppName = "/" + args.AppName;
    end
    args.AppName = "/" + matlab.lang.makeValidName(extractAfter(args.AppName, "/"));

    switch(importType)
        case "text"
            % Show the progress window immediately (if this isn't just a call to
            % get the URL)
            showProgressDialog(args);
            textITManager = internal.matlab.importtool.peer.TextImportToolManager.getInstance(args.AppName);
            itm = textITManager;

        case "spreadsheet"
            [~, ~, extension] = fileparts(filename);

            % Make sure that the ImportType matches the actual file extension,
            % because import will fail silently with internal errors if we try
            % to use the spreadsheet functions on non-spreadsheet files.
            if ~any(contains([matlab.io.internal.xlsreadSupportedExtensions '.ods'], extension))
                error(message("MATLAB:codetools:importtool:ImportTool_UnsupportedImportType", extension));
            end

            % Excel formats of xlsb and ods require the use of Excel. Error when
            % trying to import one of these files when not on a pc. This is the
            % same behavior as I/O functions which operate on spreadsheets.
            if ~ispc && ImportUtils.requiresExcelForImport(extension)
                error(message("MATLAB:codetools:importtool:FileTypeUnsupported", extension));
            end

            if ~isempty(args.InitialSheet)
                % Error if the initial sheet is not one of the
                % sheets of the spreadsheet
                sheets = internal.matlab.importtool.server.ImportUtils.sheetnames(filename);
                if ~any(sheets == args.InitialSheet)
                    error(message("MATLAB:codetools:importtool:ImportTool_Invalid_SheetName", args.InitialSheet));
                end
            end

            % Show the progress window immediately (if this isn't just a call to
            % get the URL)
            showProgressDialog(args);
            spreadsheetITManager = internal.matlab.importtool.peer.SpreadsheetImportToolManager.getInstance(args.AppName);
            itm = spreadsheetITManager;

        case "mat"
            if ~argsValidForMATFile(args)
                error(message("MATLAB:codetools:importtool:ImportTool_InvalidMATFileArgs"))
            end
            d = getMATFileProvider(filename, importType, args);
            if nargout == 1
                if ~isempty(getenv("TEST_AUTO_IMPORT"))
                    % Go ahead and import the data without even showing the
                    % dialog when autoImport is set.  This allows testing
                    % of the synchronous import workflow.
                    varargout{1} = d.importWithoutDialog();
                else
                    varargout{1} = d.import();
                end
            else
                d.import();
            end

            return;

        otherwise
            % Show the progress window immediately (if this isn't just a call to
            % get the URL)
            showProgressDialog(args);
            textITManager = internal.matlab.importtool.peer.TextImportToolManager.getInstance(args.AppName);
            itm = textITManager;
    end

    % Setup the title and import mode based on arguments
    if isempty(args.Title)
        itm.Title = strings(0);
    else
        itm.Title = args.Title;
    end
    args.Debug = internal.matlab.importtool.peer.ImportToolManager.setDebug;

    if args.InteractionMode == "rangeOnly"
        itm.ImportMode = "rangeonly";
    elseif args.InteractionMode == "interactiveCodegen"
        itm.ImportMode = "interactiveCodegen";
    else
        if ~contains(args.SupportedOutputActions, "codegen")
            itm.ImportMode = "nocodegen";
        elseif ~contains(args.SupportedOutputActions, "importdata")
            itm.ImportMode = "codegen";
        end
    end
    itm.UseDesktopTheme = args.UseDesktopTheme;

    % This is synchronous import if there is an output argument
    args.IsSynchronous = (nargout == 1);
    url = itm.importAndOpenBrowser(filename, args);

    if nargout == 1

        % If the GetImportURL flag is set, just return it without waiting for
        % the import (since the window isn't actually opened)
        if ~isempty(args.GetImportURL) && args.GetImportURL
            varargout{1} = url;
            return;
        end

        [~, channel] = itm.getFilenameAndChannel(filename);

        % Handle synchronous import, similarly to how it is done for the Import
        % Wizard in uiimport (using drawnow and pause).  We need to create an
        % internal workspace to use, to know when the import is complete.
        workspaceSet = false;
        ws = internal.matlab.importtool.peer.ImportWorkspace;
        data = [];
        varargout{1} = [];

        idx = 1;
        autoImport = ~isempty(getenv("TEST_AUTO_IMPORT"));
        while itm.browserAlreadyOpen && isempty(data)
            if ~workspaceSet
                m = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance(args.AppName).getManagerInstances();
                if isKey(m, channel)
                    mgr = m(channel);
                    mgr.Documents.ViewModel.Workspace = ws;
                    workspaceSet = true;
                end
            end

            drawnow;
            pause(0.1);

            % Go ahead and import the data after some delay when autoImport
            % is set.  This allows testing of the synchronous import
            % workflow.
            if autoImport
                idx = idx + 1;
                if idx > 100
                    [~,b] = fileparts(filename);
                    mgr.Documents.ViewModel.importData(matlab.lang.makeValidName(b));
                end
            end

            d = ws.getData;
            f = fieldnames(d);
            if ~isempty(f)
                % Pull the data from the workspace, and assign it to varargout
                data = d.(f{1});
                varargout{1} = data;
                itm.browserWindowClosed();
            end
        end
    end
end

function [status, filename, importType] = handleClipboardContent()

    % Get the clipboard content.  If it is empty, show an error dialog.
    clipContent = clipboard("paste");
    if isempty(clipContent) || isempty(strtrim(clipContent))
        errMsg = getString(message(...
            "MATLAB:codetools:uiimport:CannotImportFromEmptyFile"));
        errordlg(errMsg, getString(message(...
            "MATLAB:codetools:importtool:ProgressMessageTitle")));
        status = errMsg;
        return;
    end

    % Create a temporary file with the clipboard content
    tmpName = tempname;
    mkdir(tmpName);
    tmpName = fullfile(tmpName, "clipboardData");
    fileID = fopen(tmpName, 'w');
    fprintf(fileID, clipContent);
    fclose(fileID);

    % Use this filename, and import as text
    filename = tmpName;
    importType = 'text';
    status = [];
end

function showProgressDialog(args)
    import internal.matlab.importtool.server.ImportUtils;

    if (isempty(args.GetImportURL) || ~args.GetImportURL) && args.ShowMsgOnOpen
        if args.ImportType == "spreadsheet"
            ImportUtils.showImportProgressWindow(...
                [], getString(message("MATLAB:codetools:importtool:ProgressMessageSpreadsheetFile")));
        else
            ImportUtils.showImportProgressWindow(...
                [], getString(message("MATLAB:codetools:importtool:ProgressMessageTextFile")));
        end
    end
end

function valid = argsValidForMATFile(args)
    valid = true;
    if ~isempty(args.SupportedOutputTypes) || ...
            ~isempty(args.SupportedOutputActions) || ...
            args.CloseOnImport || ...
            ~isempty(args.VariableName) || ...
            ~isempty(args.InteractionMode) || ...
            ~isempty(args.SelectionChangedFcn) || ...
            ~isempty(args.InitialSelection) || ...
            ~isempty(args.InitialSheet) || ...
            ~args.ShowMsgOnOpen
        valid = false;
    end
end

function d = getMATFileProvider(filename, importType, args)
    importProvider = matlab.internal.importdata.ImportProviderFactory.getProvider(filename, importType);
    d = matlab.internal.importdata.DataImporter(importProvider);
    d.SupportsDontShowPref = false;
    if ~isempty(args.Title)
        d.Title = args.Title;
    end
    if ~isempty(args.Position)
        d.Position = args.Position;
    end
    if ~isempty(args.WindowClosedFcn)
        d.WindowClosedFcn = args.WindowClosedFcn;
    end
    if ~isempty(args.DataImportedFcn)
        d.DataImportedFcn = args.DataImportedFcn;
    end

end

function mustBePosition(pos)
    sz = size(pos);
    validSize = isequal(sz, [1,2]) || isequal(sz, [1,4]);
    if ~validSize
        error(message("MATLAB:codetools:importtool:ImportTool_Position_Numeric"));
    end
end
