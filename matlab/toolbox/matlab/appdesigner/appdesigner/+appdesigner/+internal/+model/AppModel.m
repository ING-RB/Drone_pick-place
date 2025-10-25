classdef AppModel < ...
        appdesigner.internal.model.AbstractAppDesignerModel & ...
        appdesservices.internal.interfaces.model.ParentingModel
    % The "Model" class of the App
    %
    % This class is responsible for managing the state of the App and
    % holding onto the App Figure Window.

    % Copyright 2013-2024 The MathWorks, Inc.

    properties
        % A handle to the figure, by default this is empty
        UIFigure = matlab.ui.Figure.empty();

        % Name of the AppModel, corresponds to the file name
        Name;

        % File location of the AppModel file
        FullFileName;

        % Plain text (m) or binary (mlapp)
        FileFormat = 'mlapp';

        CodeModel;

        % the run arguments model
        RunArgsModel;

        % The MetadataModel storing and validating the app's metadata
        MetadataModel

        % Created only when an app is associated with a Simulink Model
        SimulinkModel

        % Stores the group hierarchy created in the design environment
        GroupsModel

        % Current running app, if value is empty, there is no running App
        RunningApp;

        % When App is in the process of launching, IsLaunching will be true
        % This is true from when the user initates the run to when the
        % UIFigure frame appears
        IsLaunching

        % App's debugging state. It will be true if the App's full filename
        % is found anywhere in the debug call stack.
        IsDebugging = false;

        % Fullfile path to screenshot image. This property only
        % has a value when the user manually chooses an app screenshot on
        % the client and then needs to be saved into the MLAPP file. Once
        % it is saved, this property is set empty again because we don't
        % need to save it on every save. The screenshot is retrieved from
        % file only on demand and not every time an app is loaded.
        ScreenshotPath;

        % Boolean indicating if the app has been run after last saved 
        HasRunSinceLastSave = true;
    end

    properties (SetObservable, AbortSet)
        CodeGenerated = false;

        % Boolean indicating if the app is dirty or not
        IsDirty = [];        
    end

    properties(Access = 'private')
        % appdesigner.internal.model.AppDesignerModel
        %
        % This AppDesignerModel is the owner of this AppModel
        %
        % This property is analogous to 'Parent'
        AppDesignerModel;

        % Store the running app's UIFigure CodeName. If the user changes
        % the UIFigure CodeName while the app is running, we will close
        % the running app when the user saves the app since the MCOS object
        % of the UIFigure is no longer valid
        RunningUIFigureCodeName;

        % Store the listener to running app's BeingDestroyed event
        RunningAppBeingDestroyedListener;

        % Loaded component data for the app
        CodeNameComponentMap;
    end

    properties (Access = ?appdesigner.internal.controller.AppController)
        CompletionObserver
    end

    events (NotifyAccess = {?appdesigner.internal.componentmodel.DesignTimeComponentFactory})
	    ComponentAdded
	end

    methods
        function obj = AppModel(appDesignerModel, proxyView, uiFigure)
            % Constructor for AppModel
            %
            % Inputs:
            %
            %   appDesignerModel - The appdesigner.internal.model.AppDesignerModel
            %                      that will edit this App Model

            % Error Checking
            narginchk(2, 3);

            validateattributes(appDesignerModel, ...
                {'appdesigner.internal.model.AppDesignerModel'}, ...
                {});

            % Store the AppDesignerModel and ProxyView
            obj.AppDesignerModel = appDesignerModel;

            % set the model's name and format properties
            [obj.Name, obj.FullFileName] = getModelNameProperties(proxyView.PeerNode);
            
            obj.FileFormat = proxyView.PeerNode.getProperty('FileFormat');
            if isempty(obj.FileFormat)
                obj.FileFormat = 'mlapp';
            end

            % Store loaded uifigure for later using during creating
            % component models
            % Do this before controller creation because it will call
            % processClientCreatedPeerNode() from
            % DesignTimeParentingController's processProxyView(), which
            % will try to create children objects
            if nargin == 3 && ~isempty(uiFigure)
                obj.storeLoadedUIFigure(uiFigure);
            end

            % create the controller
            obj.createController(obj.AppDesignerModel.Controller, proxyView);

            % add this model as a child
            obj.AppDesignerModel.addChild(obj);

            obj.CompletionObserver = appdesigner.internal.application.observer.AppActionObserver;
        end

        function delete(obj)
            % Delete figure if deleting AppModel instance
            % directly from server side, which happens in test or
            % development workflow
            % In App Designer, it will be deleted through the
            % AppController
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure)
                delete(obj.UIFigure);
            end

            if ~isempty(obj.RunningAppBeingDestroyedListener)
                delete(obj.RunningAppBeingDestroyedListener);
            end
        end

        function set.UIFigure(obj, newUIFigure)
            % Error Checking
            validateattributes(newUIFigure, ...
                {'matlab.ui.Figure'}, ...
                {});

            % Storage
            obj.UIFigure = newUIFigure;
        end

        function set.CodeModel(obj, codeModel)

            validateattributes(codeModel, ...
                {'appdesigner.internal.codegeneration.model.CodeModel'}, ...
                {});

            % Storage
            obj.CodeModel = codeModel;
        end

        function set.Name(obj, newName)

            if ~isvarname(newName)
                error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName', newName, namelengthmax));
            else
                obj.Name = newName;
                markPropertiesDirty(obj, 'Name');
            end
        end

        function set.IsLaunching(obj, status)

            obj.IsLaunching = status;
            markPropertiesDirty(obj, 'IsLaunching');
        end

        function set.IsDebugging(obj, status)
            obj.IsDebugging = status;
            markPropertiesDirty(obj, 'IsDebugging');
        end

        function set.MetadataModel(obj, metadataModel)
            validateattributes(metadataModel, ...
                {'appdesigner.internal.model.MetadataModel'}, ...
                {});

            % Storage
            obj.MetadataModel = metadataModel;
        end

        function set.ScreenshotPath(obj, uri)
            obj.ScreenshotPath = uri;
            markPropertiesDirty(obj, 'ScreenshotPath');
        end

        function set.HasRunSinceLastSave(obj, value)
            obj.HasRunSinceLastSave = value;
            markPropertiesDirty(obj, 'HasRunSinceLastSave');
        end

        function set.FullFileName(obj, newFileName)
            obj.FullFileName = newFileName;
            markPropertiesDirty(obj, 'FullFileName');
        end

        function adapterClassName = getAdapterClassName(obj, adapterType)
            % return the adapter class name for the given adapter type
            adapterMap = obj.AppDesignerModel.ComponentAdapterMap;
            if ( isKey(adapterMap,adapterType) )
                adapterClassName = adapterMap(adapterType);
            else
                % if  the adapter is not found then return []
                adapterClassName = [];
            end
        end

        function adapterMap = getAdapterMap(obj)
            % return the adapter map
            adapterMap = obj.AppDesignerModel.ComponentAdapterMap;
        end

        function save(obj, fileName)
            % SAVE - fileName is the full file name with path information
            % where the item is to be saved.

            if nargin == 1
                fileName = obj.FullFileName;
            end

            [~, appName] = fileparts(fileName);

            % If the app is running and either the UIFigure CodeName
            % changed or the current app code contains a parsing error,
            % close the running app.
            %
            % A parsing error will prevent the MCOS auto-update to occur
            % and so if the user tries to interact with the app such as
            % executing a callback, it will not work properly and no live
            % error alert will display because the app is broken (g1249971).
            % Closing the running app will prevent the user from
            % interacting with a broken app.
            if ~isempty(obj.RunningApp)
                uiFigureCodeName = obj.getUIFigureCodeName();

                % Determine if the code has a parsing error
                T = mtree(obj.CodeModel.GeneratedCode);

                if ~strcmp(uiFigureCodeName, obj.RunningUIFigureCodeName) || ...
                        (T.count == 1 && strcmp(T.kind(), 'ERR'))

                    % Need to try/catch the delete of the running app in
                    % case there is a syntax error on a previous save that
                    % was not detected by mtree (see g1290751).
                    try
                        obj.RunningApp.delete();
                        obj.RunningApp = [];
                    catch exception
                        % Because the app can not be closed, report the
                        % error as a live error alert.
                        appController = obj.getController();
                        appController.sendErrorAlertToClient(exception, fileName);
                    end
                end
            end

            try
                % Let the codeModel update itself in response to a save
                % This is here to support the command line API
                obj.CodeModel.ClassName = appName;

                % Write the AppModel to the filename
                [fullFileName] = obj.writeAppToFile(fileName);

                % Update model because writeAppToFile returned no errors
                obj.Name = appName;
                obj.FullFileName = fullFileName;
                obj.HasRunSinceLastSave = false;
            catch me

                % Restore CodeModel state to the same as it was before the
                % save was attempted
                obj.CodeModel.ClassName = obj.Name;

                rethrow(me);
            end
        end

        function copy(obj, toFileName, updatedCode)
            % COPY - toFileName is the full file name with path information
            % where the app is to be saved.

            % make a copy of the UIFigure
            copiedUIFigure = obj.copyUIFigure();

            % delete the copied uifigure on cleanup after "save copy as" is
            % done. The copied figure is no longer needed.
            cleanupObj = onCleanup(@()delete(copiedUIFigure));

            % create the serializer
            serializer = appdesigner.internal.serialization.MLAPPSerializer(toFileName,copiedUIFigure);

            % set data on the Serializer to be serialized
            obj.setDataOnSerializer(serializer);

            % Use MLAPP exporter to ensure class name and constructor to be
            % updated when the new file name is different from the orignal one
            exporter = appdesigner.internal.serialization.converter.MLAPPExporter(toFileName, struct('originalName', obj.Name));
            serializer.MatlabCodeText = exporter.getGeneratedCode(updatedCode);

            % create the copy of the app
            serializer.save()
        end

        function [fullFileName] = writeAppToFile(obj, fileName)
            % WRITEAPPTOFILE - Validate inputs and write App to file
            [path, name, ext] = fileparts(fileName);


            if ~isvarname(name)
                error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName', name));
            end

            if isempty(path)
                % The case of saving to the current directory
                path = cd;
            end

            % Check if directory exists
            [success, dirAttrib] = fileattrib(path);

            % Directory should exist
            if ~success
                error(message('MATLAB:appdesigner:appdesigner:NotWritableLocation', fileName))
            end

            % Reassemble fullFileName in case the path has changed.
            fullFileName = fullfile(path, [name, ext]);
            if dirAttrib.directory && (numel(path) < numel(dirAttrib.Name))
                % if path was a relative path, path will not be the same as
                % the Name as returned by FILEATTRIB
                fullFileName = fullfile(dirAttrib.Name, [name, ext]);
            end

            % create the serializer
            serializer = appdesigner.internal.application.createMLAPPSerializer(fullFileName, obj);

            % set data on the Serializer
            obj.setDataOnSerializer(serializer);

            % save the app data
            serializer.save();

            % Reset the ScreenshotPath to empty because we don't need to save
            % the screenshot on every save, just when it is changed
            % by the user.
            if ( ~isempty(obj.ScreenshotPath))
                obj.ScreenshotPath = '';
            end

            % clear breakpoints from previous file name when creating new file or 
            % save as file with different name (g2284809, g1078401)
            if isempty(obj.FullFileName) || ~strcmp(obj.FullFileName, fullFileName)
                dbclear('in', fullFileName);
            end

            % Clear the class
            clear(name);
        end

        function setDataOnSerializer(obj, serializer)
            % Sets the data on the serializer to be serialized
            obj.CodeModel.setDataOnSerializer(serializer);
            obj.MetadataModel.setDataOnSerializer(serializer);
            obj.RunArgsModel.setDataOnSerializer(serializer);
            obj.GroupsModel.setDataOnSerializer(serializer);

            serializer.ScreenshotPath = obj.ScreenshotPath;

            if ~isempty(obj.SimulinkModel)
                obj.SimulinkModel.setDataOnSerializer(serializer);
            end
        end

        function removeErroredComponents(obj, codeNames)
            % Given a list of code names, delete the corresponding
            % components.  Should only be used to delete components during
            % the app loading process, before components have had their
            % controllers created.
            childrenMap = appdesigner.internal.application.getDescendantsMapWithCodeName(obj.UIFigure);
            for idx = 1:length(codeNames)
                codeName = codeNames{idx};
                component = childrenMap.(codeName);
                delete(component);
            end
        end

       function copiedUIfigure = copyUIFigure(obj)
           tempFileLocation = [tempname, '.mat'];

           % The temporary file will need to be deleted after reading
           c = onCleanup(@()delete(tempFileLocation));
           figureToCopy = obj.UIFigure;

           % Disable save warning and capture current lastwarn state
           previousWarning = warning('off','MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality');

           % Suppress the SizeChangedFcnDisabledWhenAutoResizeOn warning
           % during load. The warning will be thrown if the loaded
           % container has AutoResizeChildren set to 'on' and SizeChanged
           % set to a non-empty value.
           previousWarning(end+1) = warning('off', 'MATLAB:ui:containers:SizeChangedFcnDisabledWhenAutoResizeOn');
           [lastWarnStr, lastWarnId] = lastwarn;

           save(tempFileLocation,'figureToCopy');

           % apply the figures default system to all the components
           cleanupObj = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.listenAndConfigureUIFigure();

           loadedData = load(tempFileLocation);
           copiedUIfigure = loadedData.figureToCopy;

           % Restore previous warning state
           warning(previousWarning);
           lastwarn(lastWarnStr, lastWarnId);
       end

        function copyAppFile(obj, copyToFullFileName)
            % COPYAPPFILE - Creates a copy of the serialized app file.
            %
            % Note that this does NOT update the class name in the code for
            % the new file to match the copy to filename. It performs a
            % naive, straight copy. Also, the copy will be writable even if
            % the original is not so that a save can be performed on top of
            % the copy.

            fileWriter = appdesigner.internal.serialization.FileWriter(copyToFullFileName);
            fileWriter.copyAppFromFile(obj.FullFileName);
        end

        function runApp(obj, fullFileName, appArguments)

            % Run the App as if by command line
            [~, appName, appExt] = fileparts(fullFileName);

            % Silently save the app if it no longer exists because the user
            % deleted or renamed it using the file system prior to running
            % the app from App Designer.
            if exist(fullFileName, 'file') ~= 2
                try
                    save(obj, fullFileName);
                catch
                    exception = MException(message('MATLAB:appdesigner:appdesigner:RunFailedFileNotFound', [appName appExt], fullFileName));
                    throw(exception);
                end
			end
			
            if appdesigner.internal.apprun.isSameNameAppRunning(fullFileName, obj.RunningApp)
                % First check if there's a same name app from different folder already running
                exception = MException(...
                        message('MATLAB:appdesigner:appdesigner:SameNameAppRunning', appName));
                throw(exception);
            end

            appPath = appdesigner.internal.service.util.PathUtil.getPathToApp(fullFileName);
            command = appdesigner.internal.service.util.PathUtil.getAppRunCommandFromFileName(fullFileName);

            % g2061791: Call clear() and addpath() before calling which().
            % The function isAppNameShadowed calls which() via
            % mdbfileonpath().  This call to which() reloads the MCOS class
            % definition.  If another app with the same classname is found
            % earlier on the path, its class definition will be loaded
            % into memory.  This results in the wrong app running from App
            % Designer.  Calling addpath() here ensures that the app being
            % run from App Designer is found first on the path when which()
            % is called.
            clear(command);
            addpath(appPath);

            [CWDShadowed, precedenceShadowed] = appdesigner.internal.apprun.isAppNameShadowed(fullFileName);

            shadower = which(appName);
            
            if CWDShadowed
                exception = MException(message('MATLAB:appdesigner:appdesigner:AppNameShadowedByCWD', shadower));
                throw(exception);
            end

            if precedenceShadowed
                [~, name, extension] = fileparts(shadower);
                exception = MException(message('MATLAB:appdesigner:appdesigner:AppNameShadowedByPrecedence',...
                    shadower, [name extension]));
                throw(exception);
            end

            funcHandle = @()appdesigner.internal.model.AppModel.runAppHelper(obj, fullFileName, appArguments);

            % This is being used to defer the eval call to MATLAB until
            % after the fevals produced by the synchronization effort have
            % been complete.  This bumps the eval that creates the App to
            % the bottom of the list.
            appdesigner.internal.serialization.defer(funcHandle);
        end

        function addErrorAlertListener(obj)
            appController = obj.getController();
            appController.addErrorAlertListener(obj);
        end
        
        function addUpdateExceptionAlertListener(obj, runningComponent)
            appController = obj.getController();
            appController.addUpdateExceptionAlertListener(runningComponent, obj.FullFileName);
        end

        function component = popComponent(obj, codeName)
            component = [];

            if ~isempty(obj.CodeNameComponentMap) && ...
                    obj.CodeNameComponentMap.isKey(codeName)
                component = obj.CodeNameComponentMap(codeName);

                % After retrieving the component, remove it from the map
                % because it has been created successfully when loading the
                % app
                obj.CodeNameComponentMap.remove(codeName);
            end

        end
    end

    methods (Access = private)
        function uiFigureCodeName = getUIFigureCodeName(obj)
            uiFigureCodeName = obj.UIFigure.DesignTimeProperties.CodeName;
        end

        function onCleanupRunningAppReference(obj)
            % Listen to the running app being destroyed, then clear the
            % reference to the running app instance from AppModel,
            % otherwise there would be a timing issue during updating
            % the app's breakpoints information since the reference
            % to a deleted instance exists. See g1604996
            function cleanRunningAppReference(appModel)
                appModel.RunningApp = [];
            end

            if ~isempty(obj.RunningApp)
                if isvalid(obj.RunningApp)
                    % The user may delete the app in the startupFcn. See g1766098
                    obj.RunningAppBeingDestroyedListener = ...
                        addlistener(obj.RunningApp, 'ObjectBeingDestroyed', @(src, e)cleanRunningAppReference(obj));
                else
                    % app is deleted, and we also need to clear the
                    % reference to the running app in AppModel
                    cleanRunningAppReference(obj);
                end
            end
        end

        function mostRecentPrjFullFileName = getMostRecentPackageProject(obj, mlappFullFileName)
            % Find most recent .prj file in the same directory as the .mlapp file,
            % which has the Main File field set to the specified mlapp file.

            [filePath, mlappFile, ext] = fileparts(mlappFullFileName);

            % Find all .prj files in the same directory as the .mlapp file
            % Returns struct array with name and datenum (double) fields

            prjFiles = dir(fullfile(filePath, '*.prj'));

            aps = com.mathworks.toolbox.apps.services.AppsPackagingService;

            mostRecentPrjFullFileName = [];
            mostRecentPrjFileDatenum = 0;
            for file = prjFiles'
                if file.isdir
                    continue;
                end
                try
                    prjFullFileName = fullfile(filePath, file.name);
                    if aps.doesProjectContainMainFile(prjFullFileName, mlappFullFileName)
                        if file.datenum > mostRecentPrjFileDatenum
                            mostRecentPrjFullFileName = fullfile(filePath, file.name);
                            mostRecentPrjFileDatenum = file.datenum;
                        end
                    end
                catch ex
                    % Unknown error using packaging API -> return generic PackageError
                    error(message('MATLAB:appdesigner:appdesigner:PackageAppFailed', mlappFullFileName));
                end
            end
        end
    end

    methods (Static)

        function runAppHelper(currentAppModel, fullFileName, appArguments)

            appFullFileName = currentAppModel.FullFileName;

            % Guarentee IsLaunching is set to false and restoring current
            % folder
            isLaunchingCleanup = onCleanup(@()set(currentAppModel, 'IsLaunching', false));

            % Delete existing instance of the current app.
            % This IF statement has been moved from the runApp method to
            % this defered method to resolve an issue with the Run button
            % being disabled when the code has a syntax error and the
            % RunningApp instance is deleted (see g1098581).
            if ~isempty(currentAppModel.RunningApp)
                try
                    % The deletion of the previously running app could
                    % throw an exception if the running app's code was
                    % updated and fails when parsed.
                    % Destroying the last running app instance will trigger
                    % listener in onCleanupRunningAppReference() to set
                    % RunningApp to empty
                    closer = appdesigner.internal.appcloser.RunningInstanceCloserFactory.createCloser(...
                        currentAppModel.MetadataModel.AppType, currentAppModel.RunningApp);
                    closer.closeRunningInstance();
                catch
                    % Allow the exception to pass through because it will
                    % also fail when we attempt to eval the app in the code
                    % below. Reporting the eval failure is more relevant
                    % and useful than reporting the delete failure.
                end
            elseif strcmp(currentAppModel.CodeModel.SingletonMode, 'FOCUS')
				% There may be a case where the app has been launched
				% externally, then relaunched from app designer, in this
				% case the design environment should take over and close
				% the externally launched apps, g2259162
				appdesigner.internal.apprun.closeExternallyExecutedSingletonApp(fullFileName);
			end

            % Save the current UIFigure CodeName for next saving
            % to decide if needed to close the running app or not by
            % comparing the old and new CodeName
            currentAppModel.RunningUIFigureCodeName = currentAppModel.getUIFigureCodeName();

            % Listen for run time errors that occur in the running
            % app's callbacks
            currentAppModel.addErrorAlertListener();


            % Store newly generated app in the obj.RunningApp. This
            % line could throw an exception if the app's code fails
            % in parsing or an error occurs in the app's constructor.
            instantiator = appdesigner.internal.apprun.AppInstantiatorFactory.createInstantiator(currentAppModel);
            currentAppModel.RunningApp = instantiator.run(appArguments);


            % When the running app is closed, clear the reference to the
            % running app instance from AppModel
            currentAppModel.onCleanupRunningAppReference();

            % Get the figure service to interact with the figure
            serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();
            figureService = serviceProvider.FigureService;

            % If the app is deleted, closed, etc... do not continue from
            % here because the following code works on a valid running app.
            % The app could be deleted if the user put "delete(app)"
            % in the app's startupFcn
            if ~isempty(currentAppModel.RunningApp)

                % Auto-capture screenshot of running app unless the
                % screenshotMode is manual which means the user has specified
                % a custom screenshot image.
                screenshotMode = currentAppModel.MetadataModel.ScreenshotMode;
                
                if strcmp(screenshotMode, 'auto') && ~currentAppModel.HasRunSinceLastSave
                    % Capture and serialize the app screenshot
                    try
                        figureService.captureScreenshot(currentAppModel.RunningApp, appFullFileName);
                    catch
                        % Don't throw error if for some rare reason the capture
                        % fails as the cature should be unnoticed by the user.
                    end
                end
            end
            currentAppModel.HasRunSinceLastSave = true;
        end
    end

    methods(Access = 'private')
        function storeLoadedUIFigure(obj, uiFigure)
            % Store the loaded uifigure

            % Flat all components to store as a map with CodeName as key
            % for quick retrieving when creating design time comopnent
            % models
            %childrenList = appdesigner.internal.application.getDescendants(uiFigure);
            childrenList = findall(uiFigure, '-property', 'DesignTimeProperties');
            % Loaded component data for the app
            obj.CodeNameComponentMap = containers.Map();

            for ix = 1:numel(childrenList)
                codeName = childrenList(ix).DesignTimeProperties.CodeName;
                obj.CodeNameComponentMap(codeName) = childrenList(ix);
            end
        end
    end

    methods(Access = 'public')

        function controller = createController(obj, parentController, proxyView)
            % Creates the controller for this Model
            controller = appdesigner.internal.controller.AppController(obj, parentController, proxyView);

            controller.populateView(proxyView);
        end
    end

end

function [fileName, fullName] = getModelNameProperties(viewModel)
    fullFileName = viewModel.getProperty('FullFileName');
    if ~isempty(fullFileName)
        fullName = fullFileName;
        [~, fileName, ~] = fileparts(fullFileName);
    else
        fullName = '';
        fileName = viewModel.getProperty('Name');
    end
end