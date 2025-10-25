classdef ValidateIceoryxInstallation < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % ValidateIceoryxInstallation - Screen provides the instructions to validate
    % Eclipse Iceoryx installation.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        %Description text for the screen
        ScreenDescription
        % IceoryxInstallationEditText - Text box area to show iceoryx install
        % location that has to be validated.
        IceoryxInstallationEditText
        % IceoryxInstallationBrowser - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        IceoryxInstallationBrowser
        % ValidateIceoryxInstallationButton - Button that Validates the Iceoryx Installation.
        ValidateIceoryxInstallationButton
        % Status Table to show the status of validation
        StatusTable
    end

    properties (Access = private)
        % Spinner widget
        BusySpinner
        % Path to the Iceoryx Installation
        IceoryxDir
        % IceoryxEnvironment object containing iceoryx Installation preferences
        IceoryxEnvironment
    end

    methods
        function obj = ValidateIceoryxInstallation(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})

            obj.NextButton.Enable = 'off';
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:IceoryxValidationScreenTitle').getString();
            %Default position is [20 7 470 25], But increasing it to accommodate the lengthier title
            obj.Title.Position = [20 7 550 25];

            % Set Description Properties
            obj.ScreenDescription = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenDescription.Position = [20 110 420 270];
            obj.ScreenDescription.Text = message('ros:mlros2:rmwsetup:VerifyIceoryxInstallationSteps').getString();
            obj.ConfigurationInstructions.Visible = 'off';

            %Set IceoryxInstallationEditText Properties
            obj.IceoryxInstallationEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.IceoryxInstallationEditText.ValueChangedFcn = @obj.editCallbackFcn;
            obj.IceoryxInstallationEditText.Position = [20 220 300 20];
            obj.IceoryxInstallationEditText.TextAlignment = 'left';

            % Create a handle to IceoryxEnvironment object
            obj.IceoryxEnvironment = ros.internal.IceoryxEnvironment();
            if ~isempty(obj.IceoryxEnvironment.IceoryxRoot)
                getCurrentScreenValues(obj);
            end

            % Set IceoryxInstallationBrowser button Properties
            obj.IceoryxInstallationBrowser = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.IceoryxInstallationBrowser.Text = message('ros:mlros2:rmwsetup:BrowseButton').getString;
            obj.IceoryxInstallationBrowser.Position = [340 218 70 24];
            obj.IceoryxInstallationBrowser.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            % Set callback when finish button is pushed
            obj.IceoryxInstallationBrowser.ButtonPushedFcn = @obj.iceoryxInstallationBrowseFcn;

            %Set ValidateIceoryxInstallationButton properties
            obj.ValidateIceoryxInstallationButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateIceoryxInstallationButton.Text = message('ros:mlros2:rmwsetup:VerifyInstallationButton').getString;
            obj.ValidateIceoryxInstallationButton.Position = [20 170 150 24];
            obj.ValidateIceoryxInstallationButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateIceoryxInstallationButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Set callback when finish button is pushed
            obj.ValidateIceoryxInstallationButton.ButtonPushedFcn = @obj.verifyInstallationButtonCb;

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
            obj.HelpText.WhatToConsider =  message('ros:mlros2:rmwsetup:IceoryxMiddlewareWhatToConsider').getString();

        end

        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.StatusTable.Visible = 'off';

            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
        end

        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.SelectRMWImplementation';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            %Show screen to Build the RMW Implementation
            out = 'ros.internal.rmwsetup.BuildRMWIceoryxPackage';
        end%End of getNextScreenID function

    end

    methods(Access = 'private')
        function editCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.IceoryxInstallationEditText.Text,filesep),...
                    fullfile(obj.IceoryxDir,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
            end
            drawnow;
        end

        function iceoryxInstallationBrowseFcn(obj, ~, ~)
            % iceoryxInstallationBrowseFcn - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.IceoryxInstallationEditText.Text
            dir = uigetdir(obj.IceoryxInstallationEditText.Text, message('ros:mlros2:rmwsetup:BrowseIceoryxInstallation').getString());

            % App loses focus when user cancels out of uigetfile. Set focus back to app
            uiFigHandle = findobjinternal(0,'Type','Figure','Name','ROS Middleware Configuration');
            if ~isempty(uiFigHandle)
                focus(uiFigHandle);
            end

            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (IceoryxInstallationEditText.Text).
                obj.IceoryxInstallationEditText.Text = dir;
            end
        end

        function getCurrentScreenValues(obj)
            obj.IceoryxInstallationEditText.Text = ...
                strtrim(obj.IceoryxEnvironment.IceoryxRoot);
        end

        function verifyInstallationButtonCb(obj,~,~)
            % verifyInstallationButtonCb - Callback when Verify installation
            % button is clicked

            %Enable the BusySpinner while iceoryx middleware validation is taking place
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:IceoryxValidationProgress').getString();
            obj.BusySpinner.show();
            drawnow;
            ValidateSuccess = false;
            try
                %Check if the folder is valid
                if ~isfolder(fullfile(obj.IceoryxInstallationEditText.Text))
                    error(message('ros:mlros2:rmwsetup:IceoryxValidationFailedStatus').getString());
                end

                % Verify the iceoryx Installation
                obj.verifyIceoryxInstallation();
                obj.IceoryxDir = obj.IceoryxInstallationEditText.Text;
                ValidateSuccess = true;
            catch EX
                obj.EnableStatusTable(EX.identifier,EX.message);
            end

            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            drawnow;

            if ValidateSuccess
                obj.NextButton.Enable = 'on';
                % Save Iceoryx environment after successful validation of
                % iceoryx installation
                obj.IceoryxEnvironment.IceoryxHome = obj.IceoryxInstallationEditText.Text;
                obj.IceoryxEnvironment.checkAndCreatePref();

                obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:IceoryxValidationSuccessStatus').getString);
            else
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
            end
        end%End of ValidateButton_callback

        function verifyIceoryxInstallation(obj)
            %verifyIceoryxInstallation - Validates the folder by checking
            %whether libraries and executables are present.
            
            arch = computer('arch');
            libsIceoryxMap = containers.Map();
            libsIceoryxLinux = {'libiceoryx_binding_c.so', 'libiceoryx_platform.so', ...
                'libiceoryx_posh.so','libiceoryx_posh_config.so','libiceoryx_posh_gateway.so', ...
                'libiceoryx_posh_roudi.so','libiceoryx_utils.so'};
            libsIceoryxMac = {'libiceoryx_binding_c.dylib', 'libiceoryx_platform.dylib', ...
                'libiceoryx_posh.dylib','libiceoryx_posh_config.dylib','libiceoryx_posh_gateway.dylib', ...
                'libiceoryx_posh_roudi.dylib','libiceoryx_utils.dylib'};

 
            if ismac
                libsIceoryxMap(arch)  = libsIceoryxMac;
                dirInfo = dir(fullfile(obj.IceoryxInstallationEditText.Text,'lib','*.dylib'));
            elseif isunix
                libsIceoryxMap(arch)  = libsIceoryxLinux;
                dirInfo = dir(fullfile(obj.IceoryxInstallationEditText.Text,'lib','*.so'));
            end

            libsIceoryx = libsIceoryxMap(computer('arch'));

            libsExisting = { dirInfo.name };

            if ~all(ismember(libsIceoryx, libsExisting)) ...
                && ~isfile(fullfile(obj.IceoryxInstallationEditText.Text, 'bin', 'iox-roudi'))
                error(message('ros:mlros2:rmwsetup:IceoryxValidationFailedStatus').getString());
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
    end
end