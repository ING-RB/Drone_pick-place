classdef BuildRMWIceoryxPackage < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % BuildRMWIceoryxPackage - Screen implementation to enable users to build the
    % rmw_iceoryx_cpp RMW Implementation.
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})
        % Button to build the rmw implementation
        BuildButton
        % Build Status Table to show the status of build
        BuildStatusTable
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
        % Configuration step 1
        ConfigStep1
        % Configuration step 2
        ConfigStep2
        % Description in the screen
        Description
        % Spinner widget
        BusySpinner
    end
    
    properties (Access = private)
        % RMW Implementation package source directory
        RMWPackageDir
    end
    
    methods
        function obj = BuildRMWIceoryxPackage(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:ScreenThreeTitle').getString();
            obj.Description = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.Description.Text = message('ros:mlros2:rmwsetup:RMWIceoryxCppScreenDescription').getString();
            obj.Description.Position = [20 325 430 50];
            obj.ConfigurationInstructions.Visible = 'off';
            obj.ConfigStep1 = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ConfigStep1.Text = message('ros:mlros2:rmwsetup:RMWIceoryxCppPackageBrowse').getString();   
            obj.ConfigStep1.Position = [20 285 430 50];
            
            %Set ValidateEditText Properties
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.ValidateEditText.ValueChangedFcn = @obj.editCallbackFcn;
            obj.ValidateEditText.Position = [35 270 290 20];
            obj.ValidateEditText.TextAlignment = 'left';

            rmwReg = ros.internal.CustomRMWRegistry.getInstance();
            rmwInfo = rmwReg.getRMWInfo('rmw_iceoryx_cpp');

            if ~isempty(rmwInfo)
               obj.ValidateEditText.Text = rmwInfo.srcPath;
            else
                obj.ValidateEditText.Text = '';
            end

            % Set BrowseButton Properties
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.BrowseButton.Text = message('ros:mlros2:rmwsetup:BrowseButton').getString();
            obj.BrowseButton.Position = [340 268 70 24];
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            % Set callback when finish button is pushed
            obj.BrowseButton.ButtonPushedFcn = @obj.browseInstallDirectory;

            obj.ConfigStep2 = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ConfigStep2.Text = message('ros:mlros2:rmwsetup:BuildRMWIceoryxCppStep').getString();
            obj.ConfigStep2.Position = [20 230 450 35];
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            %Validation will bring in these widgets
            obj.BuildStatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.BuildStatusTable.Visible = 'off';
            obj.BuildStatusTable.Enable = 'off';
            obj.BuildStatusTable.Status = {''};
            obj.BuildStatusTable.Steps = {''};

            % Create button widget and parent it to the content panel
            obj.BuildButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            %Set BuildButton Properties
            obj.BuildButton.Text = message('ros:mlros2:rmwsetup:BuildRMWArtifactsButton').getString();
            obj.BuildButton.ButtonPushedFcn = @obj.buildButtonCallback;
            obj.BuildButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.BuildButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;

            obj.setScreenProperty();
            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            % Set the Help Text
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:BuildRMWIceoryxCppSelection').getString();
        end
        
        function setScreenProperty(obj)
            obj.BuildButton.Position = [35 185 130 25];
            obj.BuildStatusTable.ColumnWidth = [35 450];
            obj.BuildStatusTable.Position = [35 60 450 100];

            obj.ConfigurationInstructions.Text = '';
            obj.HelpText.WhatToConsider = message("ros:mlros2:rmwsetup:RMWIceoryxCppWhatToConsider").getString();
            obj.NextButton.Enable = 'off';
        end %End of setScreenProperty method
        
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
        end
        
        
        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.ValidateIceoryxInstallation';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            %Show screen to Test the RMW Implementation
            out = 'ros.internal.rmwsetup.TestRMWImplementation';
        end%End of getNextScreenID function

        function buildButtonCallback(obj,~,~)
            %% buildButtonCallback - Callback function when user clicks the 
            % Build RMW button on the screen

            obj.SetBuildStatusTable('off');
            %Disable the screen before starting BusySpinner
            obj.disableScreen();
            %Enable the BusySpinner while package build is taking place
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:PackageBuildProgress').getString();
            obj.BusySpinner.show();
            drawnow;
            try
                folderPath = convertStringsToChars(obj.RMWPackageDir);
                folderPath = ros.internal.Parsing.validateFolderPath(folderPath);
                [packageRootDir, rmwpackageName] = fileparts(folderPath);

                %build middleware implementation
                builder = ros.ros2.internal.ColconBuilder(packageRootDir,rmwpackageName,SuppressOutput=true);

                ddsEnv = ros.internal.IceoryxEnvironment;
                colconMakeArgsMap = containers.Map();
                archKeys = {'glnxa64', 'maci64', 'maca64'};
                arch = computer('arch');

                % Architecture-applicable load path environment variable
                envPathMap = ...
                    containers.Map(archKeys, ...
                    {'LD_LIBRARY_PATH', ...  % glnxa64
                    'DYLD_LIBRARY_PATH', ...  % maci64
                    'DYLD_LIBRARY_PATH'});  % maca64
                envApplicablePath = envPathMap(arch);
                pathCurrentValue = getenv(envApplicablePath);

                setenv('iceoryx_posh_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_posh'));
                cleanPoshDirEnv = onCleanup(...
                    @() unsetenv('iceoryx_posh_DIR'));

                setenv('iceoryx_hoofs_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_hoofs'));
                cleanUtilsDirEnv = onCleanup(...
                    @() unsetenv('iceoryx_hoofs_DIR'));
    
                setenv('iceoryx_binding_c_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_binding_c'));
                cleanBindingDirEnv = onCleanup(...
                    @() unsetenv('iceoryx_binding_c_DIR'));

                setenv(envApplicablePath, [fullfile(ddsEnv.IceoryxRoot,'lib'), pathsep, pathCurrentValue]);
                cleanPath = onCleanup(...
                    @() setenv(envApplicablePath, pathCurrentValue));

                if isunix && ~ismac
                    systemLibs = ['"' fullfile(matlabroot,'sys/os/glnxa64/orig/libstdc++.so.6') '"'];
                    colconMakeArgsMap(arch)  = [' --cmake-args', ' -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS=',systemLibs,' -DBUILD_TESTING=OFF -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DCMAKE_INSTALL_RPATH=\$ORIGIN/../lib '];
                else
                    colconMakeArgsMap(arch)  = [' --cmake-args', ' -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DCMAKE_INSTALL_RPATH="@loader_path/../lib" '];
                end

                % For glnxa64, maci64, maca64
                colconMakeArgs = colconMakeArgsMap(arch);

                [resetEnvs, resetCustomAmentPrefPath, ...
                    resetCustomPath, resetCustomSitePkgsPath, restCustomLibraryPath] = ros.ros2.internal.setCustomPathsAndMiddlewareEnv; %#ok<ASGLU>


                result = buildPackage(builder, [], ' --merge-install', colconMakeArgs);
                BuildSuccess = true;
            catch ME
                BuildSuccess = false;
                Exception = ME.message;
            end
            %Disable the BusySpinner after build complete
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
            %Enable the Status table to show the status of Build
            obj.SetBuildStatusTable('on');
            obj.BuildStatusTable.Border='off';
            if BuildSuccess
                obj.BuildStatusTable.Steps = { message('ros:mlros2:rmwsetup:BuildRMWPackageSuccess',fullfile(result)).getString() };
                obj.BuildStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};

                % Update preferences with folder information
                reg = ros.internal.CustomRMWRegistry.getInstance;
                rmwImplInstallDir = fullfile(packageRootDir,'install');
                rmwImplDllPathMap = containers.Map({'maci64','maca64','glnxa64'}, ...
                    { ...
                    fullfile(rmwImplInstallDir,'lib','*.dylib'),...
                    fullfile(rmwImplInstallDir,'lib','*.dylib'),...
                    fullfile(rmwImplInstallDir,'lib','*.so'),...
                    });
                rmwImplDllPath = rmwImplDllPathMap(computer('arch'));

                rmwEnv = ros.internal.ros2.RMWEnvironment;
                rmwEnv.RMWImplementation = 'rmw_iceoryx_cpp';
                reg.updateRMWEntry(rmwEnv.RMWImplementation, rmwImplInstallDir,folderPath, rmwImplDllPath, ddsEnv.IceoryxRoot);
                obj.NextButton.Enable = 'on';
            else
                if contains(Exception,'stdout_stderr.log')
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedLogFile',fullfile(Exception)).getString()};
                else
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedStatus',Exception).getString()};
                end
                obj.BuildStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.NextButton.Enable = 'off';
            end
        end
    end
    
    methods(Access = private)     
        function SetBuildStatusTable(obj,status)
            if strcmpi(status,'on')
                % Show all these widgets
                obj.BuildStatusTable.Visible = 'on';
                obj.BuildStatusTable.Enable = 'on';
            elseif strcmpi(status,'off')
                obj.BuildStatusTable.Visible = 'off';
                obj.BuildStatusTable.Enable = 'off';
            end
        end

        function editCallbackFcn(obj,~,~)
            if ~strcmp(fullfile(obj.ValidateEditText.Text,filesep),...
                    fullfile(obj.RMWPackageDir,filesep))
                % Disable the NEXT Button
                obj.NextButton.Enable = 'off';
                % Hide all these widgets
                obj.BuildStatusTable.Visible = 'off';
            end
            obj.RMWPackageDir = obj.ValidateEditText.Text;
            drawnow;
        end

        function browseInstallDirectory(obj, ~, ~)
            % browseDirectory - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.ValidateEditText.Text
            dir = uigetdir(obj.ValidateEditText.Text, message('ros:mlros2:rmwsetup:BrowseRMWIceoryxCppPlaceHolder').getString());

            % App loses focus when user cancels out of uigetfile. Set focus back to app
            uiFigHandle = findobjinternal(0,'Type','Figure','Name','ROS Middleware Configuration');
            if ~isempty(uiFigHandle)
                focus(uiFigHandle);
            end

            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (ValidateEditText.Text).
                obj.ValidateEditText.Text = dir;

            end
        end%End of browseDirectory
    end
end