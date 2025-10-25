classdef MetadataUIViewModel < handle
    % This class serves as ViewModel for the Metadata UI app
    
    % Copyright 2020-2024 The MathWorks, Inc.
    properties(Access = private)
        Metadata      % metadata for the selected component
        Status        % status of the selected component
        ComponentName % name of the selected component
        Directory     % directory of the selected component
        Categories    % all categories present in appDesigner.json
        FilePath      % filePath of the seleccted components
        ModelValidity % validity of the appdesigner.json
    end
    
    events
        UpdateModelEvent
        RegistrationErrorEvent
        RegistrationSuccessEvent
        CleanUpAppEvent
    end
    
    methods(Access = public)
        
        function obj = MetadataUIViewModel(payload)
            % MetadataUIViewModel: this funtion is constructor for MetadataUIViewModel
            % it creates metadata object for the MetadataUI app
            import appdesigner.internal.usercomponent.metadata.Constants
            
            obj.ModelValidity = payload.ModelValidity;
            
            obj.FilePath = payload.FilePath;
            % populate componentName
            metadata = payload.Metadata;
            
            % populate icon and description fields based on registration
            % status
            obj.Directory = payload.Directory;
            if strcmp(metadata.status, Constants.NotRegistered)
                metadata = obj.getDefaultMetadata(metadata);
            end
            
            % populate category drop-down values
            categories = payload.Categories;
            defaultCategory = char(Constants.MyComponents);
            if isempty(categories)
                categories = {defaultCategory};
            else
                if ~contains(categories, defaultCategory)
                    categories{end+1} = defaultCategory;
                end
            end
            
            obj.Status = metadata.status;
            metadata = rmfield(metadata, Constants.Status);
            
            obj.Metadata = metadata;
            obj.Categories = categories;
            obj.ComponentName = metadata.componentName;
        end
        
        % Getter methods for MetadataUIViewModel
        
        function metadata = getMetadata(obj)
            metadata = obj.Metadata;
        end
        
        function status = getStatus(obj)
            status = obj.Status;
        end
        
        function categories = getCategories(obj)
            categories = obj.Categories;
        end
        
        function isValid = getModelValidity(obj)
            isValid = obj.ModelValidity;
        end
        
        function [shortenedFilePath, filePath] = getFilePath(obj)
            import appdesigner.internal.usercomponent.metadata.Constants
            filePath = obj.FilePath;
            
            if length(filePath) <= Constants.MaxFilePathLength
                shortenedFilePath = filePath;
            else
                [directory, filename, extension] = fileparts(obj.FilePath);
                completeFileName =  strcat('...', filesep, filename, extension);
                maxFilePathLength = Constants.MaxFilePathLength;
                directoryPathLength = maxFilePathLength - length(completeFileName);
                if length(directory) >= directoryPathLength
                    directory = directory(1:directoryPathLength);
                end
                shortenedFilePath = [directory, completeFileName];
            end
        end
        
        % public API for MetadataUIViewModel
        
        function alignFigure(obj, figure)
            % alignFigure: this funtion aligns figure for MetadataUI in the
            % center of the screen
            figure.Visible = 'off';
            movegui(figure,'center');
            drawnow;
            figure.Visible = 'on';
        end
        
        
        function registerComponent(obj, metadata)
            % registerComponent: this funtion is called when register
            % button is clicked on MetadataUI. It creates and sends
            % UpdateModelEvent to the controller
            import appdesigner.internal.usercomponent.metadata.Constants
            
            % get avatar and defaultPosition for the component for both
            % light/unthemed and dark. Component is run only once. The
            % figure theme is flipped to capture the dark avatar once light
            % avatar getframe is processed and image cdate is converted to 
            % base64 string.
            [didError, metadata.avatar, metadata.avatarDark, metadata.defaultPosition] = obj.getAvatar(metadata.className);

            adapterMap = appdesigner.internal.appmetadata.getProductionComponentAdapterMap();
            % User components without customized adapter would not be found in the map.
            % So defaults are only generated for the User component that
            % has specific adapter
            if isKey(adapterMap, (metadata.className))
                adapterClass = adapterMap(metadata.className);
                adapter = feval(adapterClass);
                if adapter.EnableClientDriven
                    metadata.propertyValues = adapter.getComponentDesignTimeDefaults();
                end
            end
        
            % if the avatar generation errored then abort the further
            % registration process
            if didError
                return;
            end
            % create UpdateModelEvent and notify
            if strcmp(obj.Status, Constants.Registered)
                type = Constants.Update;
            elseif strcmp(obj.Status, Constants.NotRegistered)
                type = Constants.Register;
            end
            
            eventData = appdesigner.internal.usercomponent.metadata.event.UpdateModelEventData(type, metadata);
            notify(obj, Constants.UpdateModelEvent, eventData);
        end
        
        function handleRegistrationError(obj, me)
            % handleRegistrationError: this function constructs a user
            % understandable message from a MATLAB exception, translates it
            % if required and then notifies MetadataUI
            import appdesigner.internal.usercomponent.metadata.Constants
            eventData = appdesigner.internal.usercomponent.metadata.event.RegistrationErrorEventData(me);
            notify(obj, Constants.RegistrationErrorEvent, eventData);
        end
        
        function handleRegistrationSuccess(obj)
            % handleRegistrationSuccess: this function notifyies the
            % MetadataUI that the registration was succesful
            import appdesigner.internal.usercomponent.metadata.Constants
            notify(obj, Constants.RegistrationSuccessEvent);
        end
        
        function cleanUpApp(obj)
            % cleanMetadataApp: this function notifies the
            % ConfigureMetadata class to clean all the objects and
            % listeners
            import appdesigner.internal.usercomponent.metadata.Constants
            notify(obj, Constants.CleanUpAppEvent);
        end

        function addComponentDirectoryToPath(obj)
            % addComponentDirectoryToPath: this function adds the
            % component's directory to the MATLAB path
            addpath(obj.Directory);
        end
        
        function isValid = validateComponentCatgory(obj, category)
            % validateCatgory - this function validates component's
            % category
            
            % Component category is not valid if it is empty.  
            % It is also not valid if it only contains spaces.
            categoryWithoutSpaces = replace(category,' ','');
            isValid = ~isempty(categoryWithoutSpaces);
        end
        
        function isValid = validateComponentName(obj, componentName)
            % validateComponentName - this function validates component's
            % name
            
            % Component name is not valid if it is empty.  
            % It is also not valid if it only contains spaces.
            componentNameWithoutSpaces = replace(componentName,' ','');
            isValid = ~isempty(componentNameWithoutSpaces);
        end
        
        function isValid = validateComponentVersion(obj, componentVersion)
            % validateComponentVersion - this function validates component
            % version for Major.Minor format
            import appdesigner.internal.usercomponent.metadata.Constants
            
            versionstartIndex = regexp(componentVersion, Constants.VersionRegex);
            isValid =  ~isempty(componentVersion) && ...
                (~isempty(versionstartIndex) && versionstartIndex == 1);
        end
        
        function isValid = validateAuthorEmail(obj, authorEmail)
            % validateAuthorEmail - this function validates author's email
            % address, with empty email address being a valid value
            import appdesigner.internal.usercomponent.metadata.Constants
            
            authorEmailStartIndex = regexp(authorEmail, Constants.EmailRegex);
            isValid = isempty(authorEmail) || ...
                (~isempty(authorEmailStartIndex) && authorEmailStartIndex == 1);
        end
        
        function imageSource = resizeIconImage(obj, iconFile)
            % resizeIconImage: this function resizes the provided image
            % file to size specified by Constants.ComponentLibIconSize
            % keeping the colormap and transperancy intact
            
            import appdesigner.internal.usercomponent.metadata.Constants
            
            tmpDir = fullfile(tempdir, 'MetadataUIIconUtil');
            [~,~,~] = mkdir(tmpDir);
            
            % create tempfile for image writing
            tmpFile = fullfile([tempname(tmpDir), '.', 'png']);
            % read file with RGB, colormap and alpha
            [RGB, map, alpha] = imread(iconFile);
            
            % if colormap is not empty convert it to true-color
            if ~isempty(map)
                RGB = ind2rgb(RGB, map);
            end
            % resize true-color image
            RGB = imresize(RGB, Constants.ComponentLibIconSize);
            
            % if transparency is not empty then rezie alpha and write the
            % image file
            if ~isempty(alpha)
                alpha = imresize(alpha, Constants.ComponentLibIconSize);
                imwrite(RGB, tmpFile, 'Alpha', alpha);
            else
                imwrite(RGB, tmpFile);
            end
            
            imageSource = tmpFile;
        end
    end
    
    methods(Access = private)
        function metadata = getDefaultMetadata(obj, metadata)
            % getDefaultMetadata: this funtion provides default metadta for
            % a non-registered component
            import appdesigner.internal.usercomponent.metadata.Constants
            
            % store current pwd and cd into user components dir
            % temporarily
            previousDir = pwd;
            cd(obj.Directory);
            
            % split output of the help funtion in  individual lines
            helpDescription = splitlines(help(metadata.className));
            % assign first line of the hellp function as default
            % description of the user-component
            metadata.description = strtrim(helpDescription{1});
            
            % change back to original pwd
            cd(previousDir);
            
            dirPath = strjoin(Constants.UserComponentPackagePath, filesep);
            metadata.icon = fullfile(matlabroot, dirPath, Constants.DefaultComponentIcon);
            metadata.category = Constants.MyComponents;
            metadata.authorName = '';
            metadata.authorEmail = '';
            metadata.version = Constants.DefaultVersion;
        end
        
        function [didError, avatar, avatarDark, position] = getAvatar(obj, componentName)
            % getAvatar: this funtion instatiates the registered component
            % and generates avatar for the component and store component's
            % default position
            
            import appdesigner.internal.usercomponent.metadata.Constants
            import matlab.internal.capability.Capability;

            previousDir = pwd;
            cd(obj.Directory);
            cleanupDir = onCleanup(@() cd(previousDir));
            
            breakpoints = dbstatus;
            dbclear all;
            cleanupBreakpoints = onCleanup(@() dbstop(breakpoints));

            me = [];
            avatar = '';
            avatarDark = '';
            position = [];
            didError = false;
            try
                % create a hidden component to get its dimensions
                cleanupObj = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.listenAndOverrideDefaultCreateFcnOnUIFigure();

                fig = uifigure('Visible', 'off', 'Theme','light');
                cleanupFig = onCleanup(@() close(fig));
                component =  feval(componentName, 'Parent', fig);
                
                % Per g3542173 explained, when scale/text scale/MATLAB zoom
                % level is set, figure's width and heigh would be scaled
                % down according to UIContainer layer's to set window
                % bounds with the css value (scaled value), therefore
                % figure's Position would be updated accordingly, which is
                % smaller than the one is set orginally.
                % In such a situation, if we use the orginal set Position
                % value to call getframe in the below code, it would not
                % work.
                % Try to make getframe work for most cases for UAC avatar
                % capturing, will only set figure Position twice bigger if
                % a UAC component is bigger than default figure. This
                % should work for almost most cases of UAC
                figDimensions = component.Position(3:4);
                fig.Position(1:2) = [0 0];
                if fig.Position(3) < figDimensions(1)
                    fig.Position(3) = figDimensions(1) * 2;
                end
                if fig.Position(4) < figDimensions(2)
                    fig.Position(4) = figDimensions(2) * 2;
                end
                
                % Force the figure view to be ready before instantiating
                % the component (see g2378634)
                drawnow;
                
                % reparent the component
                component.Parent = fig;
                
                % reposition the component
                component.Position(1:2) = [1, 1];
                drawnow;
                
                [isValid, errorMessage] = obj.validateComponent(fig, component);
                
                if ~isValid
                    throw(MException(errorMessage));
                end
                
                % check for MATLAB Online environment, this check is
                % required as getframe is not supported in MATLAB Online
                if Capability.isSupported(Capability.LocalClient)
                    % capture the avatar
                    try 
                       % Capture the light theme avatar
                       cropRect = [0, 0, component.Position(3), component.Position(4)];
                       [avatarCDataLight, ~] = getframe(fig, cropRect);
                       avatar = obj.convertCDataToBase64(avatarCDataLight);

                       % Capture the dark theme avatar
                       fig.Theme = 'dark';
                       drawnow;
                       [avatarCDataDark, ~] = getframe(fig, cropRect);
                       avatarDark = obj.convertCDataToBase64(avatarCDataDark);
                    % if there is an error while capturing the avatar,
                    % show a warning and continue with the configuration
                    catch
                        warning('MATLAB:appdesigner:usercomponentmetadata:AvatarNotCapturedInDesktopWarning', string(message('MATLAB:appdesigner:usercomponentmetadata:AvatarNotCapturedInDesktopWarning')));
                    end
                    
                else
                    warning('MATLAB:appdesigner:usercomponentmetadata:AvatarNotCapturedWarning', string(message('MATLAB:appdesigner:usercomponentmetadata:AvatarNotCapturedWarning')));
                end
                
                % store position
                position = component.Position;
            catch me
                if strcmp(me.identifier, 'MATLAB:class:abstract')
                    me = MException(message([Constants.MessageCatalogPrefix, 'AbstractComponentErrorMsg'], componentName));
                end
            end

            if ~isempty(me)
                obj.handleRegistrationError(me);
                didError = true;
            end
        end

        function avatarBase64 = convertCDataToBase64(~, avatarCData)
            % Helper function to convert CData to base64
            import appdesigner.internal.usercomponent.metadata.Constants
            avatarAsBytes = appdesigner.internal.application.ImageUtils.getBytesFromCDataRGB(avatarCData, Constants.PNGImageFormat);
            avatarBase64 = appdesigner.internal.application.ImageUtils.getImageDataURIFromBytes(avatarAsBytes, Constants.PNGImageFormat);
        end
        
        function [isValid, errorMessage] = validateComponent(obj, fig, component)
            % validateComponent: checks whether component has correct Units
            % and make sure that no rogue components are introduced
            import appdesigner.internal.usercomponent.metadata.Constants
             
            isValid = true;
            errorMessage = [];
            
            % validate UAC units
            if ~strcmp(component.Units, Constants.Pixels)
                isValid = false;
                errorMessage = message([Constants.MessageCatalogPrefix, 'InvalidUnitsErrorMsg']);
            end
            
            % check for rogue components
            children = allchild(fig);
            for childIndex = 1:length(children)
                child = children(childIndex);
                
                if child ~= component && ...
                            ~isa(child, 'matlab.ui.container.ContextMenu')
                    isValid = false;
                    errorMessage = message([Constants.MessageCatalogPrefix, 'RogueComponentErrorMsg']);
                end
            end
            
            % Make sure public callbacks used by app designer are not
            % assigned (see g2378386)
            callbackNames = appdesigner.internal.usercomponent.getCallbackPropertyNames(component);
            nonEmptyCallbacks = {};
            for i = 1: numel(callbackNames)
                callbackValue = component.(callbackNames{i});
                if ~isempty(callbackValue)
                    nonEmptyCallbacks = [nonEmptyCallbacks, callbackNames{i}]; %#ok<AGROW>
                end
            end
            
            if ~isempty(nonEmptyCallbacks)
                isValid = false;
                
                % Sort the callback names and generate the list of callback
                % events by removing 'Fcn' from the end.
                nonEmptyCallbacks = sort(nonEmptyCallbacks);
                nonEmpyCallbackEvents = regexprep(nonEmptyCallbacks, 'Fcn$', '');
                
                % Create comma separated list of callbacks and events for
                % the error message
                nonEmptyCallbacks = strjoin(nonEmptyCallbacks, ', ');
                nonEmpyCallbackEvents = strjoin(nonEmpyCallbackEvents, ', ');
                errorMessage = message([Constants.MessageCatalogPrefix, 'CallbackHasValueErrorMsg'], nonEmptyCallbacks, nonEmpyCallbackEvents);
            end
        end
    end
end
