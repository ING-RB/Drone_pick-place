% This class is unsupported and might change or be removed without notice
% in a future version.

% Manages opening/closing the JS Import Tool in a browser window, from Matlab

% Copyright 2019-2024 The MathWorks, Inc.

classdef ImportToolManager < handle
    properties
        % Browser window
        Browser = [];

        % URL
        ImportIndex = "/toolbox/matlab/datatools/importtool/js/peer/index.html";
        DebugImportIndex = "/toolbox/matlab/datatools/importtool/js/peer/index-debug.html";

        % Import Type (for example, spreadsheet or text
        ImportType string = strings(0);

        % Whether the browser window is open or not
        IsOpen logical = false;

        % Currently opened channels for this Manager
        OpenedChannels string = strings(0);
        OpenedFiles string = strings(0);

        FileMap;

        ProgressMessageText = '';

        InitialWidth double = 825;
        InitialHeight double = 500;
        InitialX double = 100;
        InitialY double = 400;

        ProgressTimer = [];

        DeletionListeners = {};
        BrowserCloseInProgress = false;
        ImportInProgress = false;

        % The Window title.  If not set, the default title will be shown, which
        % is taken from the TitleTag
        Title = strings(0);
        TitleTag string = strings(0);

        WindowClosedFcn = [];
        ImportMode = strings(0);

        AppName = "";
        Snc = strings(0);

        SelectionListeners;
        DocumentOpenedListeners;
        SelectionChangedFcn = [];
        InitialArgs = struct();
        ArgsMap;

        CloseListener = [];

        InitialSelectionDone (1,1) logical = false;

        % Whether the UI participates in desktop theming or not
        UseDesktopTheme (1,1) logical = false;
    end

    properties (Hidden)
        WindowListener
    end

    properties (Constant)
        DebugChannel string = "/DebugImport";
    end

    methods
        function this = ImportToolManager
            % Create an instance of the ImportToolManager.  Make sure the
            % server-side Import Tool is started.
            internal.matlab.importtool.peer.DesktopImportTool.startup;

            this.FileMap = containers.Map;
            this.ArgsMap = containers.Map;
            this.SelectionListeners = containers.Map;
            this.DocumentOpenedListeners = containers.Map;
        end

        function url = importAndOpenBrowser(this, filename, dataSource)
            % Called to import a file and show it in a CEF window
            url = [];
            this.InitialArgs = dataSource;

            % If there is a file open in the Import Tool already, we don't need
            % to create the browser.  We can just show it, and import the new
            % file.  Otherwise, create the browser window.
            if ~this.browserAlreadyOpen()
                internal.matlab.datatoolsservices.logDebug("it", "browserNotOpen: " + filename);
                if (~isfield(dataSource, "GetImportURL") || isempty(dataSource.GetImportURL) || ~dataSource.GetImportURL) && ...
                        (~isfield(dataSource, "ShowMsgOnOpen") || isempty(dataSource.ShowMsgOnOpen) || dataSource.ShowMsgOnOpen)
                    % Immediately show the progress window if this isn't just a call
                    % to get the url
                    internal.matlab.importtool.server.ImportUtils.showImportProgressWindow(...
                        [], this.ProgressMessageText);
                end

                % Make sure browser window closed has executed before we try to
                % initiate another import, when we're opening a new window
                this.browserWindowClosed(false);

                if internal.matlab.importtool.peer.ImportToolManager.setDebug
                    url = this.getImportToolDebugAddressForFile(filename, dataSource.AppName);
                else
                    url = this.getImportToolAddressForFile(filename, dataSource.AppName);
                end

                if isfield(dataSource, "GetImportURL") && ~isempty(dataSource.GetImportURL) && dataSource.GetImportURL
                    return;
                end

                % Center the browser window on the screen unless the position
                % has been specified in the data source
                initialWidth = this.InitialWidth;
                initialHeight = this.InitialHeight;
                if isfield(dataSource, "Position") && ...
                        ~isempty(dataSource.Position) && ...
                        numel(dataSource.Position) >= 2
                    xPos = dataSource.Position(1);
                    yPos = dataSource.Position(2);

                    if numel(dataSource.Position) == 4
                        initialWidth = dataSource.Position(3);
                        initialHeight = dataSource.Position(4);
                    end
                else
                    screensize = get(0, 'ScreenSize');
                    swidth = screensize(3);
                    sheight = screensize(4);
                    xPos  = (swidth-this.InitialWidth)/2;
                    yPos = (sheight-this.InitialHeight)/2;
                end

                this.Browser = matlab.ui.container.internal.AppContainer;
                this.Browser.AppPage = url;

                this.WindowListener = event.listener(this.Browser, "WindowCreated", ...
                    @(varargin) this.setWindowTag(dataSource.AppName));
                
                this.Browser.Visible = true;
                this.Browser.WindowBounds = [xPos, yPos, ...
                    initialWidth, initialHeight];

                t = timer(...
                    "StartDelay", 1, ...
                    "ExecutionMode", "singleShot", ...
                    "TimerFcn", @(tm, ~) setIcon(this, tm));
                start(t);

                execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
                if execImmediately
                    this.Browser.bringToFront();
                else
                    fcn =  @(es,ed) this.Browser.bringToFront();
                    builtin('_dtcallback', fcn, true);
                end

                if isfield(dataSource, "WindowClosedFcn")
                    this.WindowClosedFcn = dataSource.WindowClosedFcn;
                end
                this.CloseListener = addlistener(this.Browser, "StateChanged", ...
                    @(~, ~) this.browserWindowClosed());
            else
                internal.matlab.datatoolsservices.logDebug("it", "browserOpen: " + filename);

                % The browser has already been created.  Just show it and bring
                % it to the front.
                this.Browser.bringToFront();

                % No need to import if the file is already open
                if isempty(this.OpenedFiles) || ~any(contains(this.OpenedFiles, filename))
                    % Immediately show the progress window
                    internal.matlab.importtool.server.ImportUtils.showImportProgressWindow(...
                        [], this.ProgressMessageText);

                    internal.matlab.datatoolsservices.logDebug("it", "calling importFile: " + filename);
                    this.importFile(filename, struct);
                end
            end

            this.IsOpen = true;
        end

        function b = browserAlreadyOpen(this)
            try
                b = ~isempty(this.Browser) && isvalid(this.Browser) && ...
                    ~(this.Browser.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED);
            catch
                b = false;
            end
        end

        function url = getImportToolAddressForFile(this, varargin)
            % Returns the Import Tool address using the specified file
            url = connector.getUrl(this.ImportIndex);
            url = this.getUpdatedURL(url, varargin{:});
        end

        function url = getImportToolDebugAddressForFile(this, varargin)
            % Returns the Import Tool debug address using the specified file
            url = connector.getUrl(this.DebugImportIndex);
            url = this.getUpdatedURL(url, varargin{:});
        end

        function url = getUpdatedURL(this, url, varargin)
            if ~contains(url, "snc")
                url = url + "?snc=" + this.Snc;
            end

            if nargin > 2 && ~isempty(varargin{1})
                fileID = "fileID" + round(abs(randn*100000));
                this.FileMap(fileID) = varargin{1};
                url = url + "&filename=" + fileID;

                if ~isempty(this.InitialArgs)
                    this.ArgsMap(fileID) = this.InitialArgs;
                end
            end

            url = url + "&type=" + this.ImportType;

            if nargin > 3 && ~isempty(varargin{2})
                url = url + "&appName=" + varargin{2};
            end

            if ~isempty(this.ImportMode)
                url = url + "&importScope=" + this.ImportMode;
            end

            if this.UseDesktopTheme
                % Add in this flag since its needed for the initial container 
                % creation for the Import UI
                url = url + "&useDesktopTheme=" + this.UseDesktopTheme;
            end

            % Add in the title, since it can be supplied from the client
            if isempty(this.Title)
                % Title will be Import Tool
                s = getString(message(this.TitleTag));
            else
                % Use the title provided by the client
                s = this.Title;
            end
            url = url + "&title=" + urlencode(s);

            if internal.matlab.importtool.peer.ImportToolManager.setDebug
                disp("ImportToolManager - Import Tool URL:  " + url)
            end
        end

        function status = initializeAndImportFile(this, fileID, dataSource)
            import internal.matlab.importtool.peer.DesktopImportTool;
            import internal.matlab.importtool.peer.ImportToolManager;
            import internal.matlab.importtool.peer.PeerImportToolFactory;
            import internal.matlab.importtool.peer.shouldShowJSImportTool;

            if internal.matlab.importtool.peer.ImportToolManager.setDebug
                disp("ImportToolManager - initializeAndImportFile, fileID = " + fileID + ", AppName = " + dataSource.AppName)
            end

            initialArgs = [];
            if isKey(this.FileMap, fileID)
                filename = this.FileMap(fileID);
                initialArgs = this.ArgsMap(fileID);
            else
                filename = fileID;
            end

            if nargin < 3
                dataSource = struct;
            elseif ~isempty(initialArgs)
                % Combine any initial args with the passed in arguments.  Any
                % conflicts are taken from the function argument dataSource.
                f = fieldnames(initialArgs);
                for idx = 1:length(f)
                    if ~isfield(dataSource, f{idx})
                        dataSource.(f{idx}) = initialArgs.(f{idx});
                    end
                end
            end

            % set showJSImportTool flag
            currShowJSITFlag = shouldShowJSImportTool;
            shouldShowJSImportTool(true);
            revertJSITFlag = onCleanup(@() shouldShowJSImportTool(currShowJSITFlag));

            % set debug mode
            if isfield(dataSource, 'Debug')
                currDebugFlag = ImportToolManager.setDebug;
                ImportToolManager.setDebug(dataSource.Debug);
                revertDebugFlag = onCleanup(@() ImportToolManager.setDebug(currDebugFlag));
            end

            channel = string(this.AppName) + DesktopImportTool.getNextChannel(filename, this.ImportType);
            mgrs = PeerImportToolFactory.getInstance(this.AppName).getManagerInstances();
            if any(string(keys(mgrs)') == channel)
                mgr = mgrs(channel);
                delete(mgr);
            end

            status = this.importFile(filename, dataSource);
            this.ImportInProgress = false;
        end

        function [filename, channel] = getFilenameAndChannel(this, filename)
            import internal.matlab.importtool.peer.DesktopImportTool;

            filename = char(filename);
            channel = char(string(this.AppName) + DesktopImportTool.getNextChannel(char(filename), ...
                char(this.ImportType)));
        end

        function [status, manager] = importFile(this, filename, dataSource)
            import internal.matlab.importtool.peer.DesktopImportTool;
            import internal.matlab.importtool.peer.PeerImportToolFactory;

            if internal.matlab.importtool.peer.ImportToolManager.setDebug
                disp("ImportToolManager - importFile, filename = " + filename)
            end

            % Need a small pause for the actions to be processed
            pause(0.1);
            drawnow;

            [filename, channel] = this.getFilenameAndChannel(filename);
            mgrs = PeerImportToolFactory.getInstance(this.AppName).getManagerInstances();
            if any(string(keys(mgrs)') == channel)
                mgr = mgrs(channel);
                delete(mgr);
            end

            dataSource.FileName = filename;
            dataSource.ImportType = char(this.ImportType);

            try
                importer = internal.matlab.importtool.server.ImporterFactory.getImporter(dataSource);
                dataSource.Importer = importer;

                % Set the CreateActionsSynchronous flag based on if the import is synchronous, or if
                % the executionTypeIdle is set to true 
                factoryInstance = PeerImportToolFactory.getInstance(this.AppName);
                factoryInstance.CreateActionsSynchronous = ...
                    (isfield(dataSource, "IsSynchronous") && dataSource.IsSynchronous) || ...
                    internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
                manager = factoryInstance.createManagerInstance(...
                    char(channel), dataSource);
                status = [];
            catch ex 
                internal.matlab.importtool.server.ImportUtils.closeImportProgressWindow();
                errordlg(...
                    getString(message("MATLAB:codetools:importtool:ImportError")), ...
                    getString(message("MATLAB:codetools:importtool:ProgressMessageTitle")));
                manager = [];
                internal.matlab.datatoolsservices.logDebug("import", "Error ID opening Import: " + ex.identifier);
                internal.matlab.datatoolsservices.logDebug("import", "Error msg opening Import: " + ex.message);
                status = struct("status", "error", "filename", filename);
            end

            if isempty(manager) || isempty(manager.Documents)
                % No document was created, so there was an error or an empty
                % file.  Just call the deletionCallback to make sure the browser
                % window is cleaned up properly.
                if ~isempty(manager)
                    this.deletionCallback(manager)
                end
                if internal.matlab.importtool.peer.ImportToolManager.setDebug
                    disp("ImportToolManager - importFile, manager error")
                end

                this.browserWindowClosed(true);
                return;
            else
                if internal.matlab.importtool.peer.ImportToolManager.setDebug
                    disp("ImportToolManager - importFile, manager created")
                end
            end

            % Determine the number of documents.  Typically there is just one,
            % but there can be multiple in the case of spreadsheet import, if
            % the specified initial sheet is not the first one
            numDocuments = length(manager.Documents);

            % isInteractiveCodegen = internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(dataSource);

            % If there's a DataImportedFcn specified, set it on the ViewModel
            if isfield(dataSource, "DataImportedFcn") && ~isempty(dataSource.DataImportedFcn)
                for idx = 1:numDocuments
                    manager.Documents(idx).ViewModel.ImportDataCallback = ...
                        dataSource.DataImportedFcn;
                end

                % if isInteractiveCodegen
                %     % Call the Import Callback function when the Import Tool
                %     % opens, so the client has the current code
                %     this.callImportCallback(manager.Documents(1).ViewModel);
                % end
            end

            % If there's a SelectionChangedFcn specified, setup listeners for
            % selection changing
            if isfield(dataSource, "SelectionChangedFcn") && ~isempty(dataSource.SelectionChangedFcn) % ) || ...
                    % (isInteractiveCodegen && isfield(dataSource, "DataImportedFcn") && ~isempty(dataSource.DataImportedFcn))
                this.SelectionChangedFcn = dataSource.SelectionChangedFcn;
                this.InitialSelectionDone = false;

                for idx = 1:numDocuments
                    % Determine a unique identifier for the view.  For
                    % spreadsheets, this will be the sheet name, but for text it
                    % can just be the filename
                    sheetIdentifier = this.getSheetIdentifier(manager, idx);

                    % Add listener on SelectionChanged on the ViewModel.  Get or
                    % create a map to store the listeners for this channel
                    if isKey(this.SelectionListeners, channel)
                        c = this.SelectionListeners(channel);
                    else
                        c = containers.Map;
                    end

                    % Get the ViewModel for this document, and assign a
                    % selection listener
                    vm = manager.Documents(idx).ViewModel;
                    c(sheetIdentifier) = event.listener(...
                        vm, "SelectionChanged", @this.importSelectionChanged);
                    this.SelectionListeners(channel) = c;
                end
            end

            % Add a listener for additional documents opened.  This is
            % needed, for example, for spreadsheets with multiple sheets
            sheetIdentifier = this.getSheetIdentifier(manager, 1);
            this.DocumentOpenedListeners(sheetIdentifier) = event.listener(...
                manager, "DocumentOpened", @this.documentOpened);

            if isfield(dataSource, "CloseOnImport") && dataSource.CloseOnImport
                for idx = 1:numDocuments
                    manager.Documents(idx).ViewModel.CloseOnImportCallback = ...
                        @this.browserWindowClosed;
                end
            end

            this.DeletionListeners{end+1} = event.listener(manager, ...
                'ObjectBeingDestroyed', @this.deletionCallback);

            % Keep track of the channels which were opened.  These are needed
            % for cleanup when the user closes the browser window.
            this.OpenedChannels(end + 1) = manager.Channel;
            this.OpenedFiles(end + 1) = filename;

            this.ProgressTimer = timer(...
                "Period", 0.5, ...
                "ExecutionMode", "fixedRate", ...
                "TimerFcn", @(~, ~) raiseProgressWindow(this));
            start(this.ProgressTimer);
        end

        function browserClosed = browserWindowClosed(this, executeCB)
            arguments
                this
                executeCB (1,1) logical = true
            end
            if this.BrowserCloseInProgress
                return;
            end
            import internal.matlab.importtool.peer.DesktopImportTool;

            browserClosed = false;
            this.BrowserCloseInProgress = true;

            % Called when the browser window is closed by the user. Just hide
            % the browser window, don't destroy it.
            if ~isempty(this.Browser) && isvalid(this.Browser)
                l = lasterror; %#ok<*LERR>
                try
                    if this.Browser.Visible
                        this.Browser.Visible = false;

                        % Only set the browser closed flag if the browser was
                        % visible to begin with.  This is used to control
                        % whether a callback function is called.
                        browserClosed = true;
                    end
                    if ~(this.Browser.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED)
                        delete(this.Browser);
                    end
                catch
                    % Ignore any errors, it may have been closed but is still
                    % considered a valid handle.
                end
                lasterror(l);
            end
            this.IsOpen = false;

            % Delete any of the open channels.  Otherwise, when the browser
            % window reopens, previous import tabs will be shown
            mgrs = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance(this.AppName).getManagerInstances;

            for idx = 1:length(this.OpenedChannels)
                channel = this.OpenedChannels(idx);
                if isKey(mgrs, channel)
                    mgr = mgrs(channel);

                    % Generate code for the focused sheet of the first file
                    % opened
                    % if internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(this.InitialArgs)
                    %     if browserClosed && idx == 1
                    %         this.callImportCallback(mgr.FocusedDocument.ViewModel);
                    %     end
                    % end

                    delete(mgr)
                end

                if isKey(this.SelectionListeners, channel)
                    c = this.SelectionListeners(channel);
                    k = keys(c);
                    for idx2 = 1:length(k)
                        listener = c(k{idx2});
                        delete(listener);
                        remove(c, k{idx2});
                    end

                    remove(this.SelectionListeners, channel);
                end

                if isKey(this.DocumentOpenedListeners, channel)
                    delete(this.DocumentOpenedListeners(channel));
                    remove(this.DocumentOpenedListeners, channel);
                end
            end

            this.OpenedChannels = strings(0);
            this.OpenedFiles = strings(0);
            this.BrowserCloseInProgress = false;
            internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab('');

            if ~isempty(this.WindowClosedFcn) && executeCB
                % Only call the WindowClosedFcn if the Import Tool window was
                % open, and this method closed it
                this.WindowClosedFcn();
            end
        end

        function delete(this)
            if this.IsOpen && ~isempty(this.Browser) && isvalid(this.Browser)
                this.Browser.Visible = false;
            end
            delete(this.Browser);

            if ~isempty(this.DeletionListeners)
                cellfun(@(x) delete(x), this.DeletionListeners);
            end
            this.DeletionListeners = {};
        end

        function setIcon(obj, tm)
            try
                winMgr = matlab.internal.webwindowmanager.instance();
                wList = winMgr.windowList;
                for idx = 1:length(wList)
                    w = wList(idx);
                    if startsWith(w.URL, obj.Browser.AppPage)
                        w.Icon = char(fullfile(matlabroot, 'toolbox/matlab/datatools/importtool/matlab/server/resources/import_16.png'));
                    end
                end                
            catch ex
                internal.matlab.datatoolsservices.logDebug("it", "Error setting icon for Import Tool window");
            end
            stop(tm);
            delete(tm);
        end

        function raiseProgressWindow(this)
            h = internal.matlab.importtool.server.ImportUtils.findVisibleImportProgressWindow();
            if ~isempty(h)
                % Bring the progress window to the front
                figure(h);
            elseif ~isempty(this.ProgressTimer)
                stop(this.ProgressTimer);
                delete(this.ProgressTimer);
            end
        end

        function deletionCallback(this, varargin)
            % Called when the manager is deleted.
            if ~this.BrowserCloseInProgress
                deletedManager = varargin{1};
                deletedChannel = string(deletedManager.Channel);
                if isstruct(deletedManager.DataSource)
                    filename = string(deletedManager.DataSource.FileName);
                else
                    filename = string(deletedManager.DataSource);
                end
                this.OpenedChannels(this.OpenedChannels == deletedChannel) = [];
                this.OpenedFiles(this.OpenedFiles == filename) = [];
                if isempty(this.OpenedChannels)
                    if ~this.ImportInProgress && ~isempty(this.Browser) && isvalid(this.Browser)
                        this.Browser.Visible = false;
                        delete(this.Browser);
                    end
                    this.IsOpen = false;
                    this.OpenedChannels = strings(0);
                    this.OpenedFiles = strings(0);
                else
                    channel = this.OpenedChannels(end);
                    managers = internal.matlab.importtool.peer. ...
                        PeerImportToolFactory.getInstance(this.AppName).getManagerInstances;
                    topTab = managers(channel);
                    internal.matlab.importtool.peer.PeerImportToolFactory. ...
                        setFocusedManager(topTab);
                end
            end
        end

        function importSelectionChanged(this, ~, eventData)
            % Listener for when the Import Tool selection changes.  This will be
            % added as a listener when the user specifies the
            % SelectionChangedFcn argument.
            import internal.matlab.importtool.server.ImportUtils;

            % Get the selection data rows and columns from the eventData.  The
            % Selection field will be something like the following, with rows as
            % the first element of the cell array, and columns as the second
            % element:
            %
            % {[2, 100], [2, 2; 6, 6]}

            selection = eventData.Selection;

            selectedRows = selection{1};
            numRowBlocks = size(selectedRows, 1);

            selectedCols = selection{2};
            numColBlocks = size(selectedCols, 1);

            if isempty(selectedRows) || isempty(selectedCols) || ...
                    any(selectedRows == 0, "all") || any(selectedCols == 0, "all")
                % Short circuit for an empty selection
                excelSelection = "";
            else
                maxBlocks = max(numRowBlocks, numColBlocks);

                excelSelection = strings(0);
                for row = 1:maxBlocks
                    for col = 1:maxBlocks
                        if row > numRowBlocks
                            adjustedRow = numRowBlocks;
                        else
                            adjustedRow = row;
                        end

                        if col > numColBlocks
                            adjustedCol = numColBlocks;
                        else
                            adjustedCol = col;
                        end

                        % Use the ImportUtils function to convert numeric
                        % selection into Excel format.  For example, [3 9],
                        % [1 2] converts to "A3:B9"
                        excelSelection(end+1) = ImportUtils.toExcelRange(...
                            selectedRows(adjustedRow, 1), ...
                            selectedRows(adjustedRow, 2), ...
                            selectedCols(adjustedCol, 1), ...
                            selectedCols(adjustedCol, 2)); %#ok<AGROW>
                    end
                end
            end

            excelSelection = strjoin(unique(excelSelection, "stable"), ",");

            % Call the user-specified SelectionChangedFcn with the excel
            % selection, file name, and sheet name if applicable.  Multiple
            % blocks in the selection will be comma separated, for example:
            % "A3:A10, C3:C10"
            s = struct;
            s.fileName = string(eventData.Source.DataModel.FileImporter.FileName);
            s.selection = string(excelSelection);
            s = this.addAdditionalSelectionFields(eventData, s);
            try
                if this.InitialSelectionDone && ~isempty(this.SelectionChangedFcn)
                    % If the initial selection is done, then broadcast this
                    % event
                    this.SelectionChangedFcn(s);
                end
            catch
                disp("ImportToolManager - Error calling SelectionChangedFcn");
            end

            % if internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(this.InitialArgs)
            %     % Call the Import Callback function when the selection changes
            %     vm = eventData.Source;
            %     this.callImportCallback(vm, excelSelection);
            % end
        end

        function set.Title(this, title)
            this.Title = title;
        end
    end

    methods(Access = protected)
        function callImportCallback(this, vm, excelSelection)
            arguments
                this
                vm
                excelSelection = vm.getTableModelProperty("excelSelection")
            end
            % Call the Import Callback function
            if ~isempty(vm.ImportDataCallback)
                if isempty(excelSelection)
                    sel = vm.DataModel.getInitialSelection;
                    excelSelection = internal.matlab.importtool.server.ImportUtils.toExcelRange(sel(1), sel(3), sel(2), sel(4));
                end
                outputVarName = vm.getTableModelProperty("OutputVariableName");
                [c, opts, outputType] = this.getGeneratedCodeAndOpts(vm, excelSelection, outputVarName);

                % Can't call this because it depends on the selection being
                % set prior, which we can't guarantee when reacting to
                % selection changes
                %   c = vm.generateScriptCode(outputVarName, false);

                st = struct('code', c);
                st.fileName = vm.DataModel.FileImporter.FileName;
                st.importOptions = opts;
                st.varNames = string(outputVarName);
                st.selection = string(excelSelection);
                if isa(outputType, "internal.matlab.importtool.server.output.TimeTableOutputType")
                    st.outputType = "timetable";
                elseif isa(outputType, "internal.matlab.importtool.server.output.CellArrayOutputType")
                    st.outputType = "cellarray";
                elseif isa(outputType, "internal.matlab.importtool.server.output.ColumnVectorOutputType")
                    st.outputType = "columnvector";
                elseif isa(outputType, "internal.matlab.importtool.server.output.NumericArrayOutputType")
                    st.outputType = "numericarray";
                elseif isa(outputType, "internal.matlab.importtool.server.output.StringArrayOutputType")
                    st.outputType = "stringarray";
                else
                    st.outputType = "table";
                end
                st = vm.addAdditionalImportDataFields(st);
                vm.ImportDataCallback(st);
            end
        end

        function sheetIdentifier = getSheetIdentifier(~, manager, ~)
            % Get the sheet identifier for the given manager's document, with
            % this specified index (unused in the base ImportToolManager), so it
            % returns the filename as the identifier.
            vm = manager.Documents.ViewModel;
            fname = vm.DataModel.FileImporter.FileName;
            if contains(fname, filesep)
                sheetIdentifier = reverse(extractBefore(reverse(fname), filesep));
            else
                sheetIdentifier = fname;
            end
        end

        function documentOpened(~, ~, ~)
            % Called when a document is opened in the manager which has a
            % selection listener set for it, so that the selection listener can
            % be added to the new view.  Unused by the base class.
        end

        function s = addAdditionalSelectionFields(this, ~, currSelectionStruct)
            % Add in any additional selection fields (there are none for the
            % base ImportToolManager), and set the InitialSelectionDone flag.
            s = currSelectionStruct;
            this.InitialSelectionDone = true;
        end

        function setWindowTag(this, tag)
            % Set the browser window Tag property, so it can be found for tests.
            % This function is called when the window for the AppContainer is
            % created, but there is no method on AppContainer to actually set
            % the Tag.  So this is the best way to do this until g2753783 is
            % fixed.
            function localSetWindowTag(this, tag)
                warningState = warning("query", "MATLAB:structOnObject");
                warning("off","MATLAB:structOnObject");
                c = onCleanup(@() warning(warningState.state, "MATLAB:structOnObject"));

                try
                    s = struct(this.Browser);
                    w = s.Window;
                    if contains(tag, "/")
                        w.Tag = extractAfter(tag, "/");
                    else
                        w.Tag = tag;
                    end
                catch
                    % This can fail during unit tests
                end
            end

            % Defer this because we're still in the process of the window
            % creation.
            matlab.graphics.internal.drawnow.callback(@(e,d) localSetWindowTag(this, tag));
        end

        function [c, opts, outputType] = getGeneratedCodeAndOpts(~, vm, excelSelection, outputVarName)
           error('no base class implementation')
        end
    end

    methods(Static)
        % Supports Debugging workflows
        function debugImportFlag = setDebug(debugFlag)
            persistent enableDebugFlag;
            if nargin >=1
                enableDebugFlag = debugFlag;
            end

            if isempty(enableDebugFlag)
                debugImportFlag = false;
            else
                debugImportFlag = enableDebugFlag;
            end
        end
    end
end
