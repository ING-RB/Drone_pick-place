classdef (Hidden, Sealed) HeadlessEditorDocument < matlab.desktop.editor.DocumentInterface
%matlab.desktop.editor.HeadlessEditorDocument Access document in headless editor.
%   This class is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2021-2025 The MathWorks, Inc.

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
        WebWindow;
        RtcId;
        Visible = matlab.lang.OnOffSwitchState.off;
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
        OriginalWebWindowURL = [];
        OriginalMATLABWindowExitedCallback = [];
    end

    methods (Access = private, Hidden = true)
        %HeadlessEditorDocument - Constructor for HeadlessEditorDocument class.
        %   OBJ = HeadlessEditorDocument(FILENAME)
        function obj = HeadlessEditorDocument(filename, webWindow, options)
            arguments
                filename {mustBeTextScalar}
                webWindow matlab.internal.cef.webwindow
                options.useLiveCodeStandaloneApp (1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
            end
            obj.RtcId = replace(matlab.lang.internal.uuid, "-", "");
            cellOptions = namedargs2cell(options);
            obj.createHeadlessEditor(filename, webWindow, cellOptions{:})
        end

        function notifyEvent(obj, msg)
            notify(obj, msg.eventName);
        end

        function createHeadlessEditor(obj, filename, webWindow, options)
            arguments
                obj matlab.desktop.editor.HeadlessEditorDocument
                filename {mustBeTextScalar}
                webWindow matlab.internal.cef.webwindow
                options.useLiveCodeStandaloneApp (1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
            end
            import matlab.desktop.editor.RtcEditorState;

            obj.IsRtcReady = RtcEditorState.UNKNOWN;

            connector.ensureServiceOn;
            obj.RequestResponseSubscriptionId = message.subscribe(strcat(obj.ApiMessageResponseChannelPrefix, obj.RtcId), @(msg) handleReadyEvent(msg));
            obj.NotificationSubscriptionId = message.subscribe(strcat(obj.ApiMessageNotificationChannelPrefix, obj.RtcId), @obj.notifyEvent);

            cellOptions = namedargs2cell(options);
            url = createEditorURL(filename, obj.RtcId, cellOptions{:});
            if isWebWindowValid(webWindow)
                obj.OriginalWebWindowURL = webWindow.URL;
                obj.OriginalMATLABWindowExitedCallback = webWindow.MATLABWindowExitedCallback;
                webWindow.URL = url;
            else
                webWindow = matlab.internal.cef.webwindow(url, matlab.internal.getDebugPort);
                % Use a wider webwindow to prevent figures from shrinking when running the script
                % and remove horizontal scrollbar from the elements like live tasks.
                webWindow.Position = [0 0 1300 768];
            end

            obj.WebWindow = webWindow;
            obj.WebWindow.MATLABWindowExitedCallback = @(event, data) obj.closeNoPrompt();

            function handleReadyEvent(msg)                
                if ~strcmp(msg.actionPerformed, 'Ready')
                    return;
                end
                if msg.result
                    obj.IsRtcReady = RtcEditorState.CREATED;
                else
                    obj.IsRtcReady = RtcEditorState.DESTROYED;
                end
                obj.unsubscribeRequestResponse();
            end
        end

        function ensureRtcReady(obj)
            import matlab.desktop.editor.RtcEditorState;
            timeElapsed = 0;
            while obj.IsRtcReady == RtcEditorState.UNKNOWN
                if timeElapsed >= obj.MaxCommunicationWaitTime
                    obj.unsubscribe();
                    break;
                else
                    if ~isWebWindowValid(obj.WebWindow)
                        obj.unsubscribe();
                        obj.IsRtcReady = RtcEditorState.DESTROYED;
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
                elseif ~isWebWindowValid(obj.WebWindow)
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
        function obj = new(bufferText, webWindow)
            %NEW Create new document containing the specified text and return Document
            %object, which references that untitled object.
            obj = getHeadlessEditorDocumentObj(getUntitledBufferName(), webWindow);
            if ~isempty(obj) && ~isempty(bufferText)
                obj.Text = bufferText;
            end
        end

        function obj = openEditor(~)
            obj = createEmptyReturnValue;
            unsupportedFunction("openEditor");
        end

        function obj = openEditorForExistingFile(filename, webWindow)
            %openEditorForExistingFile Open named file in Editor.
            [filepath, name, ext] = fileparts(filename);
            if strcmp(ext, '.p')
                filename = fullfile(filepath, strcat(name, '.m'));
            end
            assert(isAbsolutePath(filename), ...
                message('MATLAB:Editor:Document:PartialPath', filename));
            isFileExist = isfile(filename);
            if ~isFileExist
                obj = createEmptyReturnValue;
                return;
            end

            obj = getHeadlessEditorDocumentObj(filename, webWindow);
        end
    end

    %% Static accessor methods
    % These methods are not supported for headless editors.
    methods (Static, Hidden)
        function objs = getAllOpenEditors
            objs = createEmptyReturnValue;
            unsupportedFunction("getAllOpenEditors");
        end

        function obj = getActiveEditor
            obj = createEmptyReturnValue;
            unsupportedFunction("getActiveEditor");
        end

        function obj = findEditor(~)
            obj = createEmptyReturnValue;
            unsupportedFunction("findEditor");
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
                catch ME
                    error('MATLAB:Editor:Document:SaveFailed', strrep(ME.message, '\', '\\'));
                end
            end
        end

        function saveAs(obj, filename)
            %saveAs Save Document text to disk using specified file name.
            assertScalar(obj);
            assertOpen(obj);
            assert(isAbsolutePath(filename), 'MATLAB:Editor:Document:SaveAsFailed', ...
                getMessageString('MATLAB:Editor:Document:NotAbsolutePath'));

            import matlab.desktop.editor.EditorUtils;
            import matlab.internal.livecode.FileModel;

            isSourceModified = obj.Modified;
            isSourceLiveCodeFile = EditorUtils.isLiveCodeFile(obj.Filename);
            isTargetLiveCodeFile = EditorUtils.isLiveCodeFile(filename);
            try
                if ~isSourceLiveCodeFile && ~isTargetLiveCodeFile
                    if isSourceModified
                        [fileID, errmsg] = fopen(filename, 'w');
                        assert(fileID >= 0, errmsg);
                        fprintf(fileID, obj.Text);
                        fclose(fileID);
                    else
                        clonefile(obj.Filename, filename);
                    end
                elseif ~isSourceLiveCodeFile && isTargetLiveCodeFile
                    if isSourceModified
                        fileModel = FileModel.convertTextToLiveCode(obj.Text, fileparts(obj.Filename), filename);
                    else
                        fileModel = FileModel.convertFileToLiveCode(obj.Filename, filename);
                    end
                    assert(~isempty(fileModel), message('MATLAB:Editor:Document:SaveFailedUnknown', filename));
                elseif isSourceLiveCodeFile
                    [~, ~, sourceExt] = fileparts(obj.Filename);
                    [~, ~, targetExt] = fileparts(filename);
                    switch lower(sourceExt)
                        case ".m"
                            if ~isSourceModified && strcmpi(targetExt, ".m")
                                clonefile(obj.Filename, filename);
                            else
                                obj.performActionSync('SaveAs', filename);
                            end
                        case ".mlx"
                            switch lower(targetExt)
                                case ".m"
                                    % saving to an M file
                                    mlxToMSaveAs(obj, filename);
                                case ".mlx"
                                    if isSourceModified
                                        obj.performActionSync('SaveAsLiveCode', filename);
                                    else
                                        % saving to an MLX file
                                        clonefile(obj.Filename, filename);
                                    end
                                otherwise
                                    % If the source is an MLX file and the target is not .m or .mlx, follow the export workflow
                                    result = matlab.desktop.editor.internal.exportDocumentByID(obj.RtcId, filename);
                                    assert(~isempty(result), message('MATLAB:Editor:Document:SaveFailedUnknown', filename));
                            end
                    end
                end
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
            assert(~any([obj.Modified]), message('MATLAB:Editor:Document:CloseFailed'));
            obj.closeNoPrompt();
        end

        function closeNoPrompt(obj)
            %closeNoPrompt Close document in Editor, discarding unsaved changes.
            import matlab.desktop.editor.RtcEditorState;
            for x = 1:numel(obj)
                obj(x).unsubscribe();
                if ~isempty(obj(x).OriginalWebWindowURL) && isWebWindowValid(obj(x).WebWindow)
                    obj(x).WebWindow.URL = obj(x).OriginalWebWindowURL;
                    obj(x).WebWindow.MATLABWindowExitedCallback = obj(x).OriginalMATLABWindowExitedCallback;
                else
                    obj(x).WebWindow.delete();
                end
                obj(x).IsRtcReady = RtcEditorState.DESTROYED;
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

        function makeActive(~)
            %makeActive Make document active in Editor.
            unsupportedFunction("makeActive");
        end

        function newObjs = setdiff(newObjsList, originalObjList)
            %setdiff Compare lists of Editor Documents.
            newObjs = createEmptyReturnValue;
            for x = 1:numel(newObjsList)
                currentNewEditor = newObjsList(x);
                if ~ismember(currentNewEditor, originalObjList,'legacy')
                    newObjs(end+1) = currentNewEditor; %#ok<AGROW>
                end
            end
        end

        function filename = get.Filename(obj)
            if obj.Opened
                filename = obj.performActionSync('GetFilename');
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
            if obj.IsRtcReady == RtcEditorState.DESTROYED || ~isWebWindowValid(obj.WebWindow)
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
                        je2 = obj2(x).RtcId;
                    else
                        je2 = obj2.RtcId;
                    end
                    bool(x) = strcmp(obj1(x).RtcId, je2);
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
            assertScalar(obj);
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
            assertScalar(obj);
            assertOpen(obj);
            if nargin > 3
                acknowledgeLineEnding = varargin{1}.AcknowledgeLineEnding;
            else
                acknowledgeLineEnding = false;
            end
            index = obj.performActionSync('PositionInLineToIndex', line, position, acknowledgeLineEnding);
        end

        function delete(obj)
            obj.closeNoPrompt();
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

function emptyDocs = createEmptyReturnValue
    %createEmptyReturnValue Return 1x0 empty Document array.
    emptyDocs = matlab.desktop.editor.HeadlessEditorDocument.empty(1,0);
end

function obj = getHeadlessEditorDocumentObj(filename, webWindow)
    %getHeadlessEditorDocumentObj Return HeadlessEditorDocument object if filename
    % is not empty else return empty document array.
    if isempty(filename)
        obj = createEmptyReturnValue;
    else
        obj = matlab.desktop.editor.HeadlessEditorDocument(filename, webWindow);
    end
end

function tf = isAbsolutePath(filename)
    %isAbsolutePath Test if specified file name is absolute.
    tf = matlab.desktop.editor.EditorUtils.isAbsolute(filename);
end

function messageString = getMessageString(messageId, varargin)
    %getMessageString Get localized message string from messageId.
    messageString = getString(message(messageId, varargin{:}));
end

function text = transposeColumnCharVector(text)
    % transposeColumnCharVector Check that input text is 1-by-n or n-by-1 char
    % vector. If it is column vector then transpose it to row vector.
    matlab.desktop.editor.EditorUtils.assertChar(text, 'TEXT');
    if iscolumn(text)
        text = transpose(text);
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

function tf = isWebWindowValid(webWindow)
    tf = ~isempty(webWindow) && webWindow.isvalid() && webWindow.isWindowValid();
end

function name = getUntitledBufferName()
    persistent bufferCounter;
    name = strcat('untitled', int2str(bufferCounter), '.m');
    if isempty(bufferCounter)
        bufferCounter = 2;
        return;
    end
    bufferCounter = bufferCounter + 1;
end

function clonefile(source, destination)
    copyfile(source, destination);
    attribs = '+w';
    if ispc
        attribs = strcat(attribs, ' -h');
    end
    fileattrib(destination, attribs);
end

function unsupportedFunction(fname)
    ME = MException("MATLAB:Editor:Document:UnsupportedFunction", "Function '%s' is not supported for headless editor document", fname);
    throwAsCaller(ME);
end
