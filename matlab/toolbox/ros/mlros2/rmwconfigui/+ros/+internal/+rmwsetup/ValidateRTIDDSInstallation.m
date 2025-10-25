classdef ValidateRTIDDSInstallation < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % ValidateRTIDDSInstallation - Screen provides the instructions to validate
    % RTI Connext DDS Professional installation.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        %Description text for the screen
        ScreenDescription
        % DDSInstallationEditText - Text box area to show install location that has
        % to be validated.
        DDSInstallationEditText
        % DDSInstallationBrowser - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        DDSInstallationBrowser
        % ValidateDDSInstallationButton - Button that Validates the DDS Installation.
        ValidateDDSInstallationButton
        % Status Table to show the status of validation
        StatusTable
    end

    properties (Access = private)
        % Spinner widget
        BusySpinner
        % Path to the DDS Installation
        DDSDir
        % DDSEnvironment object containing DDS Installation preferences
        DDSEnvironment
    end

    methods

        function obj = ValidateRTIDDSInstallation(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})

            obj.NextButton.Enable = 'off';
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:ScreenTwoTitle').getString();
            %Default position is [20 7 470 25], But increasing it to accommodate the lengthier title
            obj.Title.Position = [20 7 550 25];

            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 110 420 270];
            obj.ScreenDescription.Text = message('ros:mlros2:rmwsetup:VerifyDDSInstallationSteps').getString();
            obj.ConfigurationInstructions.Visible = 'off';

            %Set DDSInstallationEditText Properties
            obj.DDSInstallationEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.DDSInstallationEditText.ValueChangedFcn = @obj.editCallbackFcn;
            obj.DDSInstallationEditText.Position = [20 220 300 20];
            obj.DDSInstallationEditText.TextAlignment = 'left';

            % Create a handle to DDSEnvironment object
            obj.DDSEnvironment = ros.internal.DDSEnvironment();
            if isempty(obj.DDSEnvironment.DDSRoot)
                obj.DDSInstallationEditText.Text = getDefaultDDSDir(obj);
            else
                getCurrentScreenValues(obj);
            end

            % Set DDSInstallationBrowser button Properties
            obj.DDSInstallationBrowser = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.DDSInstallationBrowser.Text = message('ros:mlros2:rmwsetup:BrowseButton').getString;
            obj.DDSInstallationBrowser.Position = [340 218 70 24];
            obj.DDSInstallationBrowser.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            % Set callback when finish button is pushed
            obj.DDSInstallationBrowser.ButtonPushedFcn = @obj.ddsRootBrowserFcn;

            %Set ValidateDDSInstallationButton properties
            obj.ValidateDDSInstallationButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateDDSInstallationButton.Text = message('ros:mlros2:rmwsetup:VerifyInstallationButton').getString;
            obj.ValidateDDSInstallationButton.Position = [20 170 150 24];
            obj.ValidateDDSInstallationButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateDDSInstallationButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Set callback when finish button is pushed
            obj.ValidateDDSInstallationButton.ButtonPushedFcn = @obj.validateButtonCallback;

            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [20 450];
            obj.StatusTable.Position = [20 80 450 60];    

            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';

            % Set the Help Text
            obj.HelpText.WhatToConsider =  message('ros:mlros2:rmwsetup:VerifyDDSInstallationHelp').getString();

        end

        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
        end

        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.SelectRMWImplementation';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            %Show screen to Build the RMW Implementation
            out = 'ros.internal.rmwsetup.BuildRMWConnextPackage';
        end%End of getNextScreenID function

    end

    methods(Access = 'private')
        function editCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.DDSInstallationEditText.Text,filesep),...
                    fullfile(obj.DDSDir,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
            end
            drawnow;
        end

        function ddsRootBrowserFcn(obj, ~, ~)
            % ddsRootBrowserFcn - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.DDSInstallationEditText.Text
            dir = uigetdir(obj.DDSInstallationEditText.Text, message('ros:mlros2:rmwsetup:BrowseDDSInstallation').getString());

            % App loses focus when user cancels out of uigetfile. Set focus back to app
            uiFigHandle = findobjinternal(0,'Type','Figure','Name','ROS Middleware Configuration');
            if ~isempty(uiFigHandle)
                focus(uiFigHandle);
            end

            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (DDSInstallationEditText.Text).
                obj.DDSInstallationEditText.Text = dir;
            end
        end

        function getCurrentScreenValues(obj)
            obj.DDSInstallationEditText.Text = ...
                strtrim(obj.DDSEnvironment.DDSRoot);
        end

        function validateButtonCallback(obj,~,~)
            % validateButtonCallback - Callback when Verify installation
            % button is clicked

            %Enable the BusySpinner while DDS validation is taking place
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:DDSInstallation_Validation').getString();
            obj.BusySpinner.show();
            drawnow;
            ValidateSuccess = false;
            rtiInstallArchName = '';
            try
                %Check if the folder is valid
                if ~isfolder(fullfile(obj.DDSInstallationEditText.Text))
                    error(message('ros:mlros2:rmwsetup:SelectDDSInstallation_InvalidFolder').getString());
                end

                if ispc
                    if ~isfile(fullfile(obj.DDSInstallationEditText.Text, 'resource','scripts','rtisetenv_x64Win64VS2017.bat'))
                        error(message('ros:mlros2:rmwsetup:SelectDDSInstallation_InvalidFolder').getString());
                    end
                    rtiInstallArchName = 'x64Win64VS2017';
                else
                    scriptsDir = fullfile(obj.DDSInstallationEditText.Text, 'resource','scripts');
                    dirInfo = dir(scriptsDir);
                    whichScripts = ~ismember({dirInfo.name}, {'.', '..'});
                    pattern = '\w*.*bash$';
                    for iScript = find(whichScripts)
                        scriptName = extract(dirInfo(iScript).name, regexpPattern(pattern));
                        if ~isempty(scriptName)
                            break;
                        end
                    end

                    % Extract Architecture Name present from the script
                    [~,rtiInstallArchName] = system(['echo ' scriptName{1} ' | sed -e "s/.*rtisetenv_\(.*\).bash/\1/"']);
                    rtiInstallArchName = rtiInstallArchName(1:end-1);
                    if ~isfile(fullfile(obj.DDSInstallationEditText.Text, 'resource','scripts',scriptName{1}))
                        error(message('ros:mlros2:rmwsetup:SelectDDSInstallation_InvalidFolder').getString());
                    end
                end

                % Verify the DDS Installation
                obj.verifyDDSInstallation(rtiInstallArchName);
                obj.DDSDir = obj.DDSInstallationEditText.Text;
                ValidateSuccess = true;
            catch EX
                obj.EnableStatusTable(EX.identifier,EX.message);
            end

            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            drawnow;

            if ValidateSuccess
                obj.NextButton.Enable = 'on';
                % Save DDS environment after successful validation of
                % DDS installation
                obj.DDSEnvironment.DDSHome = obj.DDSInstallationEditText.Text;
                obj.DDSEnvironment.checkAndCreatePref(rtiInstallArchName);

                obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:DDSValidationSuccessStatus').getString);
            else
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
        end%End of ValidateButton_callback

        function verifyDDSInstallation(obj,rtiInstallArchName)
            %verifyDDSInstallation - Validates the folder by checking
            %whether libraries, scripts and license files are present.
            

            libndds = containers.Map({'win64','maci64','maca64','glnxa64'},...
                                {'ndds*.dll','libndds*.dylib','libndds*.dylib','libndds*.so'});
            librti = containers.Map({'win64','maci64','maca64','glnxa64'},...
                                {'rti*.dll','librti*.dylib','librti*.dylib','librti*.so'});
            binrti = containers.Map({'win64','maci64','maca64','glnxa64'},...
                                {'rti*.bat','rti*.sh','rti*.sh','rti*.sh'});

            if isempty(dir(fullfile(obj.DDSInstallationEditText.Text, 'lib',rtiInstallArchName, libndds(computer('arch'))))) ...
                && isempty(dir(fullfile(obj.DDSInstallationEditText.Text, 'lib',rtiInstallArchName, librti(computer('arch'))))) ...
                && isempty(dir(fullfile(obj.DDSInstallationEditText.Text, 'bin',rtiInstallArchName, binrti(computer('arch')))))
                error(message('ros:mlros2:rmwsetup:SelectDDSInstallation_InvalidFolder').getString());
            end

            if ~isfile(fullfile(obj.DDSInstallationEditText.Text, 'rti_license.dat'))
               error(message('ros:mlros2:rmwsetup:InvalidLicense').getString());
            end
        end

        function EnableStatusTable(obj,message_id,message_detail)
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Border='off';
            obj.StatusTable.Enable = 'on';
            obj.StatusTable.Steps = {message_detail};
            drawnow;
            switch message_id
                case 'success'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                otherwise
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
            end
            drawnow;
        end%End of EnableStatusTable

        function defaultInstallLocation = getDefaultDDSDir(~)
            %getDefaultDDSDir - Shows the default installation paths if the
            %user is configuring the ROS middleware for the first time.

            DefaultLocationsMap = containers.Map;
            DefaultLocationsMap('win64')  = "C:\Program Files\rti_connext_dds-6.0.1";
            DefaultLocationsMap('glnxa64') = "/opt/rti_connext_dds-6.0.1";
            DefaultLocationsMap('maci64')  = "/Applications/rti_connext_dds-6.0.1";
            DefaultLocationsMap('maca64')  = "/Applications/rti_connext_dds-6.0.1";
            defaultInstallLocation = DefaultLocationsMap(computer('arch'));
        end
    end
end