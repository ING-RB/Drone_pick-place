% This class is unsupported and might change or be removed without notice
% in a future version.

classdef RemoteImportToolManager < internal.matlab.variableeditor.peer.RemoteManager
    % A class defining MATLAB PeerModel Import Tool

    % Copyright 2018-2024 The MathWorks, Inc.

    % Property Definitions:
    properties
        DataSource;
        TableList;
    end

    properties(Constant)
        ActionManagerNamespace = '_ImportActions';
        startPath = 'internal.matlab.importtool.Actions';
    end

    properties(Hidden)
        InitialSheetSet logical = false;
        InitialSheetSetRequired logical = false;
    end

    methods (Access = public)
        function this = RemoteImportToolManager(provider, dataSource)
            % creates RemoteManager with the specified dataSource, channel, and
            % root.  fileType is the last argument (unused)
            % calls import

            % If CreateActionsSynchronous was passed in as part of the
            % dataSource, use it.  Otherwise default to false.
            if isfield(dataSource, "CreateActionsSynchronous")
                createActionsSynchronous = dataSource.CreateActionsSynchronous;
            else
                createActionsSynchronous = false;
            end
            this@internal.matlab.variableeditor.peer.RemoteManager(provider, false);
            if ~isempty(dataSource) && exist(dataSource.FileName, 'file')
                if isempty(this.ActionManager)
                    this.initActions([this.Channel this.ActionManagerNamespace], this.startPath, ...
                        'internal.matlab.datatoolsservices.actiondataservice.Action', createActionsSynchronous);
                end

                dataSource.ImportType = char(dataSource.ImportType);
                this.DataSource = dataSource;

                % Initialize the ImportType in constructor since the
                % importDataSource needs to know the importType.
                if ~isfield(this.DataSource, "ImportType")
                    this.DataSource.ImportType = internal.matlab.importtool.server.ImportUtils.getImportType(...
                        this.DataSource.FileName);
                end

                % create a dialog to show that import is in progress
                if isempty(internal.matlab.importtool.server.ImportUtils.findImportProgressWindow)
                    s = dir(dataSource.FileName);
                    if s.bytes > 1e6
                        this.showProgressMessage();
                    end
                end
                this.importDataSource();
            end
        end

        function showProgressMessage(this)
            identifier = this.DataSource.Importer.Identifier;
            identifier = upper(extractBefore(identifier,2)) + extractAfter(identifier,1);

            msg = getString(message(...
                "MATLAB:codetools:importtool:ProgressMessage" + identifier + "File"));
            internal.matlab.importtool.server.ImportUtils.showImportProgressWindow([], msg);
        end

        function varDocument = importDataSource(this, focusedSheet)
            arguments
                this;
                focusedSheet double = 1;
            end
            import internal.matlab.importtool.server.ImportUtils;

            if this.DataSource.Importer.HasMultipleTables
                % loop through the tables in the file and add them to the
                % document list create remote documents for each of the sheets
                this.TableList = this.getDocumentList();
                if isempty(this.TableList)
                    internal.matlab.importtool.server.ImportUtils.closeImportProgressWindow();
                    errordlg(getString(message(...
                        "MATLAB:codetools:EmptyExcelFile")), ...
                        getString(message(...
                        "MATLAB:codetools:importtool:ProgressMessageTitle")));
                    return;
                end
                this.setProperty('SheetNames', this.TableList);

                if isfield(this.DataSource, "InitialSheet") && ~isempty(this.DataSource.InitialSheet) && ...
                        ~strcmp(this.DataSource.InitialSheet, this.TableList(1))
                    % Create the document for the initial sheet, if it is set,
                    % and if it isn't the same as the first sheet in the file
                    this.DataSource.SheetName = this.DataSource.InitialSheet;
                    this.DataSource.Importer = internal.matlab.importtool.server.ImporterFactory.getImporter( ...
                        this.DataSource);

                    this.InitialSheetSetRequired = true;
                    this.DataSource.SheetName = this.DataSource.InitialSheet;
                    focusedSheet = find(this.TableList == this.DataSource.InitialSheet);
                else
                    this.DataSource.SheetName = this.TableList(1);
                end
            end

            varDocument = this.createImportDocument();

            % set the focusedSheet as the focusedDocument.  Unless
            % specified, the Import Tool opens to show the first sheet.
            % But if the InitialSheet is specified as the API, the document
            % for this sheet will be created too.  In this case, it will be
            % the last document in the list.
            this.FocusedDocument = this.Documents(min(focusedSheet, length(this.Documents)));
            % Set the fileName as a property on the Manager.
            [~, fname, ext] = fileparts(this.DataSource.FileName);
            this.setProperty('DataSource', [fname ext]);
        end

        function setNonDefaultInitialSheet(this)
            try
                focusedSheet = find(this.TableList == this.DataSource.InitialSheet);
                this.FocusedDocument = this.Documents(min(focusedSheet, length(this.Documents)));
            catch
            end
        end

        function openImportSheet(this, ed)
            if this.DataSource.Importer.HasMultipleTables
                % ed.EventData.sheetName is the tableName
                this.DataSource.SheetName = ed.data.sheetName;
                this.DataSource.Importer = internal.matlab.importtool.server.ImporterFactory.getImporter( ...
                    this.DataSource);
                this.DataSource.SheetName = ed.data.sheetName;
            end
            this.createImportDocument();
        end

        function varDocument = createImportDocument(this)
            veVar = internal.matlab.importtool.peer.RemoteImportToolManager.getAdapterInstance(...
                this.DataSource);
            varDocument = this.delayCreateDocument(veVar);
        end

        function varDocument = delayCreateDocument(this, veVar)
            varDocument = this.addDocument(veVar, '');
            this.doDelayedDocumentCreation();
        end

        % overridden method
        function isOpen = isVariableOpen(~, ~)
            isOpen = false;
        end

        function documents = getDocumentList(this)
            documents = this.DataSource.Importer.TableList;
        end

        % Closes all documents that are open in the manager across all
        % workspaces
        function closeAllVariables(this)
            for i=length(this.Documents):-1:1
                if isvalid(this.Documents(i))
                    docIndex = this.documentIndex(this.Documents(i).DocID);
                    if this.FocusedDocument == this.Documents(docIndex)
                        this.FocusedDocument = [];
                    end
                    if ~isempty(docIndex)
                        this.Documents = [this.Documents(1:docIndex-1) this.Documents(docIndex+1:end)];
                    end
                end
            end

            this.Documents = [];
        end

        function index = documentIndex(this, docID)
            index = [];

            for i=1:length(this.Documents)
                doc = this.Documents(i);

                if strcmp(doc.DocID, docID)
                    index = i;
                    return;
                end
            end
        end

        function tableIndex = getTableIndex(this, tableName)
            tableList = cellfun(@(x)strcmp(x, tableName), this.TableList);
            tableIndex = find(tableList);
        end

        function closevar(~, ~, ~)
        end

        function handleEventFromClient(this, es, ed)
            this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteManager(es, ed);
            if isfield(ed.data,'type')
                try
                    switch ed.data.type
                        case 'OpenImportSheet'
                            this.openImportSheet(ed);
                    end
                catch e
                    this.sendErrorMessage(e.message);
                end
            end
        end

        % this is for testing purpose only
        function testCreateDocument(this, veVar, userContext, docID)
            this.createDocument(veVar, docID, UserContext=userContext);
        end

        % this is for testing purpose only
        function sheetNames = testGetSheetNames(this)
            sheetNames = this.getSheetNames();
        end

        function documents = testGetDocumentList(this)
            documents = this.getDocumentList();
        end

        function handlePropertySetFromClient(this, ~, eventObj)
            % Override the super class implementation in order to broadcast the
            % selection changed event when the focused document change.  This
            % way the new selection for files with multiple tables will
            % be broadcast.
            if ~isfield(eventObj, "data")
                return;
            end

            handlePropertySetFromClient@internal.matlab.variableeditor.peer.RemoteManager(...
                this, [], eventObj);

            data = this.getData(eventObj);
            if strcmpi(data.key, "FocusedDocument") && isvalid(this) && ~isempty(this.FocusedDocument)
                vm = this.FocusedDocument.ViewModel;
                eventData = internal.matlab.variableeditor.SelectionEventData;
                eventData.Selection = vm.getSelection;
                vm.notify("SelectionChanged", eventData);

                if this.InitialSheetSetRequired && ~this.InitialSheetSet && ...
                        isfield(this.DataSource, "InitialSheet") && ~isempty(this.DataSource.InitialSheet) && ...
                        ~strcmp(this.DataSource.InitialSheet, this.TableList(1))

                    fcn =  @(es,ed) this.setNonDefaultInitialSheet();
                    builtin('_dtcallback', fcn, true);
                    this.InitialSheetSet = true;
                end
            end
        end
    end

    methods(Static)
        function adapterInstance = getAdapterInstance(dataSource)
            docName = internal.matlab.importtool.server.ImportUtils.getValidNameFromTextFile(dataSource.FileName);
            dataSource.Type = dataSource.ImportType;
            adapterInstance = internal.matlab.importtool.peer.RemoteTabularImportAdapter(docName, dataSource);
        end
    end

    methods(Access='protected')
        function varDocument = createDocument(this, veVar, docID, documentCreationArgs)
            arguments
                this
                veVar
                docID char
                documentCreationArgs.UserContext char = ''
                documentCreationArgs.DisplayFormat = ''
            end
            args = namedargs2cell(documentCreationArgs);
            varDocument = internal.matlab.importtool.peer.RemoteTabularImportDocument(this, veVar, docID, args{:});
            this.Documents = [this.Documents varDocument];

            % Notify on the DocumentOpened, since this is overriding the base
            % class methods which would have done it.
            eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
            eventdata.Name = veVar.Name;
            eventdata.Workspace = [];
            eventdata.Document = varDocument;
            this.notify("DocumentOpened", eventdata);
        end
    end

    methods(Static)
        function docID = getNextDocID(veVar)
            % Make sure docID is a valid MessageService channel (alphanumeric
            % plus underline).  This is done by creating a channel based off of
            % the filename (which is fully resolved by now).
            docID = internal.matlab.importtool.peer.RemoteImportToolManager.getValidChannelId( ...
                veVar.DataSource.FileName, ...
                veVar.DataSource.Importer.HasMultipleTables, ...
                veVar.DataSource.Importer.TableIdentifier);
        end
    end

    methods(Static, Hidden)
        function id = getValidChannelId(filename, hasMultiTables, tableID)
            arguments
                filename (1,1) string;
                hasMultiTables (1,1) logical = false;
                tableID (1,1) string = "";
            end

            % Construct a valid channel ID based on the filename.  For example,
            % if the filename is:  c:\docs\file.csv, the channel name would be
            % '__cdocsfilecsv'

            [path, fname, ext] = fileparts(filename);
            pat = characterListPattern(['a':'z', 'A':'Z', '0':'9', '_']);
            validName = extract(fname, pat);
            if isempty(validName)
                % handle non-ascii filenames
                validName = string(double(char(fname)));
            end
            validPath = strjoin(extract(path, pat), "");
            validName = strjoin(validName, "");
            validName = string(validPath) + string(validName) + strjoin(extract(ext, pat), "");

            if hasMultiTables
                % Include the table ID for Multiple tables, making sure this is
                % valid too.
                tableID = strjoin(extract(tableID, pat), "");
                id = ['_' char(tableID) '__' char(validName)];
            else
                %text import doesn't have sheetName
                id = ['__' char(validName)];
            end
        end
    end
end
