classdef CodeDataController < appdesservices.internal.interfaces.controller.AbstractController
    %CodeDataController Controller for the code model data
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties (Access = private)
        AppType

        PropertiesSetListener
    end
    
    methods
        function obj = CodeDataController(model, proxyView, appType)
            % constructor for the controller
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(model, [], proxyView);
            
            % AppType stored for determining how to save apptypedata
            obj.AppType = appType;

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                % Set up propertiesSet event listener
                obj.PropertiesSetListener = addlistener(proxyView.PeerNode, 'propertiesSet', ...
                    obj.wrapLegacyProxyViewPropertiesChangedCallback(@obj.handlePropertiesChanged));
            end
            
            % notify the client that this controller has been
            % instantiated. Some code generation activity has already
            % occured by the time this is instantiated.
            eventData.Name = 'codeDataControllerCreated';
            viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent( ...
                proxyView.PeerNode, 'peerEvent', eventData);
        end
    end
    
    methods(Access = protected)
        function handleEvent(obj, ~, event)
            % handler for peer node events from the client
            
            import appdesigner.internal.codegeneration.compareGeneratedCodeToFileCode
            
            switch event.Data.Name
                case 'compareCodeToFile'
                    compareGeneratedCodeToFileCode(obj.Model.GeneratedCode, ...
                        event.Data.AppFilePath, event.Data.OriginalRelease, event.Data.CurrentRelease);
                    
                case 'syncCustomCode'
                    obj.updateCodeData(event.Data.CodeData);
            end
        end
        
        function getPropertiesForView(~, ~)
            % No-Op implemented for Base Class
        end
    end
    
    methods(Access = ?appdesigner.internal.controller.AppController)
        function updateCodeData(obj, codeData)
            % Sync the incoming custom user code into the code model, this
            % has two entry points, app model save (all fields present), or
            % the sync of custom code data client event, which will only
            % contain the editable custom section and callback collections.
            
            if ~isempty(codeData)
                if isfield(codeData, 'ComponentCallbackData')
                   obj.updateComponentCallbacks(codeData.ComponentCallbackData);
                end
                
                if isfield(codeData, 'EditableCodeData')
                    obj.updateEditableCustomCode(codeData.EditableCodeData);
                end
                
                if isfield(codeData, 'AppTypeData')
                    obj.updateAppTypeData(codeData.AppTypeData);
                end
                
                if isfield(codeData, 'GeneratedCode') && ~isempty(codeData.GeneratedCode)
                    obj.updateGeneratedCode(codeData.GeneratedCode);
                end

                if isfield(codeData, 'Bindings')
                    obj.updateBindings(codeData.Bindings);
                end
            end
        end
    end
    
    properties (Constant, Access = private)
        StartupTypeID = 'AppStartupFunction'
    end
    
    methods (Access = private)
        function updateComponentCallbacks(obj, data)
            % The user has just saved the app.  Synchronize all of the
            % callbacks bound to ui components of the app (and startupfcn)
            
            obj.Model.StartupCallback = struct.empty;
            obj.Model.Callbacks = struct.empty();
            
            % now recreate the startupFcn and callbacks
            idx = 0;
            for i = 1:length(data)
                if(strcmp(data(i).Type, obj.StartupTypeID))
                    obj.Model.StartupCallback(1).Name = data(i).Name;
                    obj.Model.StartupCallback(1).Code = data(i).Code;
                else
                    % its a regular callback
                    idx = idx+1;
                    obj.Model.Callbacks(idx).Name = data(i).Name;
                    obj.Model.Callbacks(idx).Code = data(i).Code;
                end
            end
        end
        
        function updateAppTypeData(obj, data)
            % update the apptypedata structure to be saved to disk.
            % Because this property is dynamic based on the type of app
            % being created we create and go through a synchronizer.
            
            synchronizer = appdesigner.internal.codegeneration.apptypedatasynchronizer...
                .AppTypeDataSynchronizerFactory.createAppTypeDataSynchronizer(obj.AppType);
            
            synchronizer.syncAppTypeData(obj.Model, data);
        end
        
        function updateEditableCustomCode(obj, data)
            % Update the editable custom block of code. This can be empty.
            
            if ~isempty(data)
                if iscell(data)
                    % handle client-side events that are cell arrays
                    code = data;
                else
                    code = {data.Code}';
                end
     
                obj.Model.EditableSectionCode = code;
            end
        end
        
        function updateGeneratedCode(obj, codeData)
            % Sync the generated app code to code model
            
            obj.Model.GeneratedCode = codeData;
        end

        function updateBindings(obj, bindings)
            obj.Model.Bindings = bindings;
        end
    end
end
