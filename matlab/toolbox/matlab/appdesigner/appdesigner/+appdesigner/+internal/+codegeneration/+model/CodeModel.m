classdef CodeModel < handle & appdesigner.internal.model.AbstractAppDesignerModel
    %CodeModel  Server-side representation of code data from the client

    % Copyright 2015-2024 The MathWorks, Inc.

    properties (Transient)
        % the class name of the App
        ClassName;

        % a 1xN struct array of ui component callbacks
        Callbacks;

        % the startup function structure
        StartupCallback;

        % n x 1 cell array
        EditableSectionCode;

        % the input parameters to the app.
        InputParameters;

        % the string enum representing singleton mode
        SingletonMode

        % struct with dynamic data dependent on app type
        AppTypeData;

        % struct array of bindings
        Bindings

        % an property to access the generated code
        GeneratedCode
    end

    methods
        function obj = CodeModel(appModel, proxyView)
            % constructor

            % create an empty structure for the callbacks, and startupFcn
            obj.Callbacks = struct.empty;
            obj.StartupCallback = struct.empty();
            obj.EditableSectionCode = {};
            obj.AppTypeData = struct;
            obj.Bindings = struct.empty();

            if (nargin > 0)
                % assign this object to the App Model handle
                appModel.CodeModel = obj;

                appType = 'Standard';

                % allow tests to not need metadata model construted.
                if ~isempty(appModel.MetadataModel)
                    appType = appModel.MetadataModel.AppType;
                end

                % instantiate a controller
                obj.createController(proxyView, appType);
            end
        end

        function sendGoToLineColumnEventToClient(obj, line, column, scrollToView, selectLine, message)
            % send gotoLineColumn peerEvent to CodeModel on client side
            % TODO: this function needs to be refactored/moved. It is
            % necessary for code realted functionality but is not related
            % to code data
            obj.Controller.ClientEventSender.sendEventToClient('goToLineColumn', ...
                {'Line', line,...
                'Column', column,...
                'SelectLine', selectLine,...
                'ScrollToView', scrollToView,...
                'Message', message});
        end
    end

    methods(Access = public)
        function controller = createController(obj,  proxyView, appType)
            % Creates the controller for this Model.  this method is the concrete implementation of the
            % abstract method from appdesigner.internal.model.AbstractAppDesignerModel
            controller = appdesigner.internal.codegeneration.controller.CodeDataController(obj, proxyView, appType);
            controller.populateView(proxyView);
        end

        function setDataOnSerializer(obj, serializer)
            % Sets the data on the serializer to be serialized
            serializer.MatlabCodeText =  obj.GeneratedCode;
            serializer.EditableSectionCode = obj.EditableSectionCode;
            serializer.Callbacks = obj.Callbacks;
            serializer.StartupCallback = obj.StartupCallback;
            serializer.InputParameters = obj.InputParameters;
            serializer.SingletonMode = obj.SingletonMode;
            serializer.AppTypeData = obj.AppTypeData;
            serializer.Bindings = obj.Bindings;
        end
    end

end
