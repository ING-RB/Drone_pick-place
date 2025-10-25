classdef ValidateRMWImplementation < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % ValidateRMWImplementation - Screen to validate the custom RMW implementation package.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        %ScreenInstructions - Instructions on the screen.
        ScreenInstructions

        % RMWPackageLocationTextBox - Text box area to show RMW implementation 
        % package location that has to be validated.
        RMWPackageLocationTextBox

        % RMWPackageBrowser - Button to open a filesystem browser for user
        % to pick the correct RMW implementation package location.
        RMWPackageBrowser

        % ValidateRMWPackage - Button that Validates the RMW implementation.
        ValidateRMWPackage

        % StatusTable - Status Table to show the status of validation of RMW
        % implementation package.
        StatusTable

        % NextActionText - Text to show the next action.
        NextActionText
    end

    properties (Access = private)
        % BusySpinner - Spinner during validation.
        BusySpinner

        % RMWPackageLocation - Location to the provided RMW implementation
        % package.
        RMWPackageLocation

        % RMWTypeSupportMap - Container that maps RMW implementation with
        % type support.
        RMWTypeSupportMap

        % RMWLocationToPackagesMap - Container that maps RMW implementation
        % location to packages under it.
        RMWLocationToPackagesMap
    end

    methods

        function obj = ValidateRMWImplementation(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})

            % Set the Title Text and Position
            obj.Title.Text = message('ros:mlros2:rmwsetup:RMWValidationScreenTitle').getString;
            obj.Title.Position = [20 7 550 25];

            obj.ConfigurationImage.ImageFile = '';
            obj.ConfigurationInstructions.Text = '';
            obj.ConfigurationInstructions.Visible = 'off';
            obj.NextButton.Enable = 'off';

            % Set Screen Instructions
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenInstructions.Position = [20 310 420 70];
            obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:RMWValidationScreenInstructions').getString;

            %Set RMWPackageLocationTextBox Properties
            obj.RMWPackageLocationTextBox = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.RMWPackageLocationTextBox.ValueChangedFcn = @obj.pathEditCallbackFcn;
            obj.RMWPackageLocationTextBox.Position = [30 260 300 22];
            obj.RMWPackageLocationTextBox.TextAlignment = 'left';

            % Set RMWPackageBrowser button Properties
            obj.RMWPackageBrowser = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.RMWPackageBrowser.Text = message('ros:mlros2:rmwsetup:BrowseButton').getString;
            obj.RMWPackageBrowser.Position = [350 260 70 24];
            obj.RMWPackageBrowser.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            obj.RMWPackageBrowser.ButtonPushedFcn = @obj.rmwPackageBrowserCb;

            %Set ValidateRMWPackage properties
            obj.ValidateRMWPackage = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateRMWPackage.Text = message('ros:mlros2:rmwsetup:RMWValidationScreenButton').getString;
            obj.ValidateRMWPackage.Position = [30 210 150 24];
            obj.ValidateRMWPackage.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateRMWPackage.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.ValidateRMWPackage.ButtonPushedFcn = @obj.validateRMWPackageButtonPushCb;

            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [30 410];
            obj.StatusTable.Position = [30 60 410 130];

            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            obj.NextActionText = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.NextActionText.Position = [30 10 410 30];
            obj.NextActionText.Text = '';

            % Set the Help Text
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:RMWValidationScreenAboutSelection').getString;
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:RMWValidationScreenWhatToConsider').getString;
  
            obj.RMWTypeSupportMap = containers.Map;
            obj.RMWLocationToPackagesMap = containers.Map;
            session = obj.Workflow.getSession;
            session('RMWTypeSupportMap') = obj.RMWTypeSupportMap;
            session('RMWLocationToPackagesMap') = obj.RMWLocationToPackagesMap; %#ok<NASGU>
        end

        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
            % Whenever the RMW package location is changed in the edit box,
            % disable the next button, status table and reset the session map. 
            if ~strcmp(fullfile(obj.RMWPackageLocationTextBox.Text,filesep),...
                    fullfile(obj.RMWPackageLocation,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';

                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
                obj.NextActionText.Text = '';

                % Reload the session
                obj.RMWTypeSupportMap = containers.Map;
                obj.RMWLocationToPackagesMap = containers.Map;
                session = obj.Workflow.getSession;
                session('RMWTypeSupportMap') = obj.RMWTypeSupportMap;
                session('RMWLocationToPackagesMap') = obj.RMWLocationToPackagesMap; %#ok<NASGU>
            end
        end

        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.SelectRMWImplementation';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            session = obj.Workflow.getSession;
            rmwLocationPkgMap = session('RMWLocationToPackagesMap');
            rmwImpl = rmwLocationPkgMap(obj.RMWPackageLocation);

            if numel(rmwImpl) > 1
                out = 'ros.internal.rmwsetup.ChooseRMWImplementation';
            elseif isequal(obj.RMWTypeSupportMap(rmwImpl{1}),'static')
                out = 'ros.internal.rmwsetup.ValidateROSIDLTypeSupport';
            else
                out = 'ros.internal.rmwsetup.MiddlewareInstallationEnvironment';
            end
        end
    end

    methods(Access = 'private')
        function pathEditCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.RMWPackageLocationTextBox.Text,filesep),...
                    fullfile(obj.RMWPackageLocation,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';

                % Hide all these widgets
                obj.StatusTable.Visible = 'off';
                obj.NextActionText.Text = '';

                % Reload the session
                obj.RMWTypeSupportMap = containers.Map;
                obj.RMWLocationToPackagesMap = containers.Map;
                session = obj.Workflow.getSession;
                session('RMWTypeSupportMap') = obj.RMWTypeSupportMap;
                session('RMWLocationToPackagesMap') = obj.RMWLocationToPackagesMap;
                % Whenever a different rmw package location is provided,
                % remove the package selection map from the session, which
                % is filled while choosing RMW package in same session
                if isKey(session,'PkgSelectionMap')
                    remove(session, 'PkgSelectionMap');
                end
            end
            drawnow;
        end

        function rmwPackageBrowserCb(obj, ~, ~)
            % rmwPackageBrowserCb - Callback when browse button is pushed. 
            % This launches the file browsing window set to the directory
            % indicated by obj.RMWPackageLocationTextBox.Text.

            dir = uigetdir(obj.RMWPackageLocationTextBox.Text, message('ros:mlros2:rmwsetup:RMWValidationScreenBrowse').getString);

            % App loses focus when user cancels out of uigetfile. Set focus back to app
            uiFigHandle = findobjinternal(0,'Type','Figure','Name',getString(message('ros:mlros2:rmwsetup:MainWindowTitle')));
            if ~isempty(uiFigHandle)
                focus(uiFigHandle);
            end

            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (RMWPackageLocationTextBox.Text).
                obj.RMWPackageLocationTextBox.Text = dir;
            end
        end

        function validateRMWPackageButtonPushCb(obj,~,~)
            % validateRMWPackageButtonPushCb - Callback when Validate RMW
            % package button is clicked

            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';

            % Set the Busy Spinner text and enable it while package validation is taking place
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:RMWValidationScreenSpinnerText').getString;
            obj.BusySpinner.show();
            drawnow;

            % Set Validation to false initially
            ValidateSuccess = false;
            try
                % Check if the path provided is not empty and is a folder
                rmwPackagePath = convertStringsToChars(obj.RMWPackageLocationTextBox.Text);
                if isempty(rmwPackagePath)
                    error(message('ros:mlros2:rmwsetup:RMWPackageEmptyPathError').getString);
                end
                if ~isfolder(rmwPackagePath)
                    error(message('ros:mlros2:rmwsetup:RMWPackageNotFoundError').getString);
                end

                % Extract the RMW implementation package name from provided
                % folder path.
                [~, rmwpackageName] = fileparts(rmwPackagePath);

                if obj.isValidRMWPackageName(rmwpackageName)
                    [rmwPkgDirs, typesupports] = obj.getRMWPkgDirs(rmwPackagePath);
                    if isempty(rmwPkgDirs)
                        error(message('ros:mlros2:rmwsetup:RMWPackageNotFoundError').getString);
                    else
                        ValidateSuccess = true;
                    end
                else
                    error(message('ros:mlros2:rmwsetup:RMWPackageNotFoundError').getString);
                end
                obj.RMWPackageLocation = rmwPackagePath;
                obj.RMWLocationToPackagesMap(rmwPackagePath) = rmwPkgDirs;
            catch EX
                obj.EnableStatusTable(EX.identifier,EX.message);
            end

            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            drawnow;

            if ValidateSuccess
                for i=1:numel(rmwPkgDirs)
                    if typesupports{i}
                        %obj.Workflow.IsDynamicTypeSupportAvailable = true;
                        typesupportStatus = 'dynamic';
                    else
                        %obj.Workflow.IsStaticTypeSupportAvailable = true;
                        typesupportStatus = 'static';
                    end
                    obj.RMWTypeSupportMap(rmwPkgDirs{i}) = typesupportStatus;
                end

                obj.NextButton.Enable = 'on';
                rmwImpl = obj.RMWLocationToPackagesMap(rmwPackagePath);

                if numel(rmwImpl) < 2
                    obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:RMWPackageAvailable', rmwImpl{1}, obj.RMWTypeSupportMap(rmwImpl{1})).getString);
                    if isequal(obj.RMWTypeSupportMap(rmwImpl{1}),'dynamic')
                        obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionDynamic').getString;
                    else
                        obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionStatic').getString;
                    end
                elseif numel(rmwImpl) == 2
                    if isequal(obj.RMWTypeSupportMap(rmwImpl{1}), obj.RMWTypeSupportMap(rmwImpl{2}))
                        obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:RMWValidationStatusSameTypeSupport', rmwImpl{1}, rmwImpl{2}, obj.RMWTypeSupportMap(rmwImpl{1})).getString);
                    else
                        obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:RMWValidationStatusDifferentTypeSupport', rmwImpl{1}, rmwImpl{2}, obj.RMWTypeSupportMap(rmwImpl{1}), obj.RMWTypeSupportMap(rmwImpl{2})).getString);
                    end
                    obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionMultipleRMW').getString;
                else
                    obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:RMWValidationStatusMultipleRMW').getString);
                    obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionMultipleRMW').getString;
                end
            else
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                obj.NextActionText.Text = '';
            end
        end

        function EnableStatusTable(obj,messageID,messageDetail)
            % Show all these widgets
            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Border='off';
            obj.StatusTable.Enable = 'on';
            obj.StatusTable.Steps = {messageDetail};
            drawnow;
            switch messageID
                case 'success'
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                otherwise
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
            end
            drawnow;
        end

        function isValidRMW = isValidRMWPackageName(~,rmwPackageName)
            % Check if the given package name is a valid ROS
            % middleware implementation package. RMW implementation package
            % name starts with 'rmw_'.
 
            matchedName = regexp(rmwPackageName,'^rmw_[a-z_]*$','match');
            isValidRMW = ~isempty(matchedName) && isequal(rmwPackageName, matchedName{1});
        end

        function [rmwPkgDirs, typeSupports] = getRMWPkgDirs(obj,folderPath)
            % Get the ROS middleware package names available in the given
            % folder and also get whether they are depending on 
            % dynamic(introspection) or static typesupport.

            dirInfo = dir(folderPath);
            whichPkgs = [dirInfo.isdir] & ~ismember({dirInfo.name}, {'.', '..'});
            typeSupports = {};
            rmwPkgDirs = {};

            % Get RMW implementation package name if user provides location
            % of rmw implementation package.
            cmakeListsFileInSubDir = fullfile(folderPath, 'CMakeLists.txt');
            packageXmlFileInSubDir = fullfile(folderPath, 'package.xml');
            if isfile(cmakeListsFileInSubDir) && isfile(packageXmlFileInSubDir)
                [~,rmwPkgName] = fileparts(folderPath);
                [isRMWPkg, hasDynamicTS] = ros.internal.utilities.checkValidityOfRMW(cmakeListsFileInSubDir, rmwPkgName);
                if isRMWPkg
                    typeSupports{end+1} = hasDynamicTS;
                    rmwPkgDirs{end+1} = rmwPkgName;
                    return;
                end
            end

            % Get RMW implementation package names if user provides location
            % containing rmw implementation packages.
            for iPkg = find(whichPkgs)
                cmakeListsFile = fullfile(folderPath, dirInfo(iPkg).name, 'CMakeLists.txt');
                packageXmlFile = fullfile(folderPath, dirInfo(iPkg).name, 'package.xml');

                isRMWPkg = false;
                if isfile(cmakeListsFile) && isfile(packageXmlFile)
                    if obj.isValidRMWPackageName(dirInfo(iPkg).name)
                        [isRMWPkg, hasDynamicTS] = ros.internal.utilities.checkValidityOfRMW(cmakeListsFile, dirInfo(iPkg).name);
                        if isRMWPkg
                            typeSupports{end+1} = hasDynamicTS; %#ok<AGROW>
                        end
                    end
                end
                whichPkgs(iPkg) = isRMWPkg;
            end
            %these directories have rmw implementations that need to be built
            rmwPkgDirs = {dirInfo(whichPkgs).name}';
        end
    end
end