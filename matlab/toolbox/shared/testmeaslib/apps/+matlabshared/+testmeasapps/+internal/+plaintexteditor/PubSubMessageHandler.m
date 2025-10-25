classdef PubSubMessageHandler < matlabshared.testmeasapps.internal.ITestable

    %PUBSUBMESSAGEHANDLER manages the creation and lifetime of the pub-sub
    %connector channel responsible for sending/receiving messages to/from
    %the JS editor.

    % Copyright 2021 The MathWorks, Inc.

    properties
        % The connector message channel over which the pub-sub happens.
        Channel (1, :) char
    end

    properties (SetObservable, AbortSet)
        % Contains recent text updates received from the editor. This gets
        % updated only when the editor changes from non-read-only to
        % read-only.
        Text (1, 1) string
    end

    properties (Constant)
        DefaultChannel = "/testmeasapps/PlainTextEditor"

        % The delimiter separating the publishing action (e.g.
        % SET_READONLY) and the publishing message value (e.g. "true").
        % E.g. the publishing message for setting read-only property of the
        % JS-editor is "SET_READONLY_$$_true", where the delimiter "_$$_"
        % separates the action ("SET_READONLY") and the message ("true").
        PublisherDelimiter = "_$$_"

        % Javascript Messages to listen to on the MATLAB side.
        PubSubReadyMsg = "PubSubReady"
        EditorReadyMsg = "EditorReady"
        EditorDetailsMsg = "EditorDetails"
    end

    properties (SetAccess = {?matlabshared.testmeasapps.internal.ITestable})
        % Flag to denote whether the connector message service is running.
        PubSubReady (1, 1) logical = false

        % Flag that denotes the read-only state of the editor.
        EditorReady (1, 1) logical = false

        % Flag to check the read-only status of the JS editor. The editor
        % is editable by default.
        EditorReadOnly (1, 1) logical = false

        % The handle to the connector message subscriber.
        Subscriber

        % The text (code or comment) that is queued to be sent to the
        % Editor Window once we get the notification that the message
        % service has been established. This queued data is transferred
        % once the pub-sub functionality is ready. After the transfer, this
        % is cleared.
        QueuedText (1, 1) string
    end

    %% Lifetime
    methods
        function obj = PubSubMessageHandler(clientID, varargin)

            if ~isempty(varargin)
                connectorResponse = varargin{1};
            else
                connectorResponse = connector.ensureServiceOn();
            end

            if ~connectorResponse.running
                throwAsCaller(MException(message("shared_testmeaslib_apps:plaintexteditor:ConnectorNotRunning")));
            end

            % Prepare the channel
            channel = obj.DefaultChannel + clientID;
            obj.Channel = char(channel);
            if isempty(obj.Subscriber)
                obj.Subscriber = message.subscribe(obj.Channel, @(item)obj.subscriberMessageHandler(item));
            end
        end

        function delete(obj)

            % Unsubscribe from the connector channel.
            if ~isempty(obj.Subscriber)
                message.unsubscribe(obj.Subscriber);
            end

            obj.Subscriber = [];
        end
    end

    %% Public API
    methods
        function publish(obj, action, inputArgs)
            % Send a message via the publisher to the JS editor. If the
            % connector channel is not set-up, the publishing messages are
            % queued. These messages will be automatically published once
            % the connector pub-sub channel is established. NOTE - only the
            % last message for each action type is queued, all other
            % messages are discarded.

            arguments
                obj
                action (1, 1) matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum
                inputArgs
            end

            % If the Editor is ready, publish the message.
            if obj.EditorReady
                obj.publishAction(action, inputArgs);
            else
                % Queue the action and message if the editor is not ready.
                obj.queuePublisherAction(action, inputArgs)
            end
        end
    end

    %% Helper functions.
    methods (Access = {?matlabshared.testmeasapps.internal.ITestable})
        function queuePublisherAction(obj, action, msg)
            % When the editor is not ready, queue the action and message.

            arguments
                obj
                action (1, 1) matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum
                msg
            end

            import matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum
            switch action
                case EditorActionEnum.SET_READONLY
                    obj.EditorReadOnly = msg;
                case EditorActionEnum.ADD_TEXT
                    obj.QueuedText = obj.QueuedText + msg;
                case EditorActionEnum.CLEAR_EDITOR
                    obj.QueuedText = "";
                case EditorActionEnum.SET_EDITOR_TEXT
                    obj.QueuedText = msg;
            end
        end

        function msg = publishAction(obj, action, msg)
            % Publish an action and the associated message over the
            % connector pub-sub channel to the JS editor.

            arguments
                obj
                action (1, 1) matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum
                msg
            end
            msg = string(action) + obj.PublisherDelimiter + string(msg);
            message.publish(obj.Channel, msg);
        end

        function subscriberMessageHandler(obj, msg)
            % Handler for messages received from the JS editor via the
            % pub-sub channel.

            import matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum
            if ~iscell(msg)
                return
            end

            command = string(msg{1});
            data = string(msg{2});
            switch command
                case obj.PubSubReadyMsg
                    % The connector pub-sub channel is now established.
                    % Send the message to launch the JS editor.

                    obj.PubSubReady = true;
                    publishAction(obj, EditorActionEnum.LAUNCH_EDITOR, "");

                case obj.EditorReadyMsg
                    obj.EditorReady = data == "true";

                    if obj.EditorReady
                        % Editor successfully launched.

                        obj.performEditorReadyActions();
                    end

                case obj.EditorDetailsMsg
                    readOnlyFlag = data(1) == "true";

                    % Update the Text property only if the state changed
                    % from non-read-only to read only, as users might have
                    % entered text into the editor in the non-read-only
                    % state that we need to update at our end.
                    if readOnlyFlag
                        obj.Text = data(2);
                    end

                    obj.EditorReadOnly = readOnlyFlag;
            end
        end

        function performEditorReadyActions(obj)
            % Send the queued commands over to the editor once it's
            % rendered.
            import matlabshared.testmeasapps.internal.plaintexteditor.EditorActionEnum

            publishAction(obj, EditorActionEnum.SET_READONLY, obj.EditorReadOnly);
            if obj.QueuedText ~= ""
                publishAction(obj, EditorActionEnum.SET_EDITOR_TEXT, obj.QueuedText);
                obj.QueuedText = "";
            end
        end
    end
end