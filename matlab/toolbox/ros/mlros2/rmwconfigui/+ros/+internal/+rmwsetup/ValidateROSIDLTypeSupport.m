classdef ValidateROSIDLTypeSupport < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % ValidateROSIDLTypeSupport - Screen implementation to enable users to validate the
    % ROS IDL Typesupport for RMW Implementation based on static type support.
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})
        % ScreenInstructions - Instructions on the screen.
        ScreenInstructions

        % ValidateTypeSupportButton - Button to verify the ROS IDL type
        % support.
        ValidateTypeSupportButton

        % StatusTable - Status Text for the validation.
        StatusTable

        % NextActionText - Text to show the next action.
        NextActionText
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner

        % Location to RMW implementation Package
        RMWPackageDir
    end
    
    methods
        function obj = ValidateROSIDLTypeSupport(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:ValidateTSPkgScreenTitle').getString;
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
   
            obj.setOnScreenInstructions();
            obj.ScreenInstructions.Position = [20 90 430 290];

            %Set ValidateTypeSupportButton properties
            obj.ValidateTypeSupportButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.ValidateTypeSupportButton.Text = message('ros:mlros2:rmwsetup:ValidateTSPkgScreenButton').getString;
            obj.ValidateTypeSupportButton.Position = [30 250 150 24];
            obj.ValidateTypeSupportButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateTypeSupportButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.ValidateTypeSupportButton.ButtonPushedFcn = @obj.validateROSIDLTypeSupportPkgCb;

            %Validation will bring in these widgets
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.ColumnWidth = [30 410];
            obj.StatusTable.Position = [30 170 410 60];

            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            obj.NextActionText = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.NextActionText.Position = [30 10 410 30];
            obj.NextActionText.Text = '';
            obj.NextButton.Enable = 'off';

            session = obj.Workflow.getSession;
            rmwImplLocationMap = session('RMWLocationToPackagesMap');
            rmwLocation = rmwImplLocationMap.keys;
            obj.RMWPackageDir = rmwLocation{1};

            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';

            % Set the Help Text
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:ValidateTSPkgScreenWhatToConsider').getString;
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:ValidateTSPkgScreenAboutSelection').getString;
        end

        function setOnScreenInstructions(obj)
            rmwPackageName = '';
            session = obj.Workflow.getSession;
            typesupportMap = session('RMWTypeSupportMap');
            keys = typesupportMap.keys;
            for key=1:numel(keys)
                if isequal(typesupportMap(keys{key}), 'static')
                    rmwPackageName = keys{key};
                    break;
                end
            end
            rmwImplLocationMap = session('RMWLocationToPackagesMap');
            rmwLocation = rmwImplLocationMap.keys;
            [rmwParentPath, ~] = fileparts(rmwLocation{1});

            % open the directory for user to copy ROS IDL Typesupport
            % package
            if ispc
                dirHyperLink = ['winopen(''' rmwParentPath ''')'];
            elseif ismac
                dirHyperLink = ['system([''open '' ''' '' rmwParentPath ''' '' &'']);'];
            else
                dirHyperLink = ['system([''xdg-open '' ''' '' rmwParentPath ''' '' &'']);'];
            end
            obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:ValidateTSPkgScreenInstructions', rmwPackageName, dirHyperLink).getString;
        end
  
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            obj.setOnScreenInstructions();
 
            session = obj.Workflow.getSession;
            rmwImplLocationMap = session('RMWLocationToPackagesMap');
            rmwLocation = rmwImplLocationMap.keys;
            rmwPackageDir = rmwLocation{1};

            if ~strcmp(rmwPackageDir, obj.RMWPackageDir)
                obj.StatusTable.Visible = 'off';
            end
            obj.enableScreen();
        end

        function out = getPreviousScreenID(obj)
            session = obj.Workflow.getSession;
            if ismember('PkgSelectionMap',session.keys)
                out = 'ros.internal.rmwsetup.ChooseRMWImplementation';
            else
                out = 'ros.internal.rmwsetup.ValidateRMWImplementation';
            end
        end

        function out = getNextScreenID(~)
            out = 'ros.internal.rmwsetup.MiddlewareInstallationEnvironment';
        end
    end

    methods(Access = private)

        function isValidTS = isValidRosIdlTypesupportPackageName(~,typesupportPackageName)
            matchedName = regexp(typesupportPackageName,'^rosidl_typesupport_[a-z_]*$','match');
            isValidTS = ~isempty(matchedName) && isequal(typesupportPackageName, matchedName{1});
        end

        function validateROSIDLTypeSupportPkgCb(obj,~,~)
            % validateROSIDLTypeSupportPkgCb - Callback when Validate Type
            % Support button is clicked

            %Enable the BusySpinner while package validation is taking place
            % Disable the NEXT Button
            obj.NextButton.Enable = 'off';
            obj.StatusTable.Visible = 'off';
            obj.NextActionText = '';
            %Set the Busy Spinner text
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:ValidatingTSPkgScreenSpinnerText').getString;
            obj.BusySpinner.show();
            drawnow;
            ValidateSuccess = false;

            try
                %Check if the folder is valid
                session = obj.Workflow.getSession;
                rmwImplLocationMap = session('RMWLocationToPackagesMap');
                rmwLocation = rmwImplLocationMap.keys;
                rmwPackagePath = rmwLocation{1};
                [rmwPkgRoot, ~] = fileparts(rmwPackagePath);

                hasTypeSupport = obj.checkTypeSupportPkgIsAvailable(rmwPkgRoot);
                if ~hasTypeSupport
                    hasTypeSupport = obj.checkTypeSupportPkgIsAvailable(rmwPackagePath);
                end
 
                if ~hasTypeSupport
                    error(message('ros:mlros2:rmwsetup:NoIDLTypeSupportPkgFound'));
                else
                    ValidateSuccess = true;
                end
            catch EX
                obj.EnableStatusTable(EX.identifier,EX.message);
            end

            %Disable the BusySpinner after validation complete
            obj.BusySpinner.Visible = 'off';
            drawnow;

            if ValidateSuccess
                obj.RMWPackageDir = rmwLocation{1};
                obj.NextButton.Enable = 'on';
                obj.EnableStatusTable('success',message('ros:mlros2:rmwsetup:IDLTypeSupportIsAvailable').getString);
                obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionDynamic').getString;
            else
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                obj.NextActionText.Text = '';
            end
        end

        function hasTypeSupportPkg = checkTypeSupportPkgIsAvailable(obj,folderPath)
            % Check if the type support package is available. ROS IDL type
            % support package name starts with 'rosidl_typesupport_' and
            % follows valid ROS package naming conventions. The package
            % CMakeLists.txt should contain 'ament_index_register_resource('rosidl_typesupport_cpp)'.

            dirInfo = dir(folderPath);
            whichPkgs = [dirInfo.isdir] & ~ismember({dirInfo.name}, {'.', '..'});

            hasTypeSupportPkg = false;
            for iPkg = find(whichPkgs)
                if obj.isValidRosIdlTypesupportPackageName(dirInfo(iPkg).name)
                    tsCurrentDir = fullfile(folderPath, dirInfo(iPkg).name);
                    cmakeListsFileInDir = fullfile(tsCurrentDir, 'CMakeLists.txt');
                    packageXmlFileInDir = fullfile(tsCurrentDir, 'package.xml');

                    if isfile(cmakeListsFileInDir) && isfile(packageXmlFileInDir)
                        hasTypeSupportPkg = ros.internal.utilities.checkValidityOfIDLTypeSupport(cmakeListsFileInDir);
                    else
                        dirInfoTS = dir(tsCurrentDir);
                        subDirs = [dirInfoTS.isdir] & ~ismember({dirInfoTS.name}, {'.', '..'});
                        for iDir = find(subDirs)
                            if obj.isValidRosIdlTypesupportPackageName(dirInfoTS(iDir).name)
                                cmakeListsFileOfTS = fullfile(tsCurrentDir,  dirInfoTS(iDir).name, 'CMakeLists.txt');
                                packageXmlFileOfTS = fullfile(tsCurrentDir,  dirInfoTS(iDir).name, 'package.xml');
                                if isfile(cmakeListsFileOfTS) && isfile(packageXmlFileOfTS)
                                    hasTypeSupportPkg = ros.internal.utilities.checkValidityOfIDLTypeSupport(cmakeListsFileOfTS);
                                end
                            end
                        end
                    end
                end
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
    end
end
