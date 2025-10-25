classdef AppDesignEnvironment < handle
    % APPDESIGNENVIRONMENT  Launches the App Designer
    %
    %    This class manages App Designer related settings, like index url,
    %    NameSpace, and dependent MATLAB services, like RTC, Debug.
    %    This class will launch App Designer browser window, and will open
    %    an app if App Designer already launched
    
    %    Copyright 2013-2023 The MathWorks, Inc.
    
    properties (Access = private)
        % the App Designer browser window controller
        AppDesignerWindowController
        
        % listener to the AppDesignerWindowController being destroyed
        WindowControllerDestroyedListener
        
        StartupParameters
    end
    
    properties
        % the BrowserController to launch App Deisgner in
        %
        % This should be set if you want App Designer to launch with a
        % specifc Browser in mind
        %
        % By default, use CEF
        BrowserControllerFactory appdesservices.internal.peermodel.BrowserControllerFactory;
        
        % the model holding all environment, settings, context,
        % etc... about App Designer	needed when starting up
        % Todo: when using backgroundPool in AysncTask, will make this 
        % to be able to use AsyncTask.fetch() to get the result
        StartupStateModel appdesigner.internal.application.startup.StartupStateModel;
        
        % the model holding settings for App Designer startup screen
        StartScreenStateModel appdesigner.internal.application.startup.StartScreenStateModel;
    end
    
    properties (SetAccess = private, ...
            GetAccess = public)
        % the App Designer model
        AppDesignerModel
    end
    
    properties (Constant)
        % URLs for different App Designer modes
        ReleaseUrl = 'toolbox/matlab/appdesigner/web/index.html'
        DebugUrl = 'toolbox/matlab/appdesigner/web/index-debug.html'
    end
    
    % XXX Methods called externally. Example clients of these methods:
    %
    % - appdesigner.internal.application.openAppDetails
    % - App Designer documentation
    % - appdesigner_debug and appdesigner commands
    methods
        function startAppDesigner(obj, startupParameters)
            % STARTAPPDESIGNER start App Designer
            %
            % If call this method without arguments, will just launching
            % App Designer with opening a default app
            %
            % The optional arguments:
            %    'FileName' -> App to open when launching App Designer
            %    'URL' -> URL to use when launching App Designer
            %    'NewApp' -> Struct with data about type of new app to create
            %       struct.Type - type of app to create (e.g. appdesigner.internal.serialization.app.AppTypes.StandardApp)
            %       struct.<app type specific features> (e.g. SimulinkModelName for Simulink apps)
            %    'Tutorial' -> Tutorial to open
            %    'ShowAppDetails' -> When opening an app, show the App Details dialog.
            %       This parameter assumes that a filename was also passed.
            %    'Visible' -> If App Designer should open visible or not
            arguments
                obj
                startupParameters.FileName char = ''
                startupParameters.URL char = appdesigner.internal.application.AppDesignEnvironment.ReleaseUrl
                startupParameters.NewApp struct = struct.empty;
                startupParameters.Tutorial char = ''
                startupParameters.ShowAppDetails logical = false;
                startupParameters.Visible logical = true;
            end
            
            if obj.isAppDesignerWindowOpen()
                % App Designer is already open so bring to front
                obj.AppDesignerWindowController.bringToFront();
            else
                obj.cleanupWindowController();
                
                % create Connection for AppDesignerWindowController
                pathToWebPage = convertStringsToChars(startupParameters.URL);
                connection = appdesservices.internal.peermodel.Connection(pathToWebPage);
                
                obj.StartupParameters = startupParameters;
                
                % create the AppDesignerWindowController which will launch App Designer
                % browser window
                obj.AppDesignerWindowController = appdesigner.internal.application.AppDesignerWindowController( ...
                    obj.AppDesignerModel, connection);
                
                % listen to when the AppDesignerWindowController is destroyed which means
                % the App Designer is closed by the users
                obj.WindowControllerDestroyedListener = addlistener(obj.AppDesignerWindowController,'ObjectBeingDestroyed', ...
                    @(source, event)delete(obj));
                
                % Start
                serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();
                obj.BrowserControllerFactory = serviceProvider.BrowserControllerFactory;

                obj.AppDesignerWindowController.startBrowser(obj.BrowserControllerFactory, ...
                    'Visible', startupParameters.Visible);
                
                % Create start screen needed setting
                obj.initializeStartScreenState();
            end
        end
        
        function requestToCloseAppDesigner(obj)
            obj.AppDesignerWindowController.requestToClose();
        end

        function val = isAppDesignerOpen(obj)
            val = obj.isAppDesignerWindowOpen();
        end

        function runAsyncStartupTasks(obj)
            import appdesigner.internal.async.AsyncTask;
            
            adapterMap = obj.getComponentAdapterMap();
            function asyncGetComponentAdapterMap()
                if isvalid(obj) && isvalid(obj.AppDesignerModel) ...
                        && isempty(adapterMap)
                    obj.AppDesignerModel.setComponentAdapterMap(appdesigner.internal.appmetadata.getProductionComponentAdapterMap());
                end
            end
            if isempty(adapterMap) 
                % todo: when AysncTask turns to use backgroundPool(), will pass the
                % instance of AsyncTask into AppDesignerModel for it to call into
                % fetch() to get the result.
                % for now, this task is put into IQM as the first one, so when loadApp
                % feval request comes in, it would be added to the queue, which would
                % ensure component adapters map running ealier.
                AsyncTask(@asyncGetComponentAdapterMap).run();
            end
            
            function asyncInitStartupState()
                if isvalid(obj)
                    % Async funciton may run after App Designer is closed
                    obj.initializeStartupState();
                end
            end            
            AsyncTask(@asyncInitStartupState).run();
            
            function asyncInitializeMATLABServices()
                if isvalid(obj)
                    % Async funciton may run after App Designer is closed
                    obj.initializeMATLABServices();
                end
            end            
            AsyncTask(@asyncInitializeMATLABServices).run();
        end
        
        function initializeStartScreenState(obj)
            % Initialize start screen data
            obj.StartScreenStateModel = appdesigner.internal.application.startup.StartScreenStateModel();
            obj.StartScreenStateModel.initialize(obj.StartupParameters);
        end
        
        function initializeStartupState(obj)            
            % Initialize all the startup data            
            serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();
            startupStateProviders = serviceProvider.StartupStateProviderFactory.createStartupStateProviders();
            
            obj.StartupStateModel = appdesigner.internal.application.startup.StartupStateModel(startupStateProviders);
            obj.StartupStateModel.initialize(obj.StartupParameters);
        end
        
        function createNewApp(obj, appType, appFeatures)
            %  CREATENEWAPP Opens a new app in App Designer
            %
            %   createNewApp() will bring to front/launch App Designer
            %       and create a new Standard blank, unsaved app
            %
            %   appType - type of app to create (e.g appdesigner.internal.serialization.app.AppTypes.StandardApp)
            %   appFeatures - struct with additional data for creating the
            %      new app. Example: struct('SimulinkModelName', 'somemodel.slx')
            %      for standard apps that are associated with a Simulink model.

            arguments
                obj
                appType = appdesigner.internal.serialization.app.AppTypes.StandardApp
                appFeatures = struct
            end

            appFeatures.Type = appType;

            if obj.isAppDesignerWindowOpen()
                obj.AppDesignerWindowController.bringToFront();
                obj.AppDesignerModel.createNewApp(appFeatures);
            else
                % If it isn't open, start app designer. It has a new app
                % by default so don't need to create a new one.

                obj.startAppDesigner('NewApp', appFeatures);
            end
        end

        
        function observer = openApp(obj, filePath, nameValueArgs)
            %  OPENAPP Open the app in App Designer
            %
            %   openApp() will bring bring to front or launch App Designer
            %       and open the app if the file path is not empty
            arguments
                obj
                filePath
                nameValueArgs.Visible logical = true
            end
            
            assert(~isempty(filePath), 'filePath should not be empty');
            
            if obj.isAppDesignerWindowOpen()
                obj.AppDesignerWindowController.bringToFront();
                obj.AppDesignerModel.openApp(filePath);
            else
                obj.startAppDesigner('FileName', filePath, 'Visible', nameValueArgs.Visible)
            end

            % Look for an existing app model with the requested filename
            appModel = findobj(obj.AppDesignerModel.Children, 'FullFileName', filePath, '-depth', 1);

            if nargout == 1
                if ~isempty(appModel)
                    observer = appdesigner.internal.application.observer.AppOpenObserver(obj.AppDesignerModel.CompletionObserver, appModel);
                else
                    observer = appdesigner.internal.application.observer.AppOpenObserver(obj.AppDesignerModel.CompletionObserver);
                end
            end
        end
        
        function openTutorial(obj, tutorialName, appToOpen)
            %  OPENTUTORIAL Opens the tutorial specified by tutorialName
            %
            %   openTutorial() will bring to front or launch App Designer
            %       and bring to front or start the tututorial.
            arguments
                obj,
                tutorialName,
                appToOpen = '';
            end
            
            assert(~isempty(tutorialName), 'tutorialName should not be empty');
            
            if obj.isAppDesignerWindowOpen()
                obj.AppDesignerWindowController.bringToFront();
                obj.AppDesignerModel.openTutorial(tutorialName, appToOpen);
            else
                if isempty(appToOpen)
                    obj.startAppDesigner('Tutorial', tutorialName);
                else
                    obj.startAppDesigner('FileName', appToOpen, 'Tutorial', tutorialName);
                end
            end
        end
        
        function openAppDetails(obj, filePath)
            %  OPENAPPDETAILS Open the app in App Designer and show the App Details dialog
            %
            %   openAppDetails() will bring to front or launch App Designer
            %       and open the app showing app details if the file path is not empty
            
            assert(~isempty(filePath), 'filePath should not be empty');
            
            if obj.isAppDesignerWindowOpen()
                obj.AppDesignerWindowController.bringToFront();
                obj.AppDesignerModel.openAppDetails(filePath);
            else
                obj.startAppDesigner('FileName', filePath, 'ShowAppDetails', true);
            end
        end
    end
    % XXX End of externally used methods
    
    methods
        function obj = AppDesignEnvironment(appDesignerModel)
            
            narginchk(1,1);
            
            obj.StartupParameters = struct;
            
            obj.AppDesignerModel = appDesignerModel;
        end
        
        function delete(obj)
            obj.cleanupWindowController();
        end
        
        function componentAdapterMap = getComponentAdapterMap(obj)
            componentAdapterMap = obj.AppDesignerModel.ComponentAdapterMap;
        end
        
        function setComponentAdapterMap(obj, componentAdapterMap)
            % AppDesignEvironment now gets ComponentAdapterMap in background taske
            % queue as part of our App Designer startup performance work.
            % If we do not start App Designer before calling into 
            % appdesigner.internal.application.getAppDesignEnvironment, we may have
            % no chance to get component adapter map, for instance,
            % 1) Comparison API: appdesigner.internal.comparison.getAppData calls 
            % into Deserializer directly
            % 2) appdesignerqe.mlappinfo calls into appdesigner.internal.application.loadApp
            % Provide this API for setting compoentAdapterMap externally in such a scenario
            % Todo: when it's able to use backgroundPool from AsyncTask, we
            % can refactor this.
            obj.AppDesignerModel.setComponentAdapterMap(componentAdapterMap);
        end
    end
    
    methods (Access = private)
        
        function isOpen = isAppDesignerWindowOpen(obj)            
            isOpen = ...
                ...% Exists?
                ~isempty(obj.AppDesignerWindowController) && ...
                ... % Isn't deleted
                isvalid(obj.AppDesignerWindowController) && ...
                ... Double check the window is still valid
                obj.AppDesignerWindowController.IsWindowValid;                                             
        end
        
        function cleanupWindowController(obj)
            
            if ~isempty(obj.WindowControllerDestroyedListener)
                delete(obj.WindowControllerDestroyedListener);
                obj.WindowControllerDestroyedListener = [];
            end
            
            if ~isempty(obj.AppDesignerWindowController) ...
                    && isvalid(obj.AppDesignerWindowController)
                % The object would be empty if not calling
                % startAppDesigner()
                % If the user hits 'X' to close App Designer,
                % AppDesignerWindowController would already be destroyed
                delete(obj.AppDesignerWindowController);
            end
        end
        
        function initializeMATLABServices(obj)
            if appdesservices.internal.util.MATLABChecker.isJavaDesktop()
                % com.mathworks.services.clipboardservice.ConnectorClipboardService
                % should only be called for Java Desktop, not for JSD or MO.
                try
                    % Start the connector clipboard service to allow interaction
                    % with the system clipboard
                    com.mathworks.services.clipboardservice.ConnectorClipboardService.getInstance();
                catch me
                    % This is temporary until a way to conditionally initialize
                    % the ClipboardService is implemented.
                    backtraceState = warning('QUERY', 'BACKTRACE').state;
                    warning('OFF', 'BACKTRACE');
                    warning("Unable to load connector clipboard service.");
                    warning(backtraceState, 'BACKTRACE');
                end
            end
                
            % Start Inspector so that it can handshake with client            
            internal.matlab.inspector.peer.InspectorFactory.getInstance();
        end
    end
end
