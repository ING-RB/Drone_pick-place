classdef (Hidden, Sealed) RtcEditorDocument < matlab.desktop.editor.DocumentInterface
%matlab.desktop.editor.RtcEditorDocument Access document in RTC based Editor.
%   This class is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2019-2023 The MathWorks, Inc.

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
        LiveEditorClient;
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
    end

    methods (Access = private, Hidden = true)
        %RtcEditorDocument - Constructor for RtcEditorDocument class.
        %   OBJ = RtcEditorDocument(LIVEEDITORCLIENT)
        function obj = RtcEditorDocument(LiveEditorClient)
            assert(~isempty(LiveEditorClient), ...
                   message('MATLAB:Editor:Document:EmptyEditor'));
            obj.LiveEditorClient = LiveEditorClient;
            obj.RtcId = char(LiveEditorClient.getRichTextComponent.getDocument.getUniqueKey);

            connector.ensureServiceOn;
            obj.NotificationSubscriptionId = message.subscribe(strcat(obj.ApiMessageNotificationChannelPrefix, obj.RtcId), @obj.notifyEvent);
        end

        function notifyEvent(obj, msg)
            notify(obj, msg.eventName);
        end

        function ensureRtcReady(obj)
            import matlab.desktop.editor.RtcEditorState;
            timeElapsed = 0;
            while obj.IsRtcReady == RtcEditorState.UNKNOWN
                if timeElapsed >= obj.MaxCommunicationWaitTime
                    obj.unsubscribe();
                    break;
                else
                    if ~obj.LiveEditorClient.isOpen
                        obj.unsubscribe();
                        obj.IsRtcReady = RtcEditorState.DESTROYED;
                    elseif obj.LiveEditorClient.getRichTextComponent.getDocument.isLoaded
                        obj.IsRtcReady = RtcEditorState.CREATED;
                    else
                        matlab.internal.yield;
                        pause(obj.DelayTime);
                        timeElapsed = timeElapsed + obj.DelayTime;
                    end
                end
            end
            assert(obj.IsRtcReady == RtcEditorState.CREATED, ...
                message('MATLAB:Editor:Document:OpenLoadTimeout'));
        end

        function result = performActionSync(obj, action, varargin)
            obj.ensureRtcReady;

            connector.ensureServiceOn;
            obj.RequestResponseSubscriptionId = message.subscribe(strcat(obj.ApiMessageResponseChannelPrefix, obj.RtcId), @(msg) handleResponse(msg));
            timeElapsed = 0;
            if nargin < 3
                arguments = '';
            else
                arguments = varargin;
            end
            messageToPublish.action = action;
            messageToPublish.arguments = arguments;
            message.publish(strcat(obj.ApiMessageRequestChannelPrefix, obj.RtcId), messageToPublish);
            response = {};
            while isempty(response) && iscell(response)
                if timeElapsed >= obj.MaxCommunicationWaitTime
                    obj.unsubscribeRequestResponse();
                    error(message('MATLAB:Editor:Document:PerformActionTimeout', action));
                elseif ~obj.LiveEditorClient.isOpen
                    obj.unsubscribe();
                    error(message('MATLAB:Editor:Document:EditorClosed'));
                else
                    matlab.internal.yield;
                    pause(obj.DelayTime);
                    timeElapsed = timeElapsed + obj.DelayTime;
                end
            end

            obj.unsubscribeRequestResponse();
            validateResponse(response);
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
                liveEditorClient = getEditorClientForFile(fileNameToJavaFile(fname));
                obj = getRtcEditorDocumentObj(liveEditorClient);
            else
                % This indicates that fname is a relative path.
                obj = matchname(fname);
                if isempty(obj)
                    obj = createEmptyReturnValue;
                end
            end
        end

        function obj = openEditor(filename)
        %openEditor Attempt to open named file in Editor.
            if isfolder(filename)
                obj = promptToOpenUntitledDocument(filename);
            else
                obj = openEditorViaFunction(filename, @(file)openUsingOpenFileInAppropriateEditor(file), false);
            end
        end

        function obj = openEditorForExistingFile(filename)
        %openEditorForExistingFile Open named file in Editor.
            [filepath, name, ext] = fileparts(filename);
            if strcmp(ext, '.p')
                filename = fullfile(filepath, strcat(name, '.m'));
            end
            obj = openEditorViaFunction(filename, @(file)openUsingOpenFileInAppropriateEditor(file), true);
        end
    end

    %% Static accessor methods
    % matlab.desktop.editor uses these methods to obtain information
    % about existing documents. Because the return type is a Document
    % object, these methods must access the constructor.
    methods (Static, Hidden)
        function objs = getAllOpenEditors
        %getAllOpenEditors Return list of all open Documents.
            connector.ensureServiceOn;
            editorGroup = com.mathworks.mde.liveeditor.LiveEditorGroup.getInstance;
            editorClients = awtinvoke(editorGroup, 'getOpenLiveEditorClients');
            editors = editorClients.toArray();
            if numel(editors) == 0
                objs = createEmptyReturnValue;
            else
                objs = arrayfun(@getRtcEditorDocumentObj, editors);
            end
        end

        function obj = getActiveEditor
        %getActiveEditor Return Document object for active MATLAB Editor.
            connector.ensureServiceOn;
            liveEditorApplication = matlab.desktop.editor.EditorUtils.getLiveEditorApplication;
            liveEditorClient = liveEditorApplication.getLastActiveLiveEditorClient;
            obj = getRtcEditorDocumentObj(liveEditorClient);
        end

        function obj = new(bufferText)
        %NEW Create new document containing the specified text and return Document
        %object, which references that untitled object.
            connector.ensureServiceOn;
            liveEditorApplication = matlab.desktop.editor.EditorUtils.getLiveEditorApplication;
            liveEditorClient = liveEditorApplication.newPlainCodeLiveEditorClient;
            obj = getRtcEditorDocumentObj(liveEditorClient);
            if ~isempty(obj) && ~isempty(bufferText)
                obj.Text = bufferText;
            end
        end
    end

    %% Public instance methods
    methods
        function save(obj)
        %save Save Document text to disk.
            assertOpen(obj);
            for x = 1:numel(obj)
                if ~getBackingStore(obj(x)).isPersistenceLocationSet
                    errorMessage = processMessageWithFilename(getMessageString('MATLAB:Editor:Document:SaveFailedUntitledBuffer', obj(x).Filename));
                elseif getBackingStore(obj(x)).isReadOnly
                    errorMessage = processMessageWithFilename(getMessageString('MATLAB:Editor:Document:SaveFailedReadOnly', obj(x).Filename));
                else
                    errorMessage = callMethodAndHandleException('saveWithoutErrorDialog', obj(x).LiveEditorClient);
                    filename = obj(x).Filename;
                    clear(filename);
                    fschange(filename);
                end
                assert(isempty(errorMessage), 'MATLAB:Editor:Document:SaveFailed', errorMessage);
            end
        end

        function saveAs(obj, filename)
        %saveAs Save Document text to disk using specified file name.
            assertScalar(obj);
            assertOpen(obj)
            % If this is an .mlx file and the target file is not, we use
            % the export API. Otherwise we fall back to regular saveAs.
            if matlab.desktop.editor.EditorUtils.isLiveCodeFile(obj.Filename) && ...
              ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(filename)
                matlab.desktop.editor.internal.exportDocumentByID(obj.RtcId, filename);
            else
                errorMessage = callMethodAndHandleException('saveAs', obj.LiveEditorClient, filename);
                assert(isempty(errorMessage), 'MATLAB:Editor:Document:SaveAsFailed', errorMessage);
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
            assertOpen(obj);
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
            for x = 1:numel(obj)
                callMethodAndHandleExceptionEDT('closeClient', com.mathworks.mlservices.MatlabDesktopServices.getDesktop, obj(x).LiveEditorClient); %#ok<*JAPIMATHWORKS>
                obj(x).unsubscribe();
            end
        end

        function closeNoPrompt(obj)
        %closeNoPrompt Close document in Editor, discarding unsaved changes.
            for x = 1:numel(obj)
                callMethodAndHandleExceptionEDT('closeNoPrompt', obj(x).LiveEditorClient);
                obj(x).unsubscribe();
            end
        end

        function reload(obj)
        %RELOAD Revert to saved version of Editor document.
            assertOpen(obj);
            for x = 1:numel(obj)
                status = obj(x).performActionSync('Reload');
                assert(islogical(status) && status, message('MATLAB:Editor:Document:ReloadFailed', obj(x).Filename));
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
            obj.LiveEditorClient.bringToFront;
        end

        function newObjs = setdiff(newObjsList, originalObjList)
        %setdiff Compare lists of Editor Documents.
            newObjs = createEmptyReturnValue;
            for i = 1:numel(newObjsList)
                currentNewEditor = newObjsList(i);
                if ~ismember(currentNewEditor, originalObjList,'legacy')
                    newObjs(end+1) = currentNewEditor; %#ok<AGROW>
                end
            end
        end

        function filename = get.Filename(obj)
            if obj.Opened
                filename = char(obj.LiveEditorClient.getLiveEditor.getLongName);
            else
                filename = '';
            end
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
            import matlab.desktop.editor.RtcEditorState;
            if obj.IsRtcReady == RtcEditorState.DESTROYED || ~obj.LiveEditorClient.isOpen
                isopen = false;
                return;
            end
            obj.ensureRtcReady;
            isopen = logical(obj.IsRtcReady);
        end

        function bool = get.Modified(obj)
            assertOpen(obj);
            bool = obj.performActionSync('GetModified');
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
                        je2 = obj2(x).LiveEditorClient;
                    else
                        je2 = obj2.LiveEditorClient;
                    end
                    bool(x) = obj1(x).LiveEditorClient == je2;
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
        end

        function unsubscribeRequestResponse(obj)
            if isempty(obj.RequestResponseSubscriptionId)
                return;
            end
            message.unsubscribe(obj.RequestResponseSubscriptionId);
            obj.RequestResponseSubscriptionId = [];
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

    match = '';
    editors = matlab.desktop.editor.RtcEditorDocument.getAllOpenEditors;

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
    emptyDocs = matlab.desktop.editor.RtcEditorDocument.empty(1,0);
end

function obj = getRtcEditorDocumentObj(liveEditorClient)
%getRtcEditorDocumentObj Return RtcEditorDocument object if liveEditorClient
%is not empty else return empty document array
    if isempty(liveEditorClient)
        obj = createEmptyReturnValue;
    else
        obj = matlab.desktop.editor.RtcEditorDocument(liveEditorClient);
    end
end

function F = fileNameToJavaFile(filename)
%fileNameToJavaFile Convert string file name to java.io.File object.
    F = java.io.File(filename);
end

function tf = isAbsolutePath(filename)
%isAbsolutePath Test if specified file name is absolute.
    javaFile = fileNameToJavaFile(filename);
    tf = javaMethod('isAbsolute', javaFile);
end

function messageString = getMessageString(messageId, varargin)
%getMessageString Get localized message string from messageId.
    messageString = getString(message(messageId, varargin{:}));
end

function message = processMessageWithFilename(messageWithFilename)
%processMessageWithFilename Convert single backslash to double backslash.
%For use with the error function.
    message = regexprep(char(messageWithFilename), '\', '\\\');
end

function message = callMethodAndHandleExceptionEDT(jMethod, obj, varargin)
    message = '';
    try
        javaMethodEDT(jMethod, obj, varargin{:});
    catch e
        message = handleJavaException(e);
    end
end

function message = callMethodAndHandleException(jMethod, obj, varargin)
    message = '';
    try
        javaMethod(jMethod, obj, varargin{:});
    catch e
        message = handleJavaException(e);
    end
end

function message = handleJavaException(e)
    if(isa(e,'matlab.exception.JavaException'))
        ex = e.ExceptionObject;
        assert(isjava(ex));
        message = processMessageWithFilename(ex.getLocalizedMessage);
    else
        rethrow(e);
    end
end

function liveEditorClient = openUsingOpenFileInAppropriateEditor(javaFile)
%openUsingOpenFileInAppropriateEditor Helper method for using the
%LiveEditorApplication.openLiveEditorClient java method to open a file and
%return the Editor instance for the file if one exists since
%openFileInAppropriateEditor does not return an editor interface.
    connector.ensureServiceOn;
    import com.mathworks.mde.editor.EditorUtils
    EditorUtils.openFileInAppropriateEditor(javaFile);
    liveEditorClient = getEditorClientForFile(javaFile);
end

function liveEditorClient = getEditorClientForFile(javaFile)
    connector.ensureServiceOn;
    import com.mathworks.mde.editor.EditorUtils
    canonicalFile = EditorUtils.getCanonicalFile(javaFile);
    liveEditorApplication = matlab.desktop.editor.EditorUtils.getLiveEditorApplication;
    fileStorageLocation = matlab.desktop.editor.EditorUtils.fileNameToStorageLocation(canonicalFile);
    liveEditorClient = javaMethodEDT('findLiveEditorClient', liveEditorApplication, fileStorageLocation);
end

function obj = openEditorViaFunction(filename, openMethod, mustExist)
%openEditorViaFunction Helper method for openEditor and openEditorForExistingFile.
    assert(isAbsolutePath(filename), ...
           message('MATLAB:Editor:Document:PartialPath', filename));

    javaFile = fileNameToJavaFile(filename);

    if (mustExist && ~javaFile.exists)
        % Calling the open method throws an exception, but we just want to
        % return an empty Document array.
        liveEditorClient = [];
    else
        liveEditorClient = openMethod(javaFile);
    end
    obj = getRtcEditorDocumentObj(liveEditorClient);
end

function obj = promptToOpenUntitledDocument(folderpath)
    folderpath = fileparts(folderpath);
    dialogQuestion = getMessageString('MATLAB:Editor:Document:CannotOpenDirectory', folderpath);
    dialogTitle = getMessageString('MATLAB:Editor:Document:MATLABEditorTitle');
    dialogYes = getMessageString('MATLAB:Editor:Document:DialogYes');
    dialogNo = getMessageString('MATLAB:Editor:Document:DialogNo');
    shouldCreateUntitledDocument = questdlg(dialogQuestion, dialogTitle, dialogYes, dialogNo, dialogYes);
    if strcmp(shouldCreateUntitledDocument, dialogYes)
        obj = matlab.desktop.editor.RtcEditorDocument.new('');
    else
        obj = createEmptyReturnValue;
    end
end

function bs = getBackingStore(obj)
    bs = obj.LiveEditorClient.getLiveEditor.getBackingStore;
end

function val = clampInf(input)
    val = max(min(input, intmax), intmin);
end

function validateResponse(response)
    assert(isnumeric(response.status));

    % 0 = success
    switch response.status
      case 1
        error(message('MATLAB:Editor:Document:ReadonlyPosition'));
      case 2
        error(message('MATLAB:Editor:Document:InaccessiblePosition'));
      case 3
        error(message('MATLAB:Editor:Document:NonexistentPosition'));
    end
end
