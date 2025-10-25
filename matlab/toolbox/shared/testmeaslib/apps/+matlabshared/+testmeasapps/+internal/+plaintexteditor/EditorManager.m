classdef EditorManager < matlabshared.testmeasapps.internal.ITestable
%EDITORMANAGER manages the creation and lifetime of the Publisher and
%Subscriber class, and the Code Generation Utility class. It exposes
%public API's that can be used to create and interact with a
%MATLAB-based editor.

% Copyright 2021-2024 The MathWorks, Inc.

    properties
        % The unique client ID associated with the JS editor. Every JS
        % editor will have a unique client ID, so that the changes will be
        % made to only the JS editor instance associated with the unique
        % client ID.
        ClientID (1, 1) string

        % The connector URL that hosts the server containing the JS editor.
        % This URL can be used as a UIHTML object's HTMLSource. This will`
        % render the JS editor in the UIHTML.
        URL (1, 1) string
    end

    properties (Dependent)
        % The limit for the number of characters in a comment line. Words
        % exceeding this limit will go to the next comment line
        CommentLength
    end

    properties (Dependent, SetAccess = {?matlabshared.testmeasapps.internal.ITestable})
        % Flag to check whether the Connector Messaging Framework is ready.
        PubSubReady

        % Flag to show whether the editor is read-only.
        EditorReadOnly

        % Flag that indicates whether the editor has been rendered.
        EditorReady
    end

    properties (Constant, Hidden)
        % The full path to the HTML page that contains the JS editor.
        ReleaseFilePath = "toolbox/shared/testmeaslib/apps/plaintexteditor.html"

        % The full path to the HTML page used for debugging the JS editor.
        DebugFilePath = "toolbox/shared/testmeaslib/apps/plaintexteditor-debug.html"

        % Plain Text Editor ID tag - Denotes beginning of the ClientID
        PTEIDTag = "pteid"

        % End ID Tag - denotes the end of the ClientID
        EndIDTag = "endid"
    end

    properties (Access = {?matlabshared.testmeasapps.internal.ITestable})
        % The handle to the script-generating builder class.
        ScriptBuilder

        % The handle to the Connector Pub-Sub class responsible for sending
        % and receiving messages to/from MATLAB and JS.
        PubSubMessageHandler

        % The mode to run the editor in. Default runs in release mode. The
        % mode can be passed in as an input argument to the Editor Manager
        % class.
        Mode (1, 1) string {mustBeMember(Mode, ["release", "debug"])} = "release"

        % The listener for any changes to the TextToPublish property of
        % EditorManager. Its handler publishes the text to the Editor.
        TextToPublishListener = event.listener.empty

        % Handler for whenever the read-only state changes. The current
        % editor text contents are used to update the ScriptBuilder's
        % text contents.
        SetReadOnlyStateChangedListener = event.listener.empty

        % Max Client ID value
        MaxIDValue (1, 1) double {mustBeInteger, mustBeGreaterThan(MaxIDValue, 1)} = 50000
    end

    properties (Dependent, Hidden, ...
                SetAccess = {?matlabshared.testmeasapps.internal.ITestable})
        Channel
    end

    properties (SetObservable, ...
                Access = {?matlabshared.testmeasapps.internal.ITestable})
        % Setting this property with "text" will add "text" to the
        % existing editor.
        TextToPublish (1, 1) string
    end

    %% Lifetime
    methods
        function obj = EditorManager(varargin)
            narginchk(0, 1);

            if nargin == 1
                obj.Mode = varargin{1};
            end

            obj.ScriptBuilder = ...
                matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder();

            % Create the MATLAB connector URL link.
            [url, clientID] = getHTMLFileURLAndID(obj);

            obj.PubSubMessageHandler = ...
                matlabshared.testmeasapps.internal.plaintexteditor.PubSubMessageHandler(clientID);

            objWeakRef = matlab.lang.WeakReference(obj);
            obj.TextToPublishListener = listener(obj, ...
                                                 "TextToPublish", "PostSet", @(varargin)objWeakRef.Handle.publishTextFcn(varargin{:}));

            obj.SetReadOnlyStateChangedListener = listener(obj.PubSubMessageHandler, ...
                                                           "Text", "PostSet", @(varargin)objWeakRef.Handle.readOnlyStateChangeFcn(varargin{:}));

            obj.ClientID = clientID;
            obj.URL = url;
        end

        function delete(obj)

            obj.ClientID = "";
            obj.URL = "";
            delete(obj.TextToPublishListener);
            delete(obj.SetReadOnlyStateChangedListener);

            % Clear the pub-sub handler
            obj.PubSubMessageHandler = [];
            obj.ScriptBuilder = [];
        end
    end

    %% Public-APIs
    methods
        function addComment(obj, comment)
        % Add a comment to the JS editor.

            arguments
                obj
                comment (1, 1) string
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addComment(comment) + newline;
        end

        function addSectionHeader(obj, sectionHeaderText)
        % Add a comment to the JS editor.

            arguments
                obj
                sectionHeaderText (1, 1) string
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addSectionHeader(sectionHeaderText) + newline;
        end

        function addNewLine(obj)
        % Add a newline to the JS editor.

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addNewLine();
        end

        function addSpaces(obj, numberOfSpaces)
        % Add spaces to the given line (Can be useful for formatting).
        % numberOfSpaces = 1 by default

            arguments
                obj
                numberOfSpaces = 1
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.insertSpaces(numberOfSpaces);
        end

        function addCodeWithSemicolon(obj, code)
        % Add a line of code to the JS editor. A semicolon is
        % automatically appended to the line of text of not originally
        % provided.

            arguments
                obj
                code (1, 1) string
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addCodeLineWithSemiColon(code) + newline;
        end

        function addCodeWithoutSemicolon(obj, code)
        % Add a line of code to the JS editor, without a semicolon.
        % This can be used for generating lines of code like "clear",
        % "return", "continue", etc which are not followed by a
        % semicolon.

            arguments
                obj
                code (1, 1) string
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addCodeLine(code) + newline;
        end

        function addCodeLineTruncatedWithSemicolon(obj, code)
        % Add a line of code to the JS editor. A semicolon is
        % automatically appended to the line of text of not originally
        % provided.

            arguments
                obj
                code (1, 1) string
            end

            obj.validateEditorReadOnly();
            obj.TextToPublish = obj.ScriptBuilder.addCodeLineTruncatedWithSemicolon(code) + newline;
        end

        function clearText(obj)
        % Clears the the JS editor.

            obj.validateEditorReadOnly();
            obj.ScriptBuilder.clearText();
            obj.PubSubMessageHandler.publish( ...
                matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum.CLEAR_EDITOR, true);
        end

        function text = getText(obj)
        % Returns the current contents of the JS editor.

            obj.validateEditorReadOnly();
            text = obj.ScriptBuilder.getText();
        end

        function text = setText(obj, text)
        % Set the editor contents with "text". The existing text gets
        % overwritten with the new "text".

            obj.validateEditorReadOnly();
            text = obj.ScriptBuilder.setText(text) + newline;
            obj.PubSubMessageHandler.publish( ...
                matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum.SET_EDITOR_TEXT, text);
        end

        function setEditorReadOnly(obj, val)
        % Enables or disables read-only status of the JS editor. If
        % editor is in read-only mode already, we do not need to get
        % the updated text from the JS side. If editor is not
        % read-only, we need to wait for the JS side to give us the
        % updated editor content before we return from this function.

            arguments
                obj
                val (1, 1) logical
            end

            if val == obj.EditorReadOnly
                return
            end

            obj.PubSubMessageHandler.publish( ...
                matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum.SET_READONLY, ...
                val);

            waitfor(obj.PubSubMessageHandler, "EditorReadOnly", val);
        end

        function createMFile(obj)
        % Move the current editor contents to an M-file. The generated
        % M-file is auto indented.

            obj.validateEditorReadOnly();
            obj.ScriptBuilder.createMFile();
        end

        function createMLXFile(obj)
        % Move the current editor contents to an MLX-file. The
        % generated MLX-file is auto indented.

            obj.validateEditorReadOnly();
            obj.ScriptBuilder.createMLXFile();
        end
    end

    %% Helper Methods
    methods (Access = {?matlabshared.testmeasapps.internal.ITestable})
        function [htmlFileURL, clientID] = getHTMLFileURLAndID(obj)
        % Get the MATLAB connector URL and client ID. Use the
        % matlab.net.URI() API to create a custom URI, using the path
        % to the editor files, and Query Parameters like a unique
        % clientID.

            if obj.Mode == "release"
                editorfilepath = obj.ReleaseFilePath;
            else
                editorfilepath = obj.DebugFilePath;
            end

            % Create a unique client ID using randi. The clientID is of the
            % format "PTE<random-number>". E.g. PTE4878.
            clientID = "PTE" + string(randi(obj.MaxIDValue));

            % Create a URI instance.
            editorURI = matlab.net.URI();

            % Create custom query parameters by adding the unique client ID
            % to the PTEIDTag, and an EndTag.
            editorURI.Query = matlab.net.QueryParameter(obj.PTEIDTag, clientID);
            editorURI.Query(end+1) = matlab.net.QueryParameter(obj.EndIDTag, "");

            % Provide the path to the html files.
            editorURI.Path = editorfilepath;

            % Get the final https URL using the URI generated.
            htmlFileURL = connector.getHttpsUrl(editorURI.EncodedURI);
        end

        function publishTextFcn(obj, ~, ~)
        % The handler for whenever there is a change in the Generate
        % Script Util text content. This automatically updates the JS
        % editor code content.

        % Publish the code content to the JS editor.
            publish(obj.PubSubMessageHandler, ...
                    matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum.ADD_TEXT, ...
                    obj.TextToPublish);
        end

        function readOnlyStateChangeFcn(obj, ~, ~)
        % The handler for when the editor read-only status changes from
        % not-read-only to read-only. The script builder util text
        % needs to be updated to the contents of the editor window.

            obj.ScriptBuilder.setText(obj.PubSubMessageHandler.Text);
        end

        function validateEditorReadOnly(obj)
        % Throw if the editor is not in the read-only mode.

            if ~obj.EditorReadOnly
                throwAsCaller(MException(message("shared_testmeaslib_apps:plaintexteditor:EditorReadOnly")));
            end
        end
    end

    %% Getters and Setters
    methods
        function val = get.PubSubReady(obj)
            val = obj.PubSubMessageHandler.PubSubReady;
        end

        function val = get.EditorReady(obj)
            val = obj.PubSubMessageHandler.EditorReady;
        end

        function val = get.EditorReadOnly(obj)
            val = obj.PubSubMessageHandler.EditorReadOnly;
        end

        function val = get.CommentLength(obj)
            val = obj.ScriptBuilder.CommentLength;
        end

        function set.CommentLength(obj, val)
            obj.ScriptBuilder.CommentLength = val;
        end

        function val = get.Channel(obj)
            val = obj.PubSubMessageHandler.Channel;
        end
    end
end
