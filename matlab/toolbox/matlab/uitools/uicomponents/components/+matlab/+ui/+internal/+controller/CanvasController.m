classdef CanvasController < matlab.graphics.mixin.Mixin

    % CanvasController A Controller mixin
    %
    % This should be mixed-in by any Controller that is capable of hosting
    % a Canvas
    %
    % This includes all container - based Controllers, such as Panels,
    % GridLayout, Figure, etc...
    %

    % Copyright 2022-2024 The MathWorks, Inc.

    properties(Transient)

        % A matlab.graphics.primitive.canvas.HTMLCanvas
        %
        % When this container does not have any graphics objects as its
        % children, then Canvas is empty
        Canvas

        % Listeners for Window Events
        WindowUUIDClosedListener
        WindowUUIDChangedListener;
    end

    methods
        function set.Canvas( obj,canvas )
            obj.Canvas = canvas;

            updateSceneChannel(obj);
        end

        function delete(obj)
            delete(obj.WindowUUIDChangedListener);
            delete(obj.WindowUUIDClosedListener);
        end
    end

    methods (Access='protected')

        function updateSceneChannel(obj)
            % CanvasController.m communicates with CanvasController.js
            % through the container's ViewModel
            %
            % When a Canvas is set, it interrogates various Canvas
            % properties like if a Binary Channel is available, and gets
            % environmental variables like what versions of webGL are
            % running

            binaryChannelID = '';

            if isempty(obj.Canvas)
                % We have no grapics present
                serverID = '';
                useBinaryChannel = false;
            else
                % We do have graphics
                serverID = obj.Canvas.ServerID;
                useBinaryChannel = strcmp(obj.Canvas.BinaryChannelAvailable,'on');

                [rootController, windowUUID] = getRootWindowProperties(obj);

                if(isempty(windowUUID))
                    binaryChannelID = '';
                else
                    binaryChannelID = string(windowUUID);
                    obj.Canvas.BinaryChannelID = binaryChannelID;
                end

                % sprintf("CanvasController: BinaryChannelID is ''\n")

                % If the root controller supports window events, add
                % listeners
                %
                % TODO: This logic can also be consolidated with moving
                % getRootWindowProperties() to an interface
                if(any(events(rootController) =="WindowUUIDChanged"))
                    if(~isempty(obj.WindowUUIDClosedListener))
                        % stop listening to old windows
                        delete(obj.WindowUUIDClosedListener)
                    end

                    if(~isempty(obj.WindowUUIDChangedListener))
                        % stop listening to old windows
                        delete(obj.WindowUUIDChangedListener)
                    end

                    obj.WindowUUIDChangedListener = addlistener(rootController, 'WindowUUIDChanged', ...
                        @(src, event) handleWindowUUIDChanged(obj, src, event));

                    obj.WindowUUIDClosedListener = addlistener(rootController, 'WindowUUIDClosed', ...
                        @(o,~)handleWindowDestroyed(obj, binaryChannelID));
                end
            end

            % 'none' error check mode is default
            webglErrorCheckMode = 0;
            errorCheckModeStr = getenv('WEBGL_ERRORCHECKMODE');
            if strcmp(errorCheckModeStr, '1')
                webglErrorCheckMode = 1;
            elseif strcmp(errorCheckModeStr, '2')
                webglErrorCheckMode = 2;
    	    end

            % Pass the SwiftShader mode to the client
            swiftShaderMode = 2; % default
            swiftShaderEnv = getenv('USE_SWIFTSHADER');
            if(strcmp(swiftShaderEnv, '0'))
                swiftShaderMode = 0;
            elseif (strcmp(swiftShaderEnv, '1'))
                swiftShaderMode = 1;
            end

            % Set Values for CanvasController.js to use
            if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
                props = struct;

                props.ServerID = serverID;
                props.UseBinaryChannel = useBinaryChannel;
                % We no longer honor the WebGL version feature flag, RendererVersion will only be default (0)
                props.RendererVersion = 0;
                props.WebGLErrorCheckMode = webglErrorCheckMode;
                props.SwiftShaderMode = swiftShaderMode;

                obj.ViewModel.setProperties(props);
                
                % Given GBT's commit strategy, we have to manually commit to ensure we dont end up with an open transaction (g3373257)
                viewModelManager = obj.ViewModel.getViewModelManager();
                if (strcmp(viewModelManager.getCommitStrategyType(), 'manual'))
                    % We rely on the Figure Controller to handle marking the
                    % model dirty. We could have a separate mechanism for
                    % CanvasController to decouple the two
                    rootController = obj;
                    while(~isempty(rootController.ParentController))
                        rootController = rootController.ParentController;
                    end

                    rootController.markModelDirty();
                end

                containerACTChannel = [];
                containerViewModelId = '';
                currentController = obj;

                while isempty(containerACTChannel) && ~isempty(currentController)
                    containerACTChannel = currentController.ViewModel.getProperty('ReturnACTChannel');
                    containerViewModelId = currentController.ViewModel.getId();
                    currentController = currentController.ParentController;
                end

                % remove following line after fixing g1775560
                logText = jsonencode(struct(...
                    'LogType', 'Server', ...
                    'Source', 'CanvasController', 'Channel', "", ...
                    'Event', 'Setting Server Id', ...
                    'EventData', struct(....
                    'PeerId', obj.getPeerId(), ...
                    'ContainerACTChannel', containerACTChannel, ...
                    'ContainerViewModelId', containerViewModelId, ...
                    'ServerId', serverID) ...
                    )...
                    );

                matlab.graphics.internal.logger('log', 'DrawnowTimeout', logText)
            end
        end

        function id = getPeerId(obj)
            id = char(obj.ViewModel.Id);
        end

        function handleWindowUUIDChanged(obj, src, event)
            % disp('handleWindowUUIDChanged')
            updateSceneChannel(obj);
        end

        function handleWindowDestroyed(obj, binaryChannelID)
            % sprintf("CanvasController: Destroying Binary Stream %s", binaryChannelID)
            matlab.graphics.primitive.canvas.HTMLCanvas.destroyBinaryStream(binaryChannelID);
        end

        function [rootController, windowUUID] = getRootWindowProperties(obj)
            % To do:
            %
            % Move thisentire method to sommething like
            %
            %  controller.getWindowId()
            %
            % to create better encapsulation and stop having
            % CanvasController dig in so many internals
            rootController = obj;
            while(~isempty(rootController.ParentController))
                rootController = rootController.ParentController;
            end

            % Excluded classes are controllers that do not support getting
            % a window ID
            excludedClasses = [
                "appdesigner.internal.controller.AppController"
                ];

            isSupportedRoot = class(rootController) ~= excludedClasses;

            if(~isSupportedRoot)
                windowUUID = '';
            else
                windowUUID = rootController.getWindowUUID();
            end
        end
    end
end
