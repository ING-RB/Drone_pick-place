% This class is unsupported and might change or be removed without notice
% in a future version.

% Extends the ImportToolManager to provide a manager class for importing, by
% opening and managing the JS Import Tool from Matlab.

% Copyright 2019-2024 The MathWorks, Inc.

classdef SpreadsheetImportToolManager < internal.matlab.importtool.peer.ImportToolManager

    properties(Constant)
        SPREADSHEET_IMPORT_TYPE = 'spreadsheet';
    end

    methods(Static)
        function spreadsheetITManager = getInstance(varargin)
            import internal.matlab.importtool.peer.SpreadsheetImportToolManager;
            if nargin == 1
                appName = string(varargin{1});
            else
                appName = "";
            end

            spreadsheetITManager = SpreadsheetImportToolManager.getSetInstances(appName, []);
        end

        function spreadsheetITManager = getSetInstances(appName, instance)
            import internal.matlab.importtool.peer.SpreadsheetImportToolManager;

            mlock;  % Keep persistent variables until MATLAB exits

            persistent spreadsheetITManagers;
            if isempty(spreadsheetITManagers)
                spreadsheetITManagers = containers.Map();
            end

            spreadsheetITManager = [];
            if isKey(spreadsheetITManagers, appName) && isempty(instance)
                spreadsheetITManager = spreadsheetITManagers(appName);
            end

            if isempty(spreadsheetITManager) || ~isvalid(spreadsheetITManager)
                if isempty(instance)
                    spreadsheetITManager = SpreadsheetImportToolManager(appName);
                else
                    spreadsheetITManager = instance;
                end

                spreadsheetITManagers(char(appName)) = spreadsheetITManager;
            end
        end

        function spreadsheetImport(filename, debug, varargin)
            import internal.matlab.importtool.peer.SpreadsheetImportToolManager;

            if nargin == 3
                channel = varargin{1};
            else
                channel = SpreadsheetImportToolManager.DebugChannel;
            end

            itm = SpreadsheetImportToolManager.getInstance(channel);
            itm.initializeAndImportFile(filename, ...
                struct("Debug", debug, ...
                "ImportType", SpreadsheetImportToolManager.SPREADSHEET_IMPORT_TYPE, ...
                "AppName", string(reverse(extractAfter(reverse(channel), "/")))));
        end

        function s = getSnc()
            import internal.matlab.importtool.peer.SpreadsheetImportToolManager;

            % Get the nonce to use for the Import Tool.  This needs to be
            % reused for a given page, especially in Matlab Online.
            mlock;
            persistent snc;

            if isempty(snc)
                snc = connector.newNonce;
                message.subscribe("/Import", @(evt) SpreadsheetImportToolManager.handleMessage(evt), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            end

            s = snc;
        end

        function handleMessage(eventData)
            import internal.matlab.importtool.peer.SpreadsheetImportToolManager;

            if isequal(eventData.importType, SpreadsheetImportToolManager.SPREADSHEET_IMPORT_TYPE)
                spreadsheetITManager = SpreadsheetImportToolManager.getInstance(eventData.channel);
                status = spreadsheetITManager.initializeAndImportFile(eventData.filename, ...
                    struct("Debug", eventData.debug, ...
                    "ImportType", eventData.importType, ...
                    "AppName", eventData.channel));
                if ~isempty(status)
                    % Remove the file from the SpreadsheetWorkbookFactory if it was added.  We don't
                    % want this sticking around, because if the user updates the spreadsheet to fix the 
                    % error, we need to reopen the workbook, and not use the cached version.
                    swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
                    swf.workbookClosed(status.filename);
                end
            end
        end
    end

    methods
        function this = SpreadsheetImportToolManager(appName)
            this@internal.matlab.importtool.peer.ImportToolManager();
            this.ImportType = this.SPREADSHEET_IMPORT_TYPE;
            this.ProgressMessageText =  getString(message(...
                "MATLAB:codetools:importtool:ProgressMessageSpreadsheetFile"));
            this.TitleTag = "MATLAB:codetools:importtool:SpreadsheetImportTitle";
            this.AppName = appName;
            this.Snc = internal.matlab.importtool.peer.SpreadsheetImportToolManager.getSnc;
        end
    end

    methods(Access = protected)
        function sheetIdentifier = getSheetIdentifier(~, manager, idx)
            % Get the sheet identifier, for the given sheet number
            vm = manager.Documents(idx).ViewModel;
            state = vm.DataModel.getState();
            sheetIdentifier = state.SheetName;
        end

        function vm = documentOpened(this, ~, ed)
            % Called when a document is opened in the manager which has a
            % selection listener set for it, so that the selection listener can
            % be added to the new view
            vm = ed.Document.ViewModel;

            if isfield(this.InitialArgs, "SelectionChangedFcn") && ~isempty(this.InitialArgs.SelectionChangedFcn)
                channel = ed.Source.Channel;
                c = this.SelectionListeners(channel);
                state = vm.DataModel.getState();
                sheetName = state.SheetName;
                c(sheetName) = event.listener(...
                    vm, "SelectionChanged", @this.importSelectionChanged);
                this.SelectionListeners(channel) = c;

                % Call the selection changed callback when the user switches
                % tabs for the first time, setting the source as the ViewModel
                % of the selected document.
                evt = struct;
                evt.Selection = vm.getSelection();
                evt.Source = vm;
                this.importSelectionChanged([], evt);
            end

            % Setup the DataImportedFcn if it is specified
            if isfield(this.InitialArgs, "DataImportedFcn") && ~isempty(this.InitialArgs.DataImportedFcn)
                vm.ImportDataCallback = this.InitialArgs.DataImportedFcn;
            end

            % Setup the CloseOnImport if it is specified as true
            if isfield(this.InitialArgs, "CloseOnImport") && this.InitialArgs.CloseOnImport
                vm.CloseOnImportCallback = @this.browserWindowClosed;
            end

            if internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(this.InitialArgs)
                % Call the Import Callback function when the selection changes
                this.callImportCallback(vm);
            end
        end

        function s = addAdditionalSelectionFields(this, eventData, currSelectionStruct)
            s = currSelectionStruct;

            state = eventData.Source.DataModel.getState;
            if isfield(state, "SheetName")
                s.sheetName = state.SheetName;
            end

            if ~this.InitialSelectionDone
                % Update the InitialSelectionDone flag if the initial sheet
                % wasn't specified, or if it was and this is the selection for
                % that sheet
                if ~isfield(this.InitialArgs, "InitialSheet") || isempty(this.InitialArgs.InitialSheet)
                    this.InitialSelectionDone = true;
                elseif strcmp(this.InitialArgs.InitialSheet, s.sheetName)
                    this.InitialSelectionDone = true;
                end
            end
        end

        function [c, opts, outputType] = getGeneratedCodeAndOpts(~, vm, excelSelection, outputVarName)
            [opts, dataRange, outputType] = vm.getImportOptions(excelSelection);
            scg = internal.matlab.importtool.server.SpreadsheetCodeGenerator(false);
            c = scg.generateScript(opts, ...
                "Filename", vm.DataModel.FileImporter.FileName, ...
                "Range", dataRange, ...
                "OutputType", outputType, ...
                "VarName", outputVarName, ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);
        end
    end
end
