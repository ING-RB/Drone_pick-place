classdef GUIDEAppMaintenanceOptions_exported < matlab.apps.AppBase
    %GUIDEAPPMAINTENANCEOPTIONS_EXPORTED Explore options for the maintenance of
    %GUIDE Apps after GUIDE is removed.
    %   Options for app maintenance include Export to a MATLAB File and
    %   Migrating to an App Designer app.
    %   
    %   Copyright 2020-2025 The MathWorks, Inc.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        Panel                        matlab.ui.container.Panel
        ExportGridLayout             matlab.ui.container.GridLayout
        ExportButton                 matlab.ui.control.Button
        ExportBrowseButton           matlab.ui.control.Button
        ExportEditField              matlab.ui.control.EditField
        ExportChooseAppLabel         matlab.ui.control.Label
        ExportHeader                 matlab.ui.control.Label
        GridLayout                   matlab.ui.container.GridLayout
        MigratePanel                 matlab.ui.container.Panel
        GridLayout3                  matlab.ui.container.GridLayout
        MigrateButton                matlab.ui.control.Button
        MigrateBrowseButton          matlab.ui.control.Button
        MigrateEditField             matlab.ui.control.EditField
        MigrateChooseAppLabel        matlab.ui.control.Label
        InstallPanel                 matlab.ui.container.Panel
        GridLayout4                  matlab.ui.container.GridLayout
        WarningImageLarge            matlab.ui.control.Image
        InstallLabel_RegularText     matlab.ui.control.Label
        InstallSupportPackageButton  matlab.ui.control.Button
        MigrateHeader                matlab.ui.control.Label
        MigrateImage                 matlab.ui.control.Image
        CancelButton                 matlab.ui.control.Button
        HelpButton                   matlab.ui.control.Button
    end


    properties (Access = private)
        ExportAppName
        ExportAppFullFileName
        MigrateAppName
        MigrateAppFullFileName
        Accordion
        AccordionPanel
    end

    methods (Access = private)

        function  setupApp(app)
            
            import matlab.internal.capability.Capability;
            
            % Move the UIFigure to the center of the screen.
            if Capability.isSupported(Capability.LocalClient)
                % movegui is not fully supported in MATLAB Online (g1946357)
                movegui(app.UIFigure, 'center');
            end

            app.MigrateImage.ImageSource = '+guide/+internal/MigrateToAppDesigner.png';
            app.WarningImageLarge.ImageSource =  '+guide/+internal/info.svg';
            
            app.assignInternationalizedStrings();
            drawnow;

            % If the Migration AddOn is installed, setup components to give
            % users options to migrate.  If it is not installed, setup components
            % that prompt users to install it.
            if appdesservices.internal.appmigration.isGUIDEAppMigrationAddonInstalled()
                app.setupMigrateActionComponents();
            else
                app.setupMigrateInstallComponents();
            end

            % Set initial placeholder text in the export and migrate edit
            % fields.
            app.ExportEditField.Value = getString(message('MATLAB:guide:SelectFigFile'));
            app.MigrateEditField.Value = getString(message('MATLAB:guide:SelectFigFile'));

            % Add according for export section
            accordingPanelTitle = getString(message('MATLAB:guide:guideremovaloptions:ExportTitle'));
            app.Accordion = matlab.ui.container.internal.Accordion('Parent', app.GridLayout);
            app.Accordion.Layout.Row = 4;
            app.Accordion.Layout.Column = [1 2];
            app.AccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent', app.Accordion,...
                'Title', accordingPanelTitle, 'Collapsed', true);
            app.ExportGridLayout.Parent = app.AccordionPanel;

            % Enable the app to resize larger when the according panel is
            % expanded
            matlab.ui.internal.PositionUtils.fitToContent(app.UIFigure, 'topleft');
        end
        
        function enableExportEditFieldAndActionButton(app)
            % Enable the export edit field and enable the export button.

            app.ExportEditField.Enable = 'on';
            app.ExportEditField.FontAngle = 'normal';
            app.ExportButton.Enable = 'on';
        end

        function disableExportEditFieldAndActionButton(app)
            % Disable the export edit field and disable the export button.

            app.ExportEditField.Enable = 'off';
            app.ExportEditField.Value = getString(message('MATLAB:guide:SelectFigFile'));
            app.ExportEditField.FontAngle = 'italic';
            app.ExportButton.Enable = 'off';
        end

        function enableMigrateEditFieldAndActionButton(app)
            % Enable the migrate edit field and enable the migrate button.

            app.MigrateEditField.Enable = 'on';
            app.MigrateEditField.FontAngle = 'normal';
            app.MigrateButton.Enable = 'on';
        end

        function disableMigrateEditFieldAndActionButton(app)
            % Disable the migrate edit field and disable the migrate button.

            app.MigrateEditField.Enable = 'off';
            app.MigrateEditField.Value = getString(message('MATLAB:guide:SelectFigFile'));
            app.MigrateEditField.FontAngle = 'italic';
            app.MigrateButton.Enable = 'off';
        end

        function  setupMigrateInstallComponents(app)
            % Setup the components that tell users that the support package
            % is not installed and prompt them to install it.

            app.InstallPanel.Visible = 'on';
            app.MigratePanel.Visible = 'off';
        end

        function  setupMigrateActionComponents(app)
            % Setup the components that allow users to select a GUIDE
            % FIG file and to migrate that FIG file.

            app.InstallPanel.Visible = 'off';
            app.MigratePanel.Visible = 'on';
        end
        
        function assignInternationalizedStrings(app)
            % This method is used to assign internationalized strings to
            % the text in the app.  See g2405656
            
            app.MigrateHeader.Text = getString(message('MATLAB:guide:guideremovaloptions:MigrateHeader'));
            app.ExportHeader.Text = getString(message('MATLAB:guide:guideremovaloptions:ExportHeader'));
            app.ExportChooseAppLabel.Text = getString(message('MATLAB:guide:guideremovaloptions:ExportChooseAppLabel'));
            app.MigrateChooseAppLabel.Text = getString(message('MATLAB:guide:guideremovaloptions:MigrateChooseAppLabel'));
            app.InstallSupportPackageButton.Text = getString(message('MATLAB:guide:guideremovaloptions:InstallSupportPackageButton'));
            app.ExportEditField.Value = getString(message('MATLAB:guide:guideremovaloptions:EditFieldPlaceholderText'));
            app.MigrateEditField.Value = getString(message('MATLAB:guide:guideremovaloptions:EditFieldPlaceholderText'));
            app.ExportButton.Text = getString(message('MATLAB:guide:guideremovaloptions:ExportButton'));
            app.MigrateButton.Text = getString(message('MATLAB:guide:guideremovaloptions:MigrateButton'));
            app.ExportBrowseButton.Text = getString(message('MATLAB:guide:guideremovaloptions:BrowseButtonText'));
            app.MigrateBrowseButton.Text = getString(message('MATLAB:guide:guideremovaloptions:BrowseButtonText'));
            app.HelpButton.Text = getString(message('MATLAB:guide:guideremovaloptions:HelpButton'));
            app.CancelButton.Text = getString(message('MATLAB:guide:guideremovaloptions:CancelButton'));
            app.InstallLabel_RegularText.Text = getString(message('MATLAB:guide:guideremovaloptions:InstallLabel'));
            app.UIFigure.Name = getString(message('MATLAB:guide:guideremovaloptions:FigureTitle'));
        end
    end
    
    methods
        function configureApp(app, varargin)
            % Configures the edit fields text based on varargin. This must
            % be a public method so that the external function
            % launchGUIDEAppMaintenanceOptions.m can call this.
            
            % If a FIG file was inputted as an argument, then pre-populate 
            % the edit fields and enable the buttons.
            if nargin > 1 && ~isempty(varargin{1})
                figFullFileName = varargin{1};
                app.ExportEditField.Value = figFullFileName;
                app.MigrateEditField.Value = figFullFileName;
                app.enableExportEditFieldAndActionButton();
                app.enableMigrateEditFieldAndActionButton();
            end

            % A second input argument is used to specify which
            % content is opened by default.  If a second argument was specified,
            % check if the input contains the phrase 'export' (this phrase covers
            % inputs of both 'export' or 'exportation').  If the input contains
            % the phrase, expand the export accordion panel.
            if nargin >2 && ~isempty(varargin{2}) && contains(varargin{2},'export','IgnoreCase',true)
                app.AccordionPanel.expand();
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            % Turn UIFigure Visibility 'off' during setup and
            % configuration.
            app.UIFigure.Visible = 'off';

            setupApp(app)
            configureApp(app, varargin{:});
            
            % After setup and configuration, make the UIFigure Visible.
            app.UIFigure.Visible = 'on';
        end

        % Button pushed function: MigrateBrowseButton
        function MigrateBrowseButtonPushed(app, event)
            [filename, pathname] = uigetfile('*.fig', getString(message('MATLAB:guide:SelectFigFile')));

            % Workaround uigetfile focus issue (g1598963) by forcing focus back to app
            figure(app.UIFigure);

            fullFileName = fullfile(pathname, filename);

            if ~isequal(filename, 0)
                app.MigrateEditField.Value = fullFileName;
                app.enableMigrateEditFieldAndActionButton();
            end

            app.MigrateAppName = filename;
            app.MigrateAppFullFileName = fullFileName;
        end

        % Button pushed function: ExportBrowseButton
        function ExportBrowseButtonPushed(app, event)
            [filename, pathname] = uigetfile('*.fig', getString(message('MATLAB:guide:SelectFigFile')));

            % Workaround uigetfile focus issue (g1598963) by forcing focus back to app
            figure(app.UIFigure);

            fullFileName = fullfile(pathname, filename);
            if ~isequal(filename, 0)
                app.ExportEditField.Value = fullFileName;
                app.enableExportEditFieldAndActionButton();
            end

            app.ExportAppName = filename;
            app.ExportAppFullFileName = fullFileName;
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)

            % Check if user edited the file name after loading a file using browse
            editFieldValue = app.ExportEditField.Value;

            % Update app name and fullfilename with edit field value
            [~, fileName] = fileparts(editFieldValue);
            app.ExportAppName = fileName;
            app.ExportAppFullFileName = editFieldValue;

            try 
                % Export the GUIDE App
                export.internal.exportGUIDEApp(app.ExportAppFullFileName)
                
            catch exception
                knownExceptionIdentifiers = {'appmigration:appmigration:InvalidFileName',...
                    'appmigration:appmigration:InvalidCodeFileName',...
                    'appmigration:appmigration:NotGuideCreatedApp',...
                    'appmigration:appmigration:NotWritableLocation',...
                    'MATLAB:appdesigner:appdesigner:InvalidInput',...
                    'MATLAB:appdesigner:appdesigner:FileNameFailsIsKeyword',...
                    'MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName',...
                    'MATLAB:appdesigner:appdesigner:InvalidGeneralFileExtension',...
                    'MATLAB:appdesigner:appdesigner:InvalidFilePath'};

                if any(strcmp(exception.identifier,knownExceptionIdentifiers))
                    title = getString(message('MATLAB:guide:guideremovaloptions:ExportAlertTitle'));
                    uialert(app.UIFigure,exception.message,title);
                    return;
                else
                    rethrow(exception);
                end
            end

        end

        % Button pushed function: MigrateButton
        function MigrateButtonPushed(app, event)

            % Check if user edited the file name after loading a file using browse
            editFieldValue = app.MigrateEditField.Value;

            % update app name and fullfilename with edit field value
            [~, fileName] = fileparts(editFieldValue);
            app.MigrateAppName = fileName;
            app.MigrateAppFullFileName = editFieldValue;

            try
                converter = appmigration.internal.GUIDEAppConverter(app.MigrateAppFullFileName);

                progressDialogMessage = getString(message('appmigration:appmigration:ProgressDialogMessage', converter.MLAPPFileName));
                progressDialog = uiprogressdlg(app.UIFigure, 'Message', progressDialogMessage, 'Indeterminate', 'on');

                conversionResults = converter.convert();

            catch exception
                knownExceptionIdentifiers = {'appmigration:appmigration:InvalidFileName',...
                    'appmigration:appmigration:InvalidCodeFileName',...
                    'appmigration:appmigration:NotGuideCreatedApp',...
                    'appmigration:appmigration:NotWritableLocation',...
                    'MATLAB:appdesigner:appdesigner:InvalidInput',...
                    'MATLAB:appdesigner:appdesigner:FileNameFailsIsKeyword',...
                    'MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName',...
                    'MATLAB:appdesigner:appdesigner:InvalidGeneralFileExtension',...
                    'MATLAB:appdesigner:appdesigner:InvalidFilePath'};

                if any(strcmp(exception.identifier,knownExceptionIdentifiers))
                    title = getString(message('appmigration:appmigration:AppTitle'));
                    uialert(app.UIFigure,exception.message,title);
                    return;
                else
                    rethrow(exception);
                end
            end

            reportGenerator = appmigration.internal.AppConversionReportGenerator(converter.FigFullFileName, conversionResults);
            reportGenerator.generateHTMLReport();

            % Open the app in App Designer and start the tutorial
            ade = appdesigner.internal.application.getAppDesignEnvironment();
            ade.openTutorial('AppMigration', conversionResults.MLAPPFullFileName);

            delete(progressDialog);
        end

        % Value changed function: ExportEditField
        function ExportEditFieldValueChanged(app, event)
            value = app.ExportEditField.Value;

            if isempty(value)
                app.disableExportEditFieldAndActionButton();
                app.ExportAppName = '';
                app.ExportAppFullFileName = '';
            end
        end

        % Value changed function: MigrateEditField
        function MigrateEditFieldValueChanged(app, event)
            value = app.MigrateEditField.Value;

            if isempty(value)
                app.disableMigrateEditFieldAndActionButton();
                app.MigrateAppName = '';
                app.MigrateAppFullFileName = '';
            end
        end

        % Button pushed function: InstallSupportPackageButton
        function InstallSupportPackageButtonPushed(app, event)
            appdesservices.internal.appmigration.showAppMigrationAddon();

            delete(app);
        end

        % Button pushed function: HelpButton
        function HelpButtonPushed(app, event)
            helpview('matlab', 'diffappdguide');
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 802 278];
            app.UIFigure.Name = 'GUIDE to App Designer Migration Tool';
            app.UIFigure.Resize = 'off';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {100, '1x', 180, 100};
            app.GridLayout.RowHeight = {'fit', 80, 80, 'fit', 22};
            app.GridLayout.Padding = [15 15 15 15];

            % Create HelpButton
            app.HelpButton = uibutton(app.GridLayout, 'push');
            app.HelpButton.ButtonPushedFcn = createCallbackFcn(app, @HelpButtonPushed, true);
            app.HelpButton.Layout.Row = 5;
            app.HelpButton.Layout.Column = 1;
            app.HelpButton.Text = 'Help';

            % Create CancelButton
            app.CancelButton = uibutton(app.GridLayout, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Layout.Row = 5;
            app.CancelButton.Layout.Column = 4;
            app.CancelButton.Text = 'Cancel';

            % Create MigrateImage
            app.MigrateImage = uiimage(app.GridLayout);
            app.MigrateImage.Layout.Row = [2 3];
            app.MigrateImage.Layout.Column = [3 4];

            % Create MigrateHeader
            app.MigrateHeader = uilabel(app.GridLayout);
            app.MigrateHeader.VerticalAlignment = 'top';
            app.MigrateHeader.WordWrap = 'on';
            app.MigrateHeader.Layout.Row = 1;
            app.MigrateHeader.Layout.Column = [1 4];
            app.MigrateHeader.Text = 'Migrating your app converts your GUIDE app to a new App Designer app.';

            % Create InstallPanel
            app.InstallPanel = uipanel(app.GridLayout);
            app.InstallPanel.AutoResizeChildren = 'off';
            app.InstallPanel.BorderWidth = 0;
            app.InstallPanel.Layout.Row = [2 3];
            app.InstallPanel.Layout.Column = [1 2];

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.InstallPanel);
            app.GridLayout4.ColumnWidth = {37, 180, 200};
            app.GridLayout4.RowHeight = {'1x', 41, 'fit', '1x'};

            % Create InstallSupportPackageButton
            app.InstallSupportPackageButton = uibutton(app.GridLayout4, 'push');
            app.InstallSupportPackageButton.ButtonPushedFcn = createCallbackFcn(app, @InstallSupportPackageButtonPushed, true);
            app.InstallSupportPackageButton.Layout.Row = 3;
            app.InstallSupportPackageButton.Layout.Column = 3;
            app.InstallSupportPackageButton.Text = 'Install Support Package';

            % Create InstallLabel_RegularText
            app.InstallLabel_RegularText = uilabel(app.GridLayout4);
            app.InstallLabel_RegularText.VerticalAlignment = 'top';
            app.InstallLabel_RegularText.WordWrap = 'on';
            app.InstallLabel_RegularText.Layout.Row = 2;
            app.InstallLabel_RegularText.Layout.Column = [2 3];
            app.InstallLabel_RegularText.Text = 'Install the "GUIDE to App Designer Migration Tool for MATLAB" Support Package before migrating an app.';

            % Create WarningImageLarge
            app.WarningImageLarge = uiimage(app.GridLayout4);
            app.WarningImageLarge.Layout.Row = 2;
            app.WarningImageLarge.Layout.Column = 1;

            % Create MigratePanel
            app.MigratePanel = uipanel(app.GridLayout);
            app.MigratePanel.AutoResizeChildren = 'off';
            app.MigratePanel.BorderWidth = 0;
            app.MigratePanel.Layout.Row = [2 3];
            app.MigratePanel.Layout.Column = [1 2];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.MigratePanel);
            app.GridLayout3.ColumnWidth = {363, 100};
            app.GridLayout3.RowHeight = {'1x', 'fit', 'fit', 'fit', '1x'};
            app.GridLayout3.Padding = [0 0 0 0];

            % Create MigrateChooseAppLabel
            app.MigrateChooseAppLabel = uilabel(app.GridLayout3);
            app.MigrateChooseAppLabel.VerticalAlignment = 'top';
            app.MigrateChooseAppLabel.WordWrap = 'on';
            app.MigrateChooseAppLabel.FontWeight = 'bold';
            app.MigrateChooseAppLabel.Layout.Row = 2;
            app.MigrateChooseAppLabel.Layout.Column = 1;
            app.MigrateChooseAppLabel.Text = 'Choose an app to migrate:';

            % Create MigrateEditField
            app.MigrateEditField = uieditfield(app.GridLayout3, 'text');
            app.MigrateEditField.ValueChangedFcn = createCallbackFcn(app, @MigrateEditFieldValueChanged, true);
            app.MigrateEditField.FontAngle = 'italic';
            app.MigrateEditField.Enable = 'off';
            app.MigrateEditField.Layout.Row = 3;
            app.MigrateEditField.Layout.Column = 1;
            app.MigrateEditField.Value = 'Select a GUIDE .fig file';

            % Create MigrateBrowseButton
            app.MigrateBrowseButton = uibutton(app.GridLayout3, 'push');
            app.MigrateBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @MigrateBrowseButtonPushed, true);
            app.MigrateBrowseButton.Layout.Row = 3;
            app.MigrateBrowseButton.Layout.Column = 2;
            app.MigrateBrowseButton.Text = 'Browse...';

            % Create MigrateButton
            app.MigrateButton = uibutton(app.GridLayout3, 'push');
            app.MigrateButton.ButtonPushedFcn = createCallbackFcn(app, @MigrateButtonPushed, true);
            app.MigrateButton.Enable = 'off';
            app.MigrateButton.Layout.Row = 4;
            app.MigrateButton.Layout.Column = 2;
            app.MigrateButton.Text = 'Migrate';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.Position = [36 -213 464 147];

            % Create ExportGridLayout
            app.ExportGridLayout = uigridlayout(app.Panel);
            app.ExportGridLayout.ColumnWidth = {350, 100};
            app.ExportGridLayout.RowHeight = {'fit', 5, 'fit', 'fit', 'fit'};
            app.ExportGridLayout.RowSpacing = 5;
            app.ExportGridLayout.Padding = [0 0 0 10];

            % Create ExportHeader
            app.ExportHeader = uilabel(app.ExportGridLayout);
            app.ExportHeader.Layout.Row = 1;
            app.ExportHeader.Layout.Column = [1 2];
            app.ExportHeader.Text = 'Exporting converts your GUIDE app to a new, single MATLAB code file.';

            % Create ExportChooseAppLabel
            app.ExportChooseAppLabel = uilabel(app.ExportGridLayout);
            app.ExportChooseAppLabel.VerticalAlignment = 'top';
            app.ExportChooseAppLabel.WordWrap = 'on';
            app.ExportChooseAppLabel.FontWeight = 'bold';
            app.ExportChooseAppLabel.Layout.Row = 3;
            app.ExportChooseAppLabel.Layout.Column = [1 2];
            app.ExportChooseAppLabel.Text = 'Choose an app to export:';

            % Create ExportEditField
            app.ExportEditField = uieditfield(app.ExportGridLayout, 'text');
            app.ExportEditField.ValueChangedFcn = createCallbackFcn(app, @ExportEditFieldValueChanged, true);
            app.ExportEditField.FontAngle = 'italic';
            app.ExportEditField.Enable = 'off';
            app.ExportEditField.Layout.Row = 4;
            app.ExportEditField.Layout.Column = 1;
            app.ExportEditField.Value = 'Select a GUIDE .fig file';

            % Create ExportBrowseButton
            app.ExportBrowseButton = uibutton(app.ExportGridLayout, 'push');
            app.ExportBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @ExportBrowseButtonPushed, true);
            app.ExportBrowseButton.Layout.Row = 4;
            app.ExportBrowseButton.Layout.Column = 2;
            app.ExportBrowseButton.Text = 'Browse...';

            % Create ExportButton
            app.ExportButton = uibutton(app.ExportGridLayout, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Enable = 'off';
            app.ExportButton.Layout.Row = 5;
            app.ExportButton.Layout.Column = 2;
            app.ExportButton.Text = 'Export';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUIDEAppMaintenanceOptions_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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