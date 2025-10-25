classdef MetadataUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        AppGrid                      matlab.ui.container.GridLayout
        MetadataGrid                 matlab.ui.container.GridLayout
        HeadingLabel                 matlab.ui.control.Label
        CategoryGrid                 matlab.ui.container.GridLayout
        CategoryEditFieldLabel       matlab.ui.control.Label
        CategoryHelpIcon             matlab.ui.control.Image
        ComponentDetailsHelpIcon     matlab.ui.control.Image
        FilePath                     matlab.ui.control.Label
        ComponentFileLabel           matlab.ui.control.Label
        AuthorEmailLabel             matlab.ui.control.Label
        AuthorEmail                  matlab.ui.control.EditField
        AuthorName                   matlab.ui.control.EditField
        AuthorsNameEditFieldLabel    matlab.ui.control.Label
        Version                      matlab.ui.control.EditField
        VersionLabel                 matlab.ui.control.Label
        Description                  matlab.ui.control.TextArea
        DescriptionTextAreaLabel     matlab.ui.control.Label
        ComponentDetailsLabel        matlab.ui.control.Label
        BrowseIconButton             matlab.ui.control.Button
        Icon                         matlab.ui.control.Image
        Category                     matlab.ui.control.DropDown
        ComponentName                matlab.ui.control.EditField
        IconLabel                    matlab.ui.control.Label
        ComponentNameEditFieldLabel  matlab.ui.control.Label
        ComponentLibraryAppearanceLabel  matlab.ui.control.Label
        ActionButtonGrid             matlab.ui.container.GridLayout
        HelpButton                   matlab.ui.control.Button
        OkButton                     matlab.ui.control.Button
        CancelButton                 matlab.ui.control.Button
    end

    
    properties (Access = private)
        ViewModel               % reference to MetadataUIViewModel object
        Metadata                % struct holding metadata for the component
        ProgressDialog          % reference to ProgressDialog object
    end
    
    methods (Access = public)

        function localize(app)
            % internationalize: localize all user facing strings
            % this function iterates over all child components of the figure,
            % components that require localization have a their Tag
            % property set in the format <messageCatalogId>:<child's property>
            import appdesigner.internal.usercomponent.metadata.Constants
            childComponents = [app.UIFigure; app.MetadataGrid.Children; app.ActionButtonGrid.Children; app.CategoryGrid.Children];
            for componentIndex = 1:length(childComponents)
                childComponent = childComponents(componentIndex);
                if ~isempty(childComponent.Tag)
                    tagParts = strsplit(childComponent.Tag, ':');
                    childComponent.(tagParts{2}) = string(message([Constants.MessageCatalogPrefix, tagParts{1}]));
                end
            end
        end

        function iconPath = convertBase64ToImageSource(app, base64Image)
            % convertBase64ToImageSource: this funtion converts base64
            % image to an ImageSource acceptable by an Image component
            import appdesigner.internal.usercomponent.metadata.Constants

            % get image format
            imageParts = strsplit(base64Image,',');
            header = imageParts{1};
            imageFormat = char(regexp(header,Constants.ImageFormatRegex,'match'));

            % get image data
            data = imageParts{2};

            % convert image data to bytes
            bytes = matlab.net.base64decode(data);

            % write byte data to a temporary file
            tmpDir = fullfile(tempdir, Constants.TempDir);
            [~,~,~] = mkdir(tmpDir);
            iconPath = fullfile([tempname(tmpDir), '.', imageFormat]);
            appdesigner.internal.application.ImageUtils.createImageFileFromBytes(iconPath, bytes);
        end
        
        function formattedFilePathTooltip = formatFilePathTooltip(app, filePathTooltip)
            % formattedFilePathTooltip: this funtion adds spces to the
            % a long filePath-tooltip  so that the tooltip wraps around
            % instead of getting clipped by the figure dimension
            import appdesigner.internal.usercomponent.metadata.Constants
            formattedFilePathTooltip = filePathTooltip;
            lineLength = Constants.MaxFilePathLength / 2;
            if length(filePathTooltip) > lineLength
                formattedFilePathTooltip = '';
                index = 1;
                while index < length(filePathTooltip)
                    if index + lineLength > length(filePathTooltip)
                        formattedFilePathTooltip = [formattedFilePathTooltip,' ' ,filePathTooltip(index:end)];
                        break;
                    end
                    filePathPart = filePathTooltip(index:index+lineLength);
                    formattedFilePathTooltip = [formattedFilePathTooltip,' ' ,filePathPart];
                    index = index + lineLength + 1;
                end
            end
        end
        
        function showRegistrationError(app, ~, eventData)
            % showRegistrationError: this funtions listens to the
            % RegistrationError event and shows appropriate error in the
            % Metadata UI
            import appdesigner.internal.usercomponent.metadata.Constants
            delete(app.ProgressDialog);
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'RegistrationErrorMsg'], eventData.ErrorMessage));
            uialert(app.UIFigure, selectionDialogMsg, selectionDialogHeader,...
                'Icon','error');
        end
        
        function closeMetadataUI(app, ~, ~)
            % closeMetadataUI: this funtion listens to the
            % RegistrationSuccessEvent and shows the success message in the
            % Metadata UI
            import appdesigner.internal.usercomponent.metadata.Constants
            % close progress indicator
            delete(app.ProgressDialog);
            
            % construct and show success message
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            if strcmp(app.ViewModel.getStatus(), Constants.NotRegistered)
                selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'RegistrationSuccessMsg']));
            else
                selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'UpdateSuccessMsg']));
            end
           
            uiconfirm(app.UIFigure, selectionDialogMsg, selectionDialogHeader,...
                'Icon','success', 'Options', {char(Constants.AddPath), char(Constants.Ok)}, 'CloseFcn',@app.cleanUpApp);
        end
        
        function handleInvalidModel(app)
            % handleInvalidModel: this function shows the error message to
            % the author that the exisiiting appDesigner.json file is
            % invalid and saving metadata for the current component will 
            % re-write the existing file 
            import appdesigner.internal.usercomponent.metadata.Constants
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'InvalidModelWarningMsg']));
     
            uialert(app.UIFigure, selectionDialogMsg, selectionDialogHeader,...
                'Icon','warning');
        end
        
        function resetComponentCategory(app, ~, ~)
            % resetComponentCategory: resets the value of component category
            % to previous valid value
            app.Category.Value = app.Metadata.category;
        end
        
        function resetComponentName(app, ~, ~)
            % resetComponentName:resets value of component name to previous
            % valid value
             app.ComponentName.Value = app.Metadata.componentName;
        end
        
        function resetComponentVersion(app, ~, ~)
            % resetComponentVersion:resets value of component version to 
            % previous valid value
            app.Version.Value = app.Metadata.version;
        end
        
        function resetAuthorEmail(app, ~, ~)
            % resetAuthorEmail: resets value of author email to previous
            % valid value
            app.AuthorEmail.Value = app.Metadata.authorEmail;
        end

        function cleanUpApp(app, ~, event)
            % cleanUpApp: calls cleanUpApp function on viewmodel and then
            % deletes the app

            if event.SelectedOptionIndex == 1
                app.ViewModel.addComponentDirectoryToPath();
            end

            app.ViewModel.cleanUpApp();
            delete(app);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, viewModel)
            import appdesigner.internal.usercomponent.metadata.Constants           
            
            viewModel.alignFigure(app.UIFigure);
            
            app.localize();
            
            % populate UI fields in the app
            [app.FilePath.Text, filePathTooltip] = viewModel.getFilePath();
            app.FilePath.Tooltip = app.formatFilePathTooltip(filePathTooltip);
            metadata = viewModel.getMetadata();
            app.ComponentName.Value = metadata.componentName;
            
            dirPath = strjoin(Constants.UserComponentPackagePath, filesep);
            
            if strcmp(viewModel.getStatus(), Constants.NotRegistered)
                app.Icon.ImageSource = metadata.icon;
            else
                try
                    app.Icon.ImageSource = app.convertBase64ToImageSource(metadata.icon);
                catch
                    app.Icon.ImageSource = fullfile(matlabroot, dirPath, Constants.DefaultComponentIcon);
                end
            end
            
            app.CategoryHelpIcon.ImageSource = fullfile(matlabroot, dirPath, Constants.HelpIcon);
            app.ComponentDetailsHelpIcon.ImageSource = fullfile(matlabroot,dirPath,Constants.HelpIcon);
            app.BrowseIconButton.Icon = fullfile(matlabroot, dirPath, Constants.FolderIcon);
            
            app.Version.Value = metadata.version;
            app.Description.Value = metadata.description;
            app.Category.Items = viewModel.getCategories();
            app.Category.Value = metadata.category;           
            app.AuthorName.Value = metadata.authorName;
            app.AuthorEmail.Value = metadata.authorEmail;
            
            % add listners to registration events emitted by the viewModel
            addlistener(viewModel, Constants.RegistrationErrorEvent, @app.showRegistrationError);
            addlistener(viewModel, Constants.RegistrationSuccessEvent, @app.closeMetadataUI);
            
            % check validity status of appDesigner.json and show message
            % accordingly
            if ~viewModel.getModelValidity()
                app.handleInvalidModel();
            end
            
            app.ViewModel = viewModel;
            app.Metadata = metadata;
        end

        % Button pushed function: OkButton
        function OkButtonPushed(app, event)
            import appdesigner.internal.usercomponent.metadata.Constants
          
            % do validations before proceeding with the registration           
            isValidMetadata = app.ViewModel.validateComponentName(app.ComponentName.Value) && ...
                              app.ViewModel.validateComponentCatgory(app.Category.Value) && ...
                              app.ViewModel.validateComponentVersion(app.Version.Value) && ...
                              app.ViewModel.validateAuthorEmail(app.AuthorEmail.Value);
            
            if ~isValidMetadata
                return;
            end
            
            % show progress-dialog
            progressDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader'])); 
            progressDialogMsg = string(message([Constants.MessageCatalogPrefix, 'RegistrationInProgressMsg'])); 
            app.ProgressDialog = uiprogressdlg(app.UIFigure,'Indeterminate','on',...
                        'Message',progressDialogMsg,...
                        'Title',progressDialogHeader);
             
             % collect metadata in a struct
             viewModel = app.ViewModel;
             metadata = app.Metadata;
         
             metadata.componentName = app.ComponentName.Value;
             
             metadata.version = app.Version.Value;
             
             description = app.Description.Value;
             if iscell(description)
                 description = strjoin(description, newline);
             end
             metadata.description = string(description);

             metadata.category = app.Category.Value;
             
             metadata.icon = appdesigner.internal.application.ImageUtils.getImageDataURIFromFile(app.Icon.ImageSource);             
             
             metadata.authorName = app.AuthorName.Value;
             metadata.authorEmail = string(app.AuthorEmail.Value);
             metadata.className = metadata.className;
             
             % save metadata
             viewModel.registerComponent(metadata);
        end

        % Button pushed function: BrowseIconButton
        function BrowseIconButtonPushed(app, event)
            import appdesigner.internal.usercomponent.metadata.Constants
            [fileName, filePath] = uigetfile( ...
                {'*.gif;*.jpeg;*.jpg;*.png;','All Image Files (*.gif,*.jpeg,*.jpg,*.png)';
                '*.*',  'All Files (*.*)'}, 'Choose a File');
            figure(app.UIFigure);
            
            if fileName ~= 0
                [~, ~, imageFormat] = fileparts(fileName);
                if contains(['.gif','.jpeg','.jpg','.png'], lower(imageFormat))
                    icon = fullfile(filePath, fileName);
                    app.Icon.ImageSource = app.ViewModel.resizeIconImage(icon);
                else
                    selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
                    selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'IconFileErrorMsg']));
                    uialert(app.UIFigure,selectionDialogMsg, selectionDialogHeader,...
                        'Icon','error');
                end
            end
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            app.ViewModel.cleanUpApp();
            delete(app);
        end

        % Value changed function: Category
        function CategoryValueChanged(app, event)
         import appdesigner.internal.usercomponent.metadata.Constants
            
            % if valid assign value and return
            if app.ViewModel.validateComponentCatgory(event.Value)
                app.Metadata.category = event.Value;
                return;
            end
            
            % if invalid show error-message
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'CategoryEmptyErrorMsg']));
            uialert(app.UIFigure,selectionDialogMsg,selectionDialogHeader,...
                'Icon','error','CloseFcn',@app.resetComponentCategory);
        end

        % Value changed function: ComponentName
        function ComponentNameValueChanged(app, event)
            import appdesigner.internal.usercomponent.metadata.Constants
 
            % if valid assign value and return
            if app.ViewModel.validateComponentName(event.Value)
                app.Metadata.componentName = event.Value;
                return;
            end
            
            % if invalid show error-message and restore previous value
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'ComponentNameEmptyErrorMsg']));
            uialert(app.UIFigure,selectionDialogMsg,selectionDialogHeader,...
                'Icon','error','CloseFcn',@app.resetComponentName);
  
        end

        % Value changed function: Version
        function VersionValueChanged(app, event)
            import appdesigner.internal.usercomponent.metadata.Constants
 
            % if valid assign value and return
            if app.ViewModel.validateComponentVersion(event.Value)
                 app.Metadata.version = event.Value;
                 return;
            end
            
            % if invalid show error-message and restore previous value
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'InvalidVersionErrorMsg']));
            uialert(app.UIFigure, selectionDialogMsg, selectionDialogHeader,...
                'Icon','error','CloseFcn',@app.resetComponentVersion);
        end

        % Value changed function: AuthorEmail
        function AuthorEmailValueChanged(app, event)
            import appdesigner.internal.usercomponent.metadata.Constants

            % if valid assign value and return
            if app.ViewModel.validateAuthorEmail(event.Value)
                app.Metadata.authorEmail = event.Value;
                return;
            end
            
            % if invalid show error-message and restore empty value
            selectionDialogHeader = string(message([Constants.MessageCatalogPrefix, 'ComponentRegistrationHeader']));
            selectionDialogMsg = string(message([Constants.MessageCatalogPrefix, 'InvalidEmailErrorMsg']));
            uialert(app.UIFigure, selectionDialogMsg, selectionDialogHeader,...
                'Icon','error', 'CloseFcn', @app.resetAuthorEmail);
        end

        % Button pushed function: HelpButton
        function HelpButtonPushed(app, event)
            helpview('matlab', 'appd_configure_component');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 485 617];
            app.UIFigure.Name = 'App Designer Custom UI Component Metadata';
            app.UIFigure.Tag = 'MetadataUITitle:Name';

            % Create AppGrid
            app.AppGrid = uigridlayout(app.UIFigure);
            app.AppGrid.ColumnWidth = {'1x'};
            app.AppGrid.RowHeight = {'4x', 40};

            % Create ActionButtonGrid
            app.ActionButtonGrid = uigridlayout(app.AppGrid);
            app.ActionButtonGrid.ColumnWidth = {89, '1x', 89, 89};
            app.ActionButtonGrid.RowHeight = {22};
            app.ActionButtonGrid.Layout.Row = 2;
            app.ActionButtonGrid.Layout.Column = 1;

            % Create CancelButton
            app.CancelButton = uibutton(app.ActionButtonGrid, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Tag = 'CancelLabel:Text';
            app.CancelButton.Layout.Row = 1;
            app.CancelButton.Layout.Column = 4;
            app.CancelButton.Text = 'Cancel';

            % Create OkButton
            app.OkButton = uibutton(app.ActionButtonGrid, 'push');
            app.OkButton.ButtonPushedFcn = createCallbackFcn(app, @OkButtonPushed, true);
            app.OkButton.Tag = 'OkLabel:Text';
            app.OkButton.Layout.Row = 1;
            app.OkButton.Layout.Column = 3;
            app.OkButton.Text = 'Ok';

            % Create HelpButton
            app.HelpButton = uibutton(app.ActionButtonGrid, 'push');
            app.HelpButton.ButtonPushedFcn = createCallbackFcn(app, @HelpButtonPushed, true);
            app.HelpButton.Tag = 'HelpLabel:Text';
            app.HelpButton.Layout.Row = 1;
            app.HelpButton.Layout.Column = 1;
            app.HelpButton.Text = 'Help';

            % Create MetadataGrid
            app.MetadataGrid = uigridlayout(app.AppGrid);
            app.MetadataGrid.ColumnWidth = {120, 18, 39, 89, '1x', 18};
            app.MetadataGrid.RowHeight = {'fit', 0, 'fit', 22, 22, 22, 22, 22, 11, 22, 32, '100x', 22, 22, 22};
            app.MetadataGrid.Padding = [10 10 10 0];
            app.MetadataGrid.Layout.Row = 1;
            app.MetadataGrid.Layout.Column = 1;
            app.MetadataGrid.Scrollable = 'on';

            % Create ComponentLibraryAppearanceLabel
            app.ComponentLibraryAppearanceLabel = uilabel(app.MetadataGrid);
            app.ComponentLibraryAppearanceLabel.Tag = 'ComponentLibAppearanceLabel:Text';
            app.ComponentLibraryAppearanceLabel.FontWeight = 'bold';
            app.ComponentLibraryAppearanceLabel.Layout.Row = 5;
            app.ComponentLibraryAppearanceLabel.Layout.Column = [1 4];
            app.ComponentLibraryAppearanceLabel.Text = 'Component Library Appearance';

            % Create ComponentNameEditFieldLabel
            app.ComponentNameEditFieldLabel = uilabel(app.MetadataGrid);
            app.ComponentNameEditFieldLabel.Tag = 'NameLabel:Text';
            app.ComponentNameEditFieldLabel.Layout.Row = 6;
            app.ComponentNameEditFieldLabel.Layout.Column = 1;
            app.ComponentNameEditFieldLabel.Text = 'Name';

            % Create IconLabel
            app.IconLabel = uilabel(app.MetadataGrid);
            app.IconLabel.Tag = 'IconLabel:Text';
            app.IconLabel.Layout.Row = 8;
            app.IconLabel.Layout.Column = 1;
            app.IconLabel.Text = 'Icon';

            % Create ComponentName
            app.ComponentName = uieditfield(app.MetadataGrid, 'text');
            app.ComponentName.ValueChangedFcn = createCallbackFcn(app, @ComponentNameValueChanged, true);
            app.ComponentName.Layout.Row = 6;
            app.ComponentName.Layout.Column = [3 6];

            % Create Category
            app.Category = uidropdown(app.MetadataGrid);
            app.Category.Editable = 'on';
            app.Category.ValueChangedFcn = createCallbackFcn(app, @CategoryValueChanged, true);
            app.Category.Layout.Row = 7;
            app.Category.Layout.Column = [3 6];

            % Create Icon
            app.Icon = uiimage(app.MetadataGrid);
            app.Icon.ScaleMethod = 'scaledown';
            app.Icon.Layout.Row = 8;
            app.Icon.Layout.Column = 3;

            % Create BrowseIconButton
            app.BrowseIconButton = uibutton(app.MetadataGrid, 'push');
            app.BrowseIconButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseIconButtonPushed, true);
            app.BrowseIconButton.Tag = 'BrowseLabel:Text';
            app.BrowseIconButton.Layout.Row = 8;
            app.BrowseIconButton.Layout.Column = 4;
            app.BrowseIconButton.Text = 'Browse';

            % Create ComponentDetailsLabel
            app.ComponentDetailsLabel = uilabel(app.MetadataGrid);
            app.ComponentDetailsLabel.Tag = 'ComponentDetailsLabel:Text';
            app.ComponentDetailsLabel.FontWeight = 'bold';
            app.ComponentDetailsLabel.Layout.Row = 10;
            app.ComponentDetailsLabel.Layout.Column = [1 5];
            app.ComponentDetailsLabel.Text = 'Component Details';

            % Create DescriptionTextAreaLabel
            app.DescriptionTextAreaLabel = uilabel(app.MetadataGrid);
            app.DescriptionTextAreaLabel.Tag = 'DescriptionLabel:Text';
            app.DescriptionTextAreaLabel.VerticalAlignment = 'top';
            app.DescriptionTextAreaLabel.WordWrap = 'on';
            app.DescriptionTextAreaLabel.Layout.Row = 11;
            app.DescriptionTextAreaLabel.Layout.Column = 1;
            app.DescriptionTextAreaLabel.Text = 'Description';

            % Create Description
            app.Description = uitextarea(app.MetadataGrid);
            app.Description.Layout.Row = [11 12];
            app.Description.Layout.Column = [3 6];

            % Create VersionLabel
            app.VersionLabel = uilabel(app.MetadataGrid);
            app.VersionLabel.Tag = 'VersionLabel:Text';
            app.VersionLabel.Layout.Row = 13;
            app.VersionLabel.Layout.Column = 1;
            app.VersionLabel.Text = 'Version';

            % Create Version
            app.Version = uieditfield(app.MetadataGrid, 'text');
            app.Version.ValueChangedFcn = createCallbackFcn(app, @VersionValueChanged, true);
            app.Version.Layout.Row = 13;
            app.Version.Layout.Column = 3;
            app.Version.Value = '1.0';

            % Create AuthorsNameEditFieldLabel
            app.AuthorsNameEditFieldLabel = uilabel(app.MetadataGrid);
            app.AuthorsNameEditFieldLabel.Tag = 'AuthorNameLabel:Text';
            app.AuthorsNameEditFieldLabel.Layout.Row = 14;
            app.AuthorsNameEditFieldLabel.Layout.Column = 1;
            app.AuthorsNameEditFieldLabel.Text = 'Author''s Name';

            % Create AuthorName
            app.AuthorName = uieditfield(app.MetadataGrid, 'text');
            app.AuthorName.Layout.Row = 14;
            app.AuthorName.Layout.Column = [3 6];

            % Create AuthorEmail
            app.AuthorEmail = uieditfield(app.MetadataGrid, 'text');
            app.AuthorEmail.ValueChangedFcn = createCallbackFcn(app, @AuthorEmailValueChanged, true);
            app.AuthorEmail.Layout.Row = 15;
            app.AuthorEmail.Layout.Column = [3 6];

            % Create AuthorEmailLabel
            app.AuthorEmailLabel = uilabel(app.MetadataGrid);
            app.AuthorEmailLabel.Tag = 'AuthorEmailLabel:Text';
            app.AuthorEmailLabel.VerticalAlignment = 'top';
            app.AuthorEmailLabel.WordWrap = 'on';
            app.AuthorEmailLabel.Layout.Row = 15;
            app.AuthorEmailLabel.Layout.Column = 1;
            app.AuthorEmailLabel.Text = 'Author''s Email';

            % Create ComponentFileLabel
            app.ComponentFileLabel = uilabel(app.MetadataGrid);
            app.ComponentFileLabel.Tag = 'ComponentFileLabel:Text';
            app.ComponentFileLabel.FontWeight = 'bold';
            app.ComponentFileLabel.Layout.Row = 3;
            app.ComponentFileLabel.Layout.Column = 1;
            app.ComponentFileLabel.Text = 'Component File';

            % Create FilePath
            app.FilePath = uilabel(app.MetadataGrid);
            app.FilePath.Layout.Row = 4;
            app.FilePath.Layout.Column = [1 6];
            app.FilePath.Text = '';

            % Create ComponentDetailsHelpIcon
            app.ComponentDetailsHelpIcon = uiimage(app.MetadataGrid);
            app.ComponentDetailsHelpIcon.Tag = 'ComponentDetailsHelp:Tooltip';
            app.ComponentDetailsHelpIcon.Tooltip = {''};
            app.ComponentDetailsHelpIcon.Layout.Row = 10;
            app.ComponentDetailsHelpIcon.Layout.Column = 2;
            app.ComponentDetailsHelpIcon.HorizontalAlignment = 'right';

            % Create CategoryGrid
            app.CategoryGrid = uigridlayout(app.MetadataGrid);
            app.CategoryGrid.RowHeight = {18};
            app.CategoryGrid.Padding = [0 0 0 0];
            app.CategoryGrid.Layout.Row = 7;
            app.CategoryGrid.Layout.Column = 1;

            % Create CategoryHelpIcon
            app.CategoryHelpIcon = uiimage(app.CategoryGrid);
            app.CategoryHelpIcon.Tag = 'CategoryHelp:Tooltip';
            app.CategoryHelpIcon.Tooltip = {''};
            app.CategoryHelpIcon.Layout.Row = 1;
            app.CategoryHelpIcon.Layout.Column = 2;

            % Create CategoryEditFieldLabel
            app.CategoryEditFieldLabel = uilabel(app.CategoryGrid);
            app.CategoryEditFieldLabel.Tag = 'CategoryLabel:Text';
            app.CategoryEditFieldLabel.Layout.Row = 1;
            app.CategoryEditFieldLabel.Layout.Column = 1;
            app.CategoryEditFieldLabel.Text = 'Category';

            % Create HeadingLabel
            app.HeadingLabel = uilabel(app.MetadataGrid);
            app.HeadingLabel.Tag = 'HeadingLabel:Text';
            app.HeadingLabel.WordWrap = 'on';
            app.HeadingLabel.Layout.Row = 1;
            app.HeadingLabel.Layout.Column = [1 6];
            app.HeadingLabel.Text = 'To configure the component for use in App Designer, specify its information and add its folder to the MATLAB path.';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MetadataUI_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end