classdef MessageHandler < handle
    %MESSAGEHANDLER   Base handler for audio recorder Online web messages
    %   This class handles the connector channel lifecycle and connector
    %   message delegation to subscribed callbacks.

    %   Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = {?matlab.unittest.TestCase})
        %StaticChannel
        %   The static part of connector channel used by a web module
        StaticChannel (1, 1) string

        %ClientId
        %   Randomly generated uuid to append to connector static channel
        ClientId (1, 1) string

        %PubSubChannel
        %   Actual connector channel used for communication composed of
        %   static channel and client id
        PubSubChannel (1, 1) string

        %Subscriber
        %   Subscriber to connector
        Subscriber

        %Subscriptions
        %   Map of server side subscriptions to client side action and
        %   callback
        Subscriptions

        %Subject
        %   The MATLAB web module that uses this message handler for
        %   connector communication
        Subject

    end

    methods
        function obj = MessageHandler(staticChannel)
            obj.StaticChannel = staticChannel;
            obj.initPubSubChannel();
            obj.attachToWebApp();
            obj.Subscriptions = containers.Map;
        end

        function setSubject(obj, subject)
            % Set the web module that uses this message handler
            obj.Subject = subject;
        end

        function subscribe(obj, action, callback)
            % Register a server side callback to a client side action
            arguments
                obj (1, 1) audiovideo.internal.audio.MessageHandler
                action (1, 1) string
                callback (1, 1) function_handle = @(msg)obj.Subject.(action)(msg)
            end
            obj.Subscriptions(action) = callback;
        end

        function unsubscribe(obj, action)
            % Remove a server side callback to a client side action
            if obj.Subscriptions.isKey(action)
                obj.Subscriptions.remove(action);
            end
        end

        function publish(obj, action, data)
            % Publish server command to client
            arguments
                obj (1, 1) audiovideo.internal.audio.MessageHandler
                action (1, 1) string
                data = ''
            end

            msg.action = action;
            msg.params = data;
            message.publish(obj.PubSubChannel, msg);
        end

        function delete(obj)
            % Disconnect from connector in destructor
            obj.detachFromWebApp();
        end
    end

    methods (Access = {?matlab.unittest.TestCase})

        function initPubSubChannel(obj)
            % Initialize a pub/sub channel string with uuid
            obj.ClientId = obj.generateClientId();
            obj.PubSubChannel = strcat(obj.StaticChannel, "/", obj.ClientId);
        end

        function clientId = generateClientId(~)
            % Generate a uuid as client id
            uuid = matlab.lang.internal.uuid;
            % Remove dashes in uuid
            clientId = strrep(uuid, '-', '');
        end

        function attachToWebApp(obj)
            % Subscribes to the web application communication channel
            if isempty(obj.Subscriber)
                obj.Subscriber = message.subscribe(obj.PubSubChannel, @(msg)obj.callbackHandler(msg));
            end
        end

        function detachFromWebApp(obj)
            % Unsubscribe from the connector messaging service
            message.unsubscribe(obj.Subscriber);
            obj.Subscriber = '';
        end

        function callbackHandler(obj, msg)
            % Handle client side commands
            feval(obj.Subscriptions(msg.action), msg.params);
        end
    end
end