function varargout = uiimportNoJVM(varargin)
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % UIIMPORTNOJVM Opens a dialog to interactively load data from a file or the
    % clipboard. MATLAB displays a preview of the data in the file when
    % possible.
    %
    % UIIMPORTNOJVM(FILENAME) opens the file specified in FILENAME using either
    % the Import Tool or the Import Data window depending on the file type. For
    % spreadsheet and text files uiimport opens the file using the Import Tool.
    % For all other file types (image, audio, MAT file, etc..), the uiimport
    % function initiates the Import Data window.
    %
    % UIIMPORTNOJVM('-file') works as above but the file selection dialog is
    % presented first.
    %
    % UIIMPORTNOJVM('-pastespecial') opens the clipboard content in the Import
    % Tool
    %
    % S = UIIMPORTNOJVM(...) opens the file as above, with resulting variables
    % stored as fields in the struct S.

    % Copyright 2020-2024 The MathWorks, Inc.

    % uiimport requires interactivity
    import matlab.internal.capability.Capability;
    Capability.require(Capability.InteractiveCommandLine);

    % Check if we are in synchronous mode, by seeing if there is nargout
    isSynchronous = (nargout == 1);
    useFileDialog = false;
    useClipboard = false;

    if nargin == 0
        % If no arguments are provided, show a dialog which lets the user choose
        % between file and clipboard import (or cancel)
        [useFileDialog, useClipboard] = getUIImportInputSource();
        if ~useFileDialog && ~useClipboard
            % The user hit cancel
            if isSynchronous
                varargout = {[]};
            end
            return;
        end
    else
        % The user provided an argument, it may "-file", "-pastespecial", or a
        % filename
        if strcmp(varargin{1}, "-file")
            useFileDialog = true;
        elseif strcmp(varargin{1}, "-pastespecial")
            if Capability.isSupported(Capability.LocalClient)
                useClipboard = true;
            else
                % Importing from clipboard is currently only supported on the
                % local client
                productName = connector.internal.getProductNameByClientType;
                error(message("MATLAB:codetools:uiimport:MatlabOnlineSupport", productName));
            end
        end
    end

    if useClipboard
        % Clipboard paste is currently handled by the text import tool, show it
        % and return.
        out = handlePastedTextImport(isSynchronous);
        if isSynchronous
            varargout{1} = out;
        end
        return
    end

    % Get the selected file, return if it is empty
    selectedFile = getSelectedFile(useFileDialog, varargin{:});
    if isempty(selectedFile)
        if isSynchronous
            varargout = {[]};
        end
        return;
    end

    % Try to access the selected file
    [fileExists, fileLength, resolvedFile] = internal.matlab.importtool.server.ImportUtils.checkFileExists(selectedFile);

    % Detect and report empty input files - display an error dialog
    if ~fileExists 
        error(message('MATLAB:finfo:FileNotFound', selectedFile));
    elseif fileLength == 0
        errordlg(getString(message("MATLAB:codetools:uiimport:CannotImportFromEmptyFile")), ...
            getString(message("MATLAB:codetools:uiimport:ErrorTitle")));
        return;
    else
        selectedFile = resolvedFile;
    end

    % Get the file type
    selectedFile = char(selectedFile);
    type = finfo(selectedFile);

    if internal.matlab.importtool.ImportableFileIdentifier.useSpreadsheetImportTool(false, type)
        % Open the spreadsheet import tool
        out = handleSpreadsheetImport(selectedFile, isSynchronous);
        if isSynchronous
            varargout{1} = out;
        end
    else
        % Is there an import provider for this file type?  If so, import using
        % it.  This handles cases like audio, video, image, MAT, STL and parquet
        % file import.
        importDataUI = isImportAlreadyOpen(selectedFile);
        if ~isempty(importDataUI) && isvalid(importDataUI)
            % If the window is already open for media import for this file, then
            % just reset the window state in case it is minimized, and bring it
            % to the front.  (It's a noop if the window is already visible)
            importDataUI.WindowState = "normal";
            figure(importDataUI)
        else
            importProvider = matlab.internal.importdata.ImportProviderFactory.getProvider(selectedFile, type);
            if ~isempty(importProvider)
                % A provider was found, import the data using it
                out = handleDataImport(importProvider, isSynchronous);
            else
                [~, ~, ext] = fileparts(fullfile(selectedFile));
                ext = extractAfter(ext, ".");
                importFunctionMapping = matlab.internal.commonimport.DataImporters.getImportFileFunctions();
                if isKey(importFunctionMapping, ext)
                    importArgMapping = matlab.internal.commonimport.DataImporters.getImportFileFunctionOutputArgs();
                    if isKey(importArgMapping, ext)
                        outputArgCount = importArgMapping(ext);
                    else
                        outputArgCount = 1;
                    end
                    out = handleImportFileFcn(selectedFile, importFunctionMapping(ext), outputArgCount, isSynchronous);
                else
                    % There is no provider, and it this isn't a spreadsheet file, so
                    % import using the text import tool.  This is the catch-all when we
                    % don't have another method to import.
                    out = handleTextImport(selectedFile, isSynchronous);
                end
            end

            if isSynchronous
                varargout{1} = out;
            end
        end
    end
end

function selectedFile = getSelectedFile(useFileDialog, varargin)
    % If the user hasn't specified a file, open the file selection dialog,
    % otherwise just use the file from the user.

    arguments
        useFileDialog logical
    end
    arguments (Repeating)
        varargin
    end

    if useFileDialog
        % Open the file selection dialog, showing the various supported file
        % types.  
        filter = matlab.internal.commonimport.DataImporters.getUIGetFileFilter;
        fileChooserTitle = message("MATLAB:codetools:uiimport:FileChooserTitle").getString();
        [fileName, path] = uigetfile(filter, fileChooserTitle);

        if fileName == 0
            % The user hit cancel on the file selection dialog
            selectedFile = [];
        else
            selectedFile = [path fileName];
        end
    else
        selectedFile = varargin{1};
    end
end

function out = handleSpreadsheetImport(selectedFile, isSynchronous)
    % Handle spreadsheet import

    arguments
        selectedFile char
        isSynchronous logical
    end

    import matlab.internal.capability.Capability;

    % The Import Tool needs to open undocked for the desktop, or if the 
    % import is synchronous
    out = [];
    if Capability.isSupported(Capability.LocalClient) || isSynchronous
        if isSynchronous
            % Use the Import Tool API to open the spreadsheet import tool
            imOutput = internal.matlab.importtool.peer.uiimportFile(selectedFile, ...
                "ImportType", "spreadsheet", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
            out = getTabularSynchronousOutput(imOutput);
        else
            internal.matlab.importtool.peer.uiimportFile(selectedFile, ...
                "ImportType", "spreadsheet", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
        end
    else
        % For MOL, start import using the desktop import tool
        importTool = internal.matlab.importtool.peer.DesktopImportTool.getInstance;
        importTool.import(selectedFile, "spreadsheet");
    end
end

function out = handleTextImport(selectedFile, isSynchronous)
    % Handle text import

    arguments
        selectedFile char
        isSynchronous logical
    end

    import matlab.internal.capability.Capability;

    % The Import Tool needs to open undocked for the desktop, or if the 
    % import is synchronous
    out = [];
    if Capability.isSupported(Capability.LocalClient) || isSynchronous
        if isSynchronous
            % Use the Import Tool API to open the text import tool
            imOutput = internal.matlab.importtool.peer.uiimportFile(selectedFile, ...
                "ImportType", "text", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
            out = getTabularSynchronousOutput(imOutput);
        else
            internal.matlab.importtool.peer.uiimportFile(selectedFile, ...
                "ImportType", "text", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
        end
    else
        % For MOL, start import using the desktop import tool
        importTool = internal.matlab.importtool.peer.DesktopImportTool.getInstance;
        importTool.import(selectedFile, "text");
    end
end

function out = handleImportFileFcn(selectedFile, fcnName, outputArgCount, isSynchronous)
    % Handle import of files which just supply an import function

    arguments
        selectedFile string
        fcnName string
        outputArgCount (1,1) double = 1;
        isSynchronous (1,1) logical = false;
    end

    import matlab.internal.capability.Capability;

    out = [];
    importCode = fcnName + "(""" + selectedFile + """);";
    if outputArgCount == 1 && ~isSynchronous
        [~, varName] = fileparts(selectedFile);
        varName = matlab.lang.makeUniqueStrings(...
            matlab.lang.makeValidName(varName), ...
            evalin("debug", "who"), namelengthmax);

        importCode = varName + " = " + importCode;
    end

    if isSynchronous
        % Eval the code locally, and return the value which was created
        eval("X = " + importCode);
        out = X;
    elseif ~(matlab.internal.feature('webui') == 0 && Capability.isSupported(Capability.LocalClient))
        % Publish the code to the CodePublishingService
        c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
        c.publishCode("ImportData", importCode);
    else
        % Eval the code in the base workspace (for testing in Java Desktop)
        evalin("debug", importCode);
    end
end

function out = handlePastedTextImport(isSynchronous)
    % Handle pasted text import -- this is shown in the Import Tool

    arguments
        isSynchronous logical
    end

    out = [];
    if isSynchronous
        % Use the Import Tool API to open the import tool
        imOutput = internal.matlab.importtool.peer.uiimportFile(...
            "-pastespecial", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
        out = getTabularSynchronousOutput(imOutput);
    else
        % For MOL, start import using the desktop import tool
        internal.matlab.importtool.peer.uiimportFile(...
            "-pastespecial", "AppName", "uiimportDesktop", "UseDesktopTheme", true);
    end
end

function out = handleDataImport(importProvider, isSynchronous)
    % Handle import of media files (audio/video/image), MAT files, and files
    % that don't show a preview (like STL or parquet files)
    arguments
        importProvider
        isSynchronous logical
    end

    d = matlab.internal.importdata.DataImporter(importProvider);
    d.UseDesktopTheme = true;
    out = [];

    if importProvider.getShowDialogPref
        % If the preference setting for this file type it to show the
        % dialog, call the import method
        if isSynchronous
            out = d.import();
        else
            d.import();
        end
    else
        % The preference setting for this file type is to not show the
        % dialog, so call the importWithoutDialog method instead
        if isSynchronous
            out = d.importWithoutDialog();
        else
            d.importWithoutDialog();
        end
    end
end

function st = getTabularSynchronousOutput(imOutput)
    % The struct from tabular data import includes many fields in addition to
    % the actual imported data.  Strip this down and return a struct with the
    % field names as the variable names, and the values as the imported data
    % values, to match legacy behavior.

    arguments
        imOutput struct;
    end

    st = struct;
    if isfield(imOutput, "varNames")
        for idx = 1:length(imOutput.varNames)
            st.(imOutput.varNames(idx)) = imOutput.vars{idx};
        end
    end
end

function importFigure = isImportAlreadyOpen(filename)
    % Check if the Import Data is already open for this filename or not.
    % Returns the uifigure if it is already open, and empty [] otherwise.
    arguments
        filename string;
    end

    importFigure = [];

    % Find any figures which are open, that have the "importdata" Tag
    f = findall(groot, "Type", "figure", "Tag", "importdata");
    if ~isempty(f)
        for idx = 1:length(f)
            fg = f(idx);
            ud = fg.UserData;
            if ~isempty(ud) && (ischar(ud) || isstring(ud)) && strcmp(ud, filename)
                % It's a match if the UserData of the figure matches the
                % filename exactly
                importFigure = fg;
                break;
            end
        end
    end
end

