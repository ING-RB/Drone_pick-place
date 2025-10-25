classdef AppDocument < handle ...
        & appdesservices.internal.interfaces.controller.AbstractControllerMixin

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Dependent)
        % Determine if the app has unsaved changes
        Modified

        % The full file name of the app
        FileName
    end

    properties (Access = private)
        AppModel
        AppController
    end

    methods (Access = private)
        function obj = AppDocument(appModel, appController)
            obj.AppModel = appModel;
            obj.AppController = appController;
            addlistener(obj.AppModel, 'ObjectBeingDestroyed', @(~, ~) delete(obj));
        end

        function component = getComponent(obj, componentCodeName)
            % Returns component with CodeName componentCodeName 

            % Get all components on UIFigure
            components = findall(obj.AppModel.UIFigure, '-property', 'DesignTimeProperties');

            % If no component is found, returns empty
            component = [];

            % Check if any component on UIFigure has CodeName componentCodeName
            for ix = 1:numel(components)
                codeName = components(ix).DesignTimeProperties.CodeName;
                if strcmp(codeName, componentCodeName)
                    component = components(ix);
                    break;
                end
            end
        end
        function saveFileIfNotExisted(obj)
            % Need to save app if app is not saved yet g2816389
            if(isempty(obj.AppModel.FullFileName))
                obj.saveAs([obj.AppModel.Name, '.mlapp']);
            end
        end
    end

    methods
        function save(obj)
            % Save the app in place

            fullFileName = obj.FileName;
            obj.saveAs(fullFileName);
        end

        function saveAs(obj, fullFileName)
            % Save the app with a new filename

            [~, ~, ext] = fileparts(fullFileName);

            if ~strcmp(ext, '.mlapp')
                error('Extension must be .mlapp');
            end

            saveObserver = obj.AppController.saveApp(fullFileName);

            % SaveResult property will be populated by the listener
            % attached to the completion observer.
            waitfor(saveObserver, 'Status');

            % If the save failed, there will be an exception we can throw
            % to inform the caller of the error.
            status = saveObserver.Status;
            exception = saveObserver.Exception;

            if strcmpi(status, 'error')
                throw(exception);
            end
        end

        function bringToFront(obj)
            % Brings the app tab to front in App Designer.
            obj.AppController.setActiveApp();
        end

        function close(obj)
            % Close the app, prompting to save it if it has unsaved changes
            obj.AppController.closeApp(obj.FileName, false);
        end
        
        function closeNoPrompt(obj)
            % Close the app without displaying a prompt to save the app if
            % it has unsaved changes
            obj.AppController.closeApp(obj.FileName, true);
            delete(obj);
        end

        function val = get.Modified(obj)
            val = obj.AppModel.IsDirty;
        end

        function set.Modified(~, ~)
        end

        function val = get.FileName(obj)
            val = obj.AppModel.FullFileName;
        end

        function set.FileName(~, ~)
        end

        function tf = hasComponent(obj, componentCodeName, parentComponentCodeName)
            % Assesses whether a component exists in app with CodeName componentCodeName
            % parentComponentCodeName is optional parameter. This also checks whether the component is a child of the parentComponent

            component = obj.getComponent(componentCodeName);
            % Check if component exists
            tf = ~isempty(component);

            % Check if component exists and if parentComponentCodeName argument was passed  
            if tf && nargin == 3 
                tf = strcmp(component.Parent.DesignTimeProperties.CodeName, parentComponentCodeName);
            end
        end

        function tf = hasProperty(obj, propName, accessType)
            % Assesses whether app has property with name propName and access accessType

            % Assume false
            tf = false;

            obj.saveFileIfNotExisted();

            reader = appdesigner.internal.serialization.FileReader(obj.FileName);
            code = reader.readMATLABCodeText();
            code = strsplit(code, '\n');
            % Remove first and last lines for parser
            code = code(:, 2:end-1);

            % Parsing user code to check for properties
            codeStructs = appdesigner.internal.application.parseUserCode(strjoin(code, '\n'));
            for idx = 1:length(codeStructs)
                codeStruct = cell2mat(codeStructs(idx));
                if(strcmp(codeStruct.Access, accessType) && strcmp(codeStruct.Type, 'PROPERTIES'))
                    itemsCell = codeStruct.Items;
                    properties = [cell2mat(itemsCell).Property];
                    tf = any(strcmp({properties(:).Name}, propName));
                    if(tf)
                        break;
                    end
                end
            end
        end

        function tf = hasCallback(obj, callbackFcnName)
            % Assesses whether a callback function exists with name callbackFcnName

            codeModel = obj.AppModel.CodeModel;

            % Check if callbacks exist
            if(~isempty(codeModel.Callbacks))
                callbacks = {codeModel.Callbacks.Name}
                tf = any(strcmp(callbacks, callbackFcnName));
            else
                tf = false;
            end
        end

        function value = getComponentPropertyValue(obj, componentCodeName, propertyName)
            % Returns value of property propertyName of component with CodeName componentCodeName

            component = obj.getComponent(componentCodeName);

            % Check if componentCodeName and propertyName are valid
            if(~isempty(component) && isprop(component, propertyName))
                value = component.(propertyName);
            else
                error(message('MATLAB:appdesigner:appdocument:InvalidComponentOrProperty'));
            end
        end

        function runningAppProxy = runApp(obj)
            % Starts a hidden running app instance of open app

            appArguments = [];

            % Clean up code for when running app is deleted
            function cleanRunningAppReference(appModel)
                appModel.RunningApp = [];
            end

            obj.saveFileIfNotExisted();

            % Runs app and assigns RunningApp in AppModel
            obj.AppModel.RunningApp = appdesigner.internal.service.AppManagementService.runApp(obj.AppModel.FullFileName, appArguments);
            obj.AppModel.RunningApp.UIFigure.Visible = 'off';
            addlistener(obj.AppModel.RunningApp, 'ObjectBeingDestroyed', @(src, e)cleanRunningAppReference(obj.AppModel));

            % Instantiate runningAppProxy
            runningAppProxy = appdesigner.internal.document.RunningAppProxy(obj.AppModel.RunningApp);
        end

        function tf = isAppRunning(obj)
            % Checks whether a running app instance exists
            tf = ~isempty(obj.AppModel.RunningApp);
        end
    end

    methods (Static, Access = private)
        function isADOpen = isAppDesignerOpen()
            isADOpen = false;

            appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment([], [], false);
            if isempty(appDesignEnvironment) || ~isvalid(appDesignEnvironment) || ~appDesignEnvironment.isAppDesignerOpen()
                return;
            end

            isADOpen = true;
        end

    end

    methods (Static)
        function document = open(fileName, nameValueArgs)
            % Opens the passed app in App Designer 
            % if called without output argument, send open app request without waiting for openning the app in the client side
            % if called with output argument, returns an AppDocument instance describing the app.
            % This method blocks until the app has fully initialized in App
            % Designer, which may take a long time if the app has lots of
            % components.
            arguments
                fileName
                nameValueArgs.Visible logical = true
            end

            fullFileName = appdesigner.internal.application.getValidatedInputAppFileName(fileName);

            appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();

            % Launch the app
            %
            % Tracking the app being open is done with the following:
            % - Retrieve an observer from the AppDesignerModel, which
            % will be notified when the app model is opened
            %
            % - When the model is opened, count the children of the
            % figure and wait for that many controllers to be created
            % DesignTimeComponentFactory will notify on a static
            % observer when that is done
            %
            % - Once all controllers are created, we can say that the
            % client-side code generation is done.  At that point, if
            % the dirty state is not initialized, wait for it to finish
            % initializing

            % Get an observer object that will have its 'AppModel'
            % property populated when the app is opened
            openObserver = appDesignEnvironment.openApp(fullFileName, 'Visible', nameValueArgs.Visible);

            % return without waiting for openning the app in the client side 
            if nargout == 0
                return;
            end

            % If the app is already open, the observer's AppModel property
            % will be populated.  Otherwise block until the app opens
            if isempty(openObserver.AppModel)
                waitfor(openObserver, 'AppModel');
            end

            appModel = openObserver.AppModel;

            appController = appModel.getController();

            document = appdesigner.internal.document.AppDocument(appModel, appController);
        end

        function closeAll()
            % Close all apps that are open in App Designer.  Does not
            % prompt to save any apps with unsaved changes.

            if appdesigner.internal.document.AppDocument.isAppDesignerOpen()
                docs = appdesigner.internal.document.AppDocument.getAllOpenApps();

                for idx = 1:length(docs)
                    docs(idx).closeNoPrompt();
                end
            end
        end

        function requestToCloseAppDesigner()
            % Closes App Designer.  This does not take any action to close
            % apps that are currently open.  If apps have unsaved changes,
            % they will display a prompt and abort the close.

            if appdesigner.internal.document.AppDocument.isAppDesignerOpen()
                appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();
                appDesignEnvironment.requestToCloseAppDesigner();
            end
        end

        function docs = getAllOpenApps()
            % Returns AppDocument instances for each app that is open in
            % App Designer.

            docs = appdesigner.internal.document.AppDocument.empty();

            if appdesigner.internal.document.AppDocument.isAppDesignerOpen()
                appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();

                appDesignerModel = appDesignEnvironment.AppDesignerModel;

                appModels = appDesignerModel.Children;
                docs = appdesigner.internal.document.AppDocument.empty(length(appModels), 0);

                for idx = 1:length(appModels)
                    appModel = appModels(idx);
                    docs(idx) = appdesigner.internal.document.AppDocument(appModel, appModel.getController());
                end
            end
        end

        function resetAppDesignerState(stateFile)
            % Closes all open files and opens stateFile
            % stateFile is a full file path
            appdesigner.internal.document.AppDocument.closeAll();

            % Check if stateFile exists before opening 
            if exist(stateFile, 'file') == 2

                % Create copy so that original stateFile doesn't get modified
                newFullFileName = fullfile(pwd, 'myapp.mlapp');
                appdesigner.internal.application.copyMLAPPFile(stateFile, newFullFileName);
                % Open stateFile app withtout wait
                % g2949329 this is used for onramp course, do not use waitfor opening app in client side
                % because waitfor blocks MATLAB worker for onramp course
                appdesigner.internal.document.AppDocument.open(newFullFileName);
            end
        end
 
        function setTrainingMode(tf)
            % set training Mode for online course, used by online course script.
            % if training mode is true, move uifigure in center in online course environment. g2815636
            persistent appCreationListener;
            if isempty(appCreationListener) || ~isvalid(appCreationListener)
                if tf
                    ams = appdesigner.internal.service.AppManagementService.instance();
                    appCreationListener = addlistener(...
                        ams, 'AppCreateComponentsExecutionCompleted',...
                        @(~,e)movegui(e.Figure, 'center'));
                end
            else
                if ~tf
                    delete(appCreationListener);
                end
            end
        end
    end

    methods(Static, Access = {?tAppDocument}, Hidden = true)
        function appDocument = createAppDocument(appModel)
            % Used to create an AppDocument with custom appModel for testing query APIs 
            appController = appModel.getController();
            appDocument = appdesigner.internal.document.AppDocument(appModel, appController);
        end
    end
end
