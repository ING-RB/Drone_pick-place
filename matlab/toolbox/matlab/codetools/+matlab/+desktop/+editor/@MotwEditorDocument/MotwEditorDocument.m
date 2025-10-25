classdef (Hidden, Sealed) MotwEditorDocument < matlab.desktop.editor.DocumentInterface
%matlab.desktop.editor.MotwEditorDocument Access document in RTC based Editor in web based UI.
%   This class is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2019-2025 The MathWorks, Inc.

    properties (SetAccess = private, Dependent = true)
        Filename;
        Opened;
        Language;
        SelectedText;
        Modified;
        ExtendedSelection;
        ExtendedSelectedText;
    end

    properties (SetAccess = public, Dependent = true)
        Text;
        Selection;
        Editable;
    end

    properties (SetAccess = private, Hidden = true)
        AppContainerDocument;
    end

    properties (SetAccess = immutable, Hidden = true, Dependent = true)
        RtcId;
    end

    properties (GetAccess = private, SetAccess = private, Hidden = true)
        IsRtcReady = matlab.desktop.editor.RtcEditorState.UNKNOWN;
        MaxCommunicationWaitTime = 45; % seconds
        DelayTime = 0.01; % 10 milliseconds
        ApiMessageNotificationChannelPrefix = '/api/editor/notify/';
        ApiMessageRequestChannelPrefix = '/api/editor/request/';
        ApiMessageResponseChannelPrefix = '/api/editor/response/';
        RequestResponseSubscriptionId = [];
        NotificationSubscriptionId = [];
        ContentPropertyChangeListener = [];
    end

    methods (Access = private, Hidden = true)
        function obj = MotwEditorDocument(appContainerDocument)
        %MotwEditorDocument - Constructor for MotwEditorDocument class.
        %   OBJ = MotwEditorDocument(APPCONTAINERDOCUMENT)
            assert(~isempty(appContainerDocument), message('MATLAB:Editor:Document:EmptyEditor'));
            obj.AppContainerDocument = appContainerDocument;
            obj.subscribePropertyChange();
            obj.subscribeNotifications();
        end

        function ensureRtcReady(obj)
            import matlab.desktop.editor.RtcEditorState;
            timeElapsed = 0;
            while obj.IsRtcReady == RtcEditorState.UNKNOWN
                if timeElapsed >= obj.MaxCommunicationWaitTime
                    obj.unsubscribe();
                    break;
                elseif isClosed(obj.AppContainerDocument)
                    obj.IsRtcReady = RtcEditorState.DESTROYED;
                    obj.unsubscribe();
                elseif ~isRtcIdAvailable(obj) ...
                        && isWaitingToInitialize(obj.AppContainerDocument)
                    obj.AppContainerDocument.Content = struct( ...
                        'WaitToInitialize', false ...
                    );
                elseif isRtcIdAvailable(obj)
                    obj.IsRtcReady = RtcEditorState.CREATED;
                else
                    matlab.internal.yield;
                    pause(obj.DelayTime);
                    timeElapsed = timeElapsed + obj.DelayTime;
                end
            end

            assert(obj.IsRtcReady == RtcEditorState.CREATED && ~isempty(getRtcId(obj)), ...
                   message('MATLAB:Editor:Document:OpenLoadTimeout'));
        end

        function subscribePropertyChange(obj)
            obj.unsubscribePropertyChange();
            obj.ContentPropertyChangeListener = addlistener(obj.AppContainerDocument, 'PropertyChanged', @obj.handleContentPropertyChanged);
        end

        function handleContentPropertyChanged(obj, ~, evt)
        % Monitor AppContainerDocument.Content property for changes
        % to AppContainerDocument.Content.RtcId
            if ~strcmpi(evt.PropertyName, 'Content')
                return;
            end
            obj.subscribeNotifications();
        end

        function subscribeNotifications(obj)
            if ~isempty(obj.NotificationSubscriptionId)
                obj.unsubscribeNotifications();
            end
            % Subscribe to notification channel when RtcId is available.
            if obj.IsRtcReady == matlab.desktop.editor.RtcEditorState.DESTROYED ...
                    || isClosed(obj.AppContainerDocument) ...
                    || ~isRtcIdAvailable(obj)
                return;
            end
            connector.ensureServiceOn;
            obj.NotificationSubscriptionId = message.subscribe( ...
                strcat(obj.ApiMessageNotificationChannelPrefix, getRtcId(obj)), @obj.notifyEvent);
        end

        function notifyEvent(obj, msg)
            notify(obj, msg.eventName);
        end

        function result = performActionSync(obj, action, varargin)
            obj.ensureRtcReady;

            connector.ensureServiceOn;
            obj.RequestResponseSubscriptionId = message.subscribe( ...
                strcat(obj.ApiMessageResponseChannelPrefix, getRtcId(obj)), @(msg) handleResponse(msg));
            timeElapsed = 0;
            if nargin < 3
                arguments = '';
            else
                arguments = varargin;
            end
            messageToPublish.action = action;
            messageToPublish.arguments = arguments;
            message.publish(strcat(obj.ApiMessageRequestChannelPrefix, getRtcId(obj)), messageToPublish);
            response = {};

            while isempty(response) && iscell(response)
                if timeElapsed >= obj.MaxCommunicationWaitTime
                    obj.unsubscribeRequestResponse();
                    error(message('MATLAB:Editor:Document:PerformActionTimeout', action));
                elseif isClosed(obj.AppContainerDocument)
                    obj.IsRtcReady = matlab.desktop.editor.RtcEditorState.DESTROYED;
                    obj.unsubscribe();
                    error(message('MATLAB:Editor:Document:EditorClosed'));
                else
                    matlab.internal.yield;
                    pause(obj.DelayTime);
                    timeElapsed = timeElapsed + obj.DelayTime;
                end
            end

            obj.unsubscribeRequestResponse();
            validateResponse(response, obj, arguments);
            result = response.result;

            function handleResponse(msg)
                if strcmp(action, msg.actionPerformed)
                    response = msg;
                end
            end
        end
    end

    %% Static constructors
    %These should only be called from matlab.desktop.editor functions
    methods (Static, Hidden)
        function obj = findEditor(fname)
        %findEditor Return Document instance for matching file name.
            assert(nargin >= 1 && ~isempty(fname), ...
                   message('MATLAB:Editor:Document:NoFilename'));

            if isAbsolutePath(fname)
                acdoc = findOpenAppContainerDocument(fname);
                obj = getMotwEditorDocumentObj(acdoc);
            else
                % This indicates that fname is an untitled buffer or relative path.
                MO = getRootApp();
                acdoc = MO.getDocument(getEditorGroup().Tag, fname);
                if ~isempty(acdoc)
                    obj = getMotwEditorDocumentObj(acdoc);
                else
                    % This indicates that fname is relative path.
                    obj = matchname(fname);
                end
            end
        end

        function obj = openEditor(filename)
        %openEditor Attempt to open named file in Editor.
            if isfolder(filename)
                folderpath = fileparts(filename);
                questionMessage = message('MATLAB:Editor:Document:CannotOpenDirectory', folderpath);
                obj = promptToOpenUntitledDocument(questionMessage);
            else
                obj = openEditorViaFunction(filename, false);
            end
        end

        function obj = openEditorForExistingFile(filename)
        %openEditorForExistingFile Open named file in Editor.
            [filepath, name, ext] = fileparts(filename);
            if strcmp(ext, '.p')
                filename = fullfile(filepath, strcat(name, '.m'));
            end
            obj = openEditorViaFunction(filename, true);
        end
    end

    %% Static accessor methods
    % matlab.desktop.editor uses these methods to obtain information
    % about existing documents. Because the return type is a Document
    % object, these methods must access the constructor.
    methods (Static, Hidden)
        function objs = getAllOpenEditors
        %getAllOpenEditors Return list of all open Documents.
            MO = getRootApp();
            docs = MO.getDocuments();
            objs = createEmptyReturnValue;
            for x = 1:numel(docs)
                doc = docs{x};
                if isempty(doc) || isClosed(doc) || ~isValidDocumentGroupTag(doc.DocumentGroupTag)
                    continue;
                end
                objs(end+1) = getMotwEditorDocumentObj(doc); %#ok<AGROW>
            end
        end

        function obj = getActiveEditor
        %getActiveEditor Return Document object for active MATLAB Editor.
            MO = getRootApp();
            MO.LastSelectedDocument;
            lastSelectedDoc = getEditorGroup().LastSelected;
            if isempty(lastSelectedDoc)
                obj = createEmptyReturnValue;
                return;
            end
            acdoc = MO.getDocument(getEditorGroup().Tag, lastSelectedDoc.tag);
            obj = getMotwEditorDocumentObj(acdoc);
        end

        function obj = new(bufferText)
        %NEW Create new document containing the specified text and return Document
        %object, which references that untitled object.
            obj = createAndAddAppContainerDocumentToRootApp('', 'm');
            if ~isempty(obj) && ~isempty(bufferText)
                obj.Text = bufferText;
            end
            % Wait until the document opens
            assertOpen(obj);
        end
    end

    %% Public instance methods
    methods
        function save(obj)
        %save Save Document text to disk.
            assertOpen(obj);
            for x = 1:numel(obj)
                try
                    obj(x).performActionSync('Save');
                    filename = obj(x).Filename;
                    clear(filename);
                    fschange(filename);
                catch ME
                    error('MATLAB:Editor:Document:SaveFailed', strrep(ME.message, '\', '\\'));
                end
            end
        end

        function saveAs(obj, filename)
        %saveAs Save Document text to disk using specified file name.
            assertScalar(obj);
            assertOpen(obj)

            assert(isAbsolutePath(filename), 'MATLAB:Editor:Document:SaveAsFailed', ...
                   message('MATLAB:Editor:Document:NotAbsolutePath').getString());

            % If this is an .mlx file and target is a .mlx or rich markup .m, the we do
            % regular save-as. Otherwise its an export operation.
            if shouldExport(obj.Filename, filename)
                matlab.desktop.editor.internal.exportDocumentByID(obj.RtcId, filename);
                return;
            end
            try
                obj.performActionSync('SaveAs', filename);
            catch ME
                error('MATLAB:Editor:Document:SaveAsFailed', strrep(ME.message, '\', '\\'));
            end
        end

        function goToLine(obj, line)
        %goToLine Move cursor to specified line in Editor document.
            assertScalar(obj);
            assertPositiveLessEqualInt32Max(line, 'LINENUMBER');
            assertOpen(obj);

            obj.performActionSync('GoToLine', line);
        end

        function goToPositionInLine(obj, line, position)
        %goToPositionInLine Move to specified position within line.
            assertScalar(obj);
            assertPositiveLessEqualInt32Max(line, 'LINE');
            assertLessEqualInt32Max(position, 'POSITION');
            assertOpen(obj);

            obj.performActionSync('GoToPositionInLine', line, position);
        end

        function goToFunction(obj, functionName)
        %goToFunction Move to function in MATLAB program.
            assertScalar(obj);
            obj.performActionSync('GoToFunction', functionName);
        end

        function smartIndentContents(obj)
        %smartIndentContents Apply smart indenting to code.
            assertOpen(obj);
            for x = 1:numel(obj)
                obj(x).performActionSync('SmartIndentContents');
            end
        end

        function close(obj)
        %close Close document in Editor.
            MO = getRootApp();
            for x = 1:numel(obj)
                if ~isClosed(obj(x).AppContainerDocument)
                    MO.closeDocument(obj(x).AppContainerDocument.DocumentGroupTag, obj(x).AppContainerDocument.Tag, false, 'sync');
                end
                obj(x).unsubscribe();
            end
        end

        function closeNoPrompt(obj)
        %closeNoPrompt Close document in Editor, discarding unsaved changes.
            MO = getRootApp();
            for x = 1:numel(obj)
                if ~isClosed(obj(x).AppContainerDocument)
                    MO.closeDocument(obj(x).AppContainerDocument.DocumentGroupTag, obj(x).AppContainerDocument.Tag, true, 'sync');
                end
                obj(x).unsubscribe();
            end
        end

        function reload(obj)
        %RELOAD Revert to saved version of Editor document.
            assertOpen(obj);
            for x = 1:numel(obj)
                reloadSuccess = obj(x).performActionSync('Reload');
                assert(islogical(reloadSuccess) && reloadSuccess, ...
                       message('MATLAB:Editor:Document:ReloadFailed', obj(x).Filename));
            end
        end

        function appendText(obj, textToAppend)
        %appendText Append text to document in Editor.
            assertScalar(obj);
            textToAppend = transposeColumnCharVector(textToAppend);
            assertOpen(obj);
            assertEditable(obj);
            obj.performActionSync('AppendText', textToAppend);
        end

        function set.Text(obj, textToSet)
        %set.Text Set the text in the Document buffer.
            textToSet = transposeColumnCharVector(textToSet);
            assertOpen(obj);
            assertEditable(obj);
            obj.performActionSync('SetText', textToSet);
        end

        function makeActive(obj)
        %makeActive Make document active in Editor.
            assertScalar(obj);
            MO = getRootApp();
            MO.bringDocumentToFront(obj.AppContainerDocument);
        end

        function newObjs = setdiff(newObjsList, originalObjList)
        %setdiff Compare lists of Editor Documents.
            newObjs = createEmptyReturnValue;
            for i = 1:numel(newObjsList)
                currentNewEditor = newObjsList(i);
                if ~ismember(currentNewEditor, originalObjList, 'legacy')
                    newObjs(end+1) = currentNewEditor; %#ok<AGROW>
                end
            end
        end

        function filename = get.Filename(obj)
            filename = obj.AppContainerDocument.Content.Filename;
        end

        function text = get.Text(obj)
            assertOpen(obj);
            text = obj.performActionSync('GetText');
        end

        function selection = get.Selection(obj)
            assertOpen(obj);
            selection = obj.performActionSync('GetSelection')';
        end

        function set.Selection(obj, position)
            assertOpen(obj);
            assert(isnumeric(position) && length(position) == 4, ...
                   message('MATLAB:Editor:Document:InvalidSelection'));
            position = uint32(position);
            obj.performActionSync('SetSelection', position);
        end

        function text = get.SelectedText(obj)
            assertOpen(obj);
            text = obj.performActionSync('GetSelectedText');
        end

        function extendedSelection = get.ExtendedSelection(obj)
            assertOpen(obj);
            extendedSelection = obj.performActionSync('GetExtendedSelection');
        end

        function extendedSelectedText = get.ExtendedSelectedText(obj)
            assertOpen(obj);
            extendedSelectedText = obj.performActionSync('GetExtendedSelectedText');
        end

        function editable = get.Editable(obj)
            assertOpen(obj);
            editable = obj.performActionSync('GetEditable');
        end

        function set.Editable(obj, editable)
            assertOpen(obj);
            obj.performActionSync('SetEditable', editable);
        end

        function lang = get.Language(obj)
            assertOpen(obj);
            lang = obj.performActionSync('GetLanguage');
        end

        function insertTextAtPositionInLine(obj, text, line, position)
        %insertTextAtPositionInLine Insert text in Editor document at position specified.
            assertScalar(obj);
            text = transposeColumnCharVector(text);
            assertEditable(obj);
            obj.performActionSync('InsertTextAtPositionInLine', text, clampInf(line), clampInf(position));
        end

        function isopen = get.Opened(obj)
            if obj.IsRtcReady == matlab.desktop.editor.RtcEditorState.DESTROYED
                isopen = false;
                return;
            elseif isClosed(obj.AppContainerDocument)
                obj.IsRtcReady = matlab.desktop.editor.RtcEditorState.DESTROYED;
                obj.unsubscribe();
                isopen = false;
                return;
            else
                obj.ensureRtcReady;
                isopen = true;
            end
        end

        function bool = get.Modified(obj)
            import matlab.desktop.editor.RtcEditorState;
            if ~isRtcIdAvailable(obj)
               if isContentAvailable(obj.AppContainerDocument) && isfield(obj.AppContainerDocument.Content, 'LastKnownModified')
                    bool = obj.AppContainerDocument.Content.LastKnownModified;
                else
                    bool = false;
                end
            else
                assertOpen(obj)
                bool = obj.performActionSync('GetModified');
            end
        end

        function rtcId = get.RtcId(obj)
            obj.ensureRtcReady;
            rtcId = getRtcId(obj);
        end

        function bool = eq(obj1, obj2)
        %eq Overloads the == operator to compare two Document objects.
            n1 = numel(obj1);
            n2 = numel(obj2);

            assert(n1 == 1 || n2 == 1 || any(size(obj1) == size(obj2)), ...
                   message('MATLAB:Editor:Document:InvalidMatrixDimensions'));

            % Make sure that at least one object is not empty.
            if isempty(obj1) || isempty(obj2)
                bool = false;
            else
                % Loop over the larger array.
                if n2 > n1
                    bool = loopEq(obj2, obj1);
                else
                    bool = loopEq(obj1, obj2);
                end
            end

            function bool = loopEq(obj1, obj2)
                bool = false(size(obj1));
                num2 = numel(obj2);
                for x = 1:numel(obj1)
                    if num2 > 1
                        je2 = obj2(x).AppContainerDocument.Tag;
                    else
                        je2 = obj2.AppContainerDocument.Tag;
                    end
                    bool(x) = strcmp(obj1(x).AppContainerDocument.Tag, je2);
                end
            end
        end

        function bool = isequal(obj1, obj2)
        % Test two (possibly arrays of) Documents for equality.
            bool = isequal(size(obj1),size(obj2)) && all(eq(obj1, obj2));
        end
    end

    methods (Hidden)
        function [line, position] = indexToPositionInLine(obj, index, varargin)
            assertOpen(obj);
            if nargin > 2
                acknowledgeLineEnding = varargin{1}.AcknowledgeLineEnding;
            else
                acknowledgeLineEnding = false;
            end
            linePosition = obj.performActionSync('IndexToPositionInLine', index, acknowledgeLineEnding);
            line = linePosition.line;
            position = linePosition.column;
        end

        function index = positionInLineToIndex(obj, line, position, varargin)
            assertOpen(obj);
            if nargin > 3
                acknowledgeLineEnding = varargin{1}.AcknowledgeLineEnding;
            else
                acknowledgeLineEnding = false;
            end
            index = obj.performActionSync('PositionInLineToIndex', line, position, acknowledgeLineEnding);
        end

        function delete(obj)
            obj.unsubscribe();
        end
    end

    methods (Hidden, Access = private)
        function unsubscribe(obj)
            obj.unsubscribeRequestResponse();
            obj.unsubscribeNotifications();
            obj.unsubscribePropertyChange();
        end

        function unsubscribeRequestResponse(obj)
            if isempty(obj.RequestResponseSubscriptionId)
                return;
            end
            message.unsubscribe(obj.RequestResponseSubscriptionId);
            obj.RequestResponseSubscriptionId = [];
        end

        function unsubscribePropertyChange(obj)
            if isempty(obj.ContentPropertyChangeListener)
                return;
            end
            delete(obj.ContentPropertyChangeListener);
            obj.ContentPropertyChangeListener = [];
        end

        function unsubscribeNotifications(obj)
            if isempty(obj.NotificationSubscriptionId)
                return;
            end
            message.unsubscribe(obj.NotificationSubscriptionId);
            obj.NotificationSubscriptionId = [];
        end
    end
end

function assertScalar(obj)
% assertScalar Check that Document is scalar.
    matlab.desktop.editor.EditorUtils.assertScalar(obj);
end

function text = transposeColumnCharVector(text)
% transposeColumnCharVector Check that input text is 1-by-n or n-by-1 char
% vector. If it is column vector then transpose it to row vector.
    matlab.desktop.editor.EditorUtils.assertChar(text, 'TEXT');
    if iscolumn(text)
        text = transpose(text);
    end
end

function assertOpen(obj)
% assertOpen Check that Document is open.
    matlab.desktop.editor.EditorUtils.assertOpen(obj, 'DOCUMENT');
end

function assertEditable(obj)
% assertEditable Check that Document is editable.
    assert(all([obj.Editable]), message('MATLAB:Editor:Document:Uneditable'));
end

function assertLessEqualInt32Max(input, variablename)
% assertLessEqualInt32Max Check that input number is not greater than maximum of 32-bit integer.
    matlab.desktop.editor.EditorUtils.assertLessEqualInt32Max(input, variablename);
end

function assertPositiveLessEqualInt32Max(input, variablename)
% assertPositiveLessEqualInt32Max Check that input number is positive and not greater than maximum of 32-bit integer.
    matlab.desktop.editor.EditorUtils.assertPositiveLessEqualInt32Max(input, variablename);
end

function match = matchname(fname)
%MATCHNAME Return first open Document with file name containing fname.

    match = createEmptyReturnValue;
    editors = matlab.desktop.editor.MotwEditorDocument.getAllOpenEditors;

    partialMatchedEditors = {};
    for i = 1:length(editors)

        currentname = editors(i).Filename;
        [~, currentFileName, currentFileExt] = fileparts(currentname);

        % If filename with extension matched, (e.g. C:\myFile.m with myFile.m),
        % then return it
        if ~isempty(currentname) && isequal([currentFileName currentFileExt], fname)
            match = editors(i);
            return
        end

        % If filename without extension matched, (e.g. C:\myFile.m with myFile),
        % then return it
        if ~isempty(currentname) && isequal(currentFileName, fname)
            match = editors(i);
            return
        end

        % If the part of the filename matches the current filename,
        % then collect the list of partially matched editors
        if ~isempty(currentname) && contains(currentname, fname)
            partialMatchedEditors{end+1} = editors(i); %#ok<AGROW>
        end
    end

    % Return the first item in partially matched editor list
    if ~isempty(partialMatchedEditors)
        match = partialMatchedEditors{1};
    end

end

function emptyDocs = createEmptyReturnValue
%createEmptyReturnValue Return 1x0 empty Document array.
    emptyDocs = matlab.desktop.editor.MotwEditorDocument.empty(1,0);
end

function obj = getMotwEditorDocumentObj(appContainerDocument)
%getMotwEditorDocumentObj Return MotwEditorDocument object if appContainerDocument
%is not empty else return empty document array.
    if isempty(appContainerDocument)
        obj = createEmptyReturnValue;
    else
        obj = matlab.desktop.editor.MotwEditorDocument(appContainerDocument);
    end
end

function tf = isAbsolutePath(filename)
%isAbsolutePath Test if specified file name is absolute.
    tf = matlab.desktop.editor.EditorUtils.isAbsolute(filename);
end

function obj = openEditorViaFunction(filename, mustExist)
%openEditorViaFunction Helper method for openEditor and openEditorForExistingFile.
    assert(isAbsolutePath(filename), ...
           message('MATLAB:Editor:Document:PartialPath', filename));
    acobj = findOpenAppContainerDocument(filename);
    if ~isempty(acobj)
        obj = getMotwEditorDocumentObj(acobj);
        obj.makeActive;
        return;
    end
    if mustExist && ~isfile(filename)
        obj = createEmptyReturnValue;
        return;
    end
    [~, ~, fileExtension] = fileparts(filename);
    obj = createAndAddAppContainerDocumentToRootApp(filename, fileExtension(2:end));
end

function obj = promptToOpenUntitledDocument(questionMessage)
    dialogQuestion = getString(questionMessage);
    dialogTitle = getString(message('MATLAB:Editor:Document:MATLABEditorTitle'));
    dialogYes = getString(message('MATLAB:Editor:Document:DialogYes'));
    dialogNo = getString(message('MATLAB:Editor:Document:DialogNo'));
    shouldCreateUntitledDocument = questdlg(dialogQuestion, dialogTitle, dialogYes, dialogNo, dialogYes);
    if strcmp(shouldCreateUntitledDocument, dialogYes)
        obj = matlab.desktop.editor.MotwEditorDocument.new('');
    else
        obj = createEmptyReturnValue;
    end
end

function val = clampInf(input)
    val = max(min(input, intmax), intmin);
end

function validateResponse(response, obj, arguments)
    assert(isnumeric(response.status));

    % 0 = success
    switch response.status
        case 1
            error(message('MATLAB:Editor:Document:ReadonlyPosition'));
        case 2
            error(message('MATLAB:Editor:Document:InaccessiblePosition'));
        case 3
            error(message('MATLAB:Editor:Document:NonexistentPosition'));
        case 4
            error(message('MATLAB:Editor:Document:SaveFailedUntitledBuffer', ...
                getFilenameForSaveError(obj, arguments)));
        case 5
            error(message('MATLAB:Editor:Document:SaveFailedReadOnly', ...
                getFilenameForSaveError(obj, arguments)));
        case 6
            error(message('MATLAB:Editor:Document:SaveFailedPermissionDenied', ...
                getFilenameForSaveError(obj, arguments)));
        case 7
            error(message('MATLAB:Editor:Document:SaveFailedUnknown', ...
                getFilenameForSaveError(obj, arguments)));
    end
end

function filename = getFilenameForSaveError(obj, arguments)
    if isempty(arguments)
        filename = obj.Filename; % save
    else
        filename = arguments{1}; % save as
    end
end

function rtcId = getRtcId(obj)
    rtcId = obj.AppContainerDocument.Content.RtcId;
end

function MO = getRootApp
    MO = matlab.ui.container.internal.RootApp.getInstance();
end

function editorGroup = getEditorGroup()
    MO = getRootApp();
    editorGroup = MO.getEditorGroup();
    assert(~isempty(editorGroup), message('MATLAB:Editor:Document:EmptyEditorGroup'));
end

function acdoc = findOpenAppContainerDocument(filename)
    canonicalFilePath = matlab.desktop.editor.EditorUtils.getCanonicalPath(filename);
    MO = getRootApp();
    acdoc = MO.getDocument(getEditorGroup().Tag, canonicalFilePath);
    if ~isempty(acdoc) && isClosed(acdoc)
        acdoc = [];
    end
end

function tf = isClosed(appContainerDocument)
    tf = ~isvalid(appContainerDocument);
end

function tf = isContentAvailable(appContainerDocument)
    tf = ~isempty(appContainerDocument.Content) && ~isstring(appContainerDocument.Content);
end

function tf = isRtcIdAvailable(obj)
    tf = isContentAvailable(obj.AppContainerDocument) && isfield(obj.AppContainerDocument.Content, 'RtcId') && ~isempty(getRtcId(obj)) && getRtcId(obj) ~= "";
end

function tf = isWaitingToInitialize(appContainerDocument)
    tf = ~isempty(appContainerDocument.Content) && ~isfield(appContainerDocument.Content, 'WaitToInitialize') || appContainerDocument.Content.WaitToInitialize;
end

function tf = isValidDocumentGroupTag(documentGroupTag)
    tf = strcmp(documentGroupTag, getEditorGroup().Tag);
end

function obj = createAndAddAppContainerDocumentToRootApp(filename, fileExtension)
    arguments
        filename (1,:) char = ''
        fileExtension (1,:) char = ''
    end
    isUntitled = isempty(filename);
    isFileExists = ~isUntitled && isfile(filename);
    content = struct( ...
        'Filename', filename, ...
        'FileExtension', fileExtension, ...
        'IsUntitled', isUntitled, ...
        'IsMATLABApiRequest', true, ...
        'ShowErrorDialogs', true, ...
        'IsFileExists', isFileExists, ...
        'WaitToInitialize', false ...
    );
    metadata = getFileMetadata(filename, fileExtension);
    if ~isempty(metadata)
        content.Metadata = metadata;
    end

    MO = getRootApp();
    import matlab.ui.container.internal.appcontainer.*;
    acdoc = Document();
    acdoc.DocumentGroupTag = getEditorGroup().Tag;
    acdoc.Tag = filename;
    acdoc.Content = content;
    if ~isUntitled
        [~, name, ext] = fileparts(filename);
        acdoc.Title = strcat(name, ext);
    end
    MO.add(acdoc);
    obj = getMotwEditorDocumentObj(acdoc);
end
