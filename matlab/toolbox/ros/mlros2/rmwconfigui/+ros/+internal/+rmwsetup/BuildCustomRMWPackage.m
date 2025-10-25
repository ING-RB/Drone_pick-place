classdef BuildCustomRMWPackage < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % BuildCustomRMWPackage - Screen implementation to enable users to build the
    % RMW Implementation for custom middleware.
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        % ScreenInstructions - Instructions on the screen
        ScreenInstructions

        % BuildRMWButton - Button to build the custom rmw implementation package
        BuildRMWButton

        % BuildStatusTable - Build Status Table to show the status of build
        BuildStatusTable

         % NextActionText - Text to show the next action.
        NextActionText

        % Spinner widget
        BusySpinner
    end
    
    properties (Access = private)
        % RMW Implementation package build directory
        RMWBuildDir
    end
    
    methods
        function obj = BuildCustomRMWPackage(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:ScreenThreeTitle').getString();
            % Set the on screen instructions
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.setOnScreenInstructions();

            obj.ScreenInstructions.Position = [20 260 430 110];
            obj.ConfigurationInstructions.Visible = 'off';
            
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            %Validation will bring in these widgets
            obj.BuildStatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.BuildStatusTable.Visible = 'off';
            obj.BuildStatusTable.Enable = 'off';
            obj.BuildStatusTable.Status = {''};
            obj.BuildStatusTable.Steps = {''};

            % Create button widget and parent it to the content panel
            obj.BuildRMWButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            obj.BuildRMWButton.Text = message('ros:mlros2:rmwsetup:BuildRMWArtifactsButton').getString();
            obj.BuildRMWButton.ButtonPushedFcn = @obj.buildRMWButtonCb;
            obj.BuildRMWButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.BuildRMWButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;

            obj.setScreenProperty();

            % Maintain the selected RMW package directory location in the
            % session.
            session = obj.Workflow.getSession;
            if isKey(session, 'RMWLocationToPackagesMap')
                pkgLocation = session('RMWLocationToPackagesMap').keys;
                obj.RMWBuildDir = pkgLocation{:};
            end

            obj.NextActionText = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.NextActionText.Position = [30 10 410 30];
            obj.NextActionText.Text = '';

            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
        end
        
        function setScreenProperty(obj)
            obj.BuildRMWButton.Position = [20 280 130 25];
            obj.BuildStatusTable.ColumnWidth = [20 420];
            obj.BuildStatusTable.Position = [20 50 420 210];

            obj.ConfigurationInstructions.Text = '';
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:BuildCustomRMWAboutSelection').getString;
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:BuildCustomRMWScreenWhatToConsider').getString;
            obj.NextButton.Enable = 'off';

        end

        function setOnScreenInstructions(obj)
            session = obj.Workflow.getSession;

            if ~ismember('PkgSelectionMap', session.keys)
                rmwPkgsMap = session('RMWTypeSupportMap');
                rmwKeys = rmwPkgsMap.keys;
                obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:BuildCustomRMWScreenInstructions', rmwKeys{1}).getString;
            else
                pkgSelectionMap = session('PkgSelectionMap');
                pkgSelection = pkgSelectionMap.keys;
                if isequal(pkgSelection{1},'all')
                    obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:BuildCustomRMWForAllPkg').getString;
                else
                    rmwImpl = pkgSelectionMap.values;
                    obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:BuildCustomRMWScreenInstructions', rmwImpl{1}).getString;
                end
            end
        end
        
        function reinit(obj)
            % Reloading the screen
            
            obj.BusySpinner.Visible = 'off';
            obj.setOnScreenInstructions();
            nextButtonStatus = char(obj.NextButton.Enable);
            obj.enableScreen();

            % If the selected RMW package location is different from
            % previously build RMW package in same session, disable the
            % next button and turn off the status table, allowing user to
            % build the desired package.
            session = obj.Workflow.getSession;
            obj.NextButton.Enable = nextButtonStatus;
            if isKey(session, 'RMWLocationToPackagesMap')
                pkgLocation = session('RMWLocationToPackagesMap').keys;
                if ~isequal(pkgLocation{:}, obj.RMWBuildDir)
                    obj.SetBuildStatusTable('off');
                    obj.NextButton.Enable = 'off';
                end
            end
            drawnow;
        end
        
        
        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.MiddlewareInstallationEnvironment';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            obj.ConfigurationImage.ImageFile = '';
            obj.ConfigurationInstructions.Text = '';

            session = obj.Workflow.getSession;
            pkgLocationToRMWMap = session('RMWLocationToPackagesMap');
            rmwPkgsMap = session('RMWTypeSupportMap');

            if ~ismember('PkgSelectionMap',session.keys)
                rmwImplementation = rmwPkgsMap.keys;
                obj.Workflow.RMWImplementation = rmwImplementation{:};
                typesupport = rmwPkgsMap(obj.Workflow.RMWImplementation);
            else
                pkgSelectionMap = session('PkgSelectionMap');
                rmwImplementation = pkgSelectionMap.keys;
                if isequal(rmwImplementation{:},'all')
                   rmwPackages = pkgLocationToRMWMap.values;
                   typesupport = 'dynamic';
                   dynamicRMW = {};
                   staticRMW = {};
                   for iPkg=1:numel(rmwPackages{:})
                       if isequal(rmwPkgsMap(rmwPackages{:}{iPkg}), 'dynamic')
                           dynamicRMW{end+1} = rmwPackages{:}{iPkg}; %#ok<AGROW>
                       else
                           typesupport = 'static';
                           staticRMW{end+1} = rmwPackages{:}{iPkg}; %#ok<AGROW>
                       end
                   end

                   if isequal(typesupport,'static') && isempty(dynamicRMW)
                       % This condition is true when there are all static
                       % typesupport based RMW implementations in a location.
                       obj.Workflow.RMWImplementation = staticRMW{1};
                   else
                       % This condition is true when there are one or more
                       % dynamic based RMW implementations in a location.
                       % If there is a static and dynamic typesupport based RMW
                       % default value chosen in dynamic
                       obj.Workflow.RMWImplementation = dynamicRMW{1};
                   end
                else
                    obj.Workflow.RMWImplementation = rmwImplementation{:};
                    typesupport = rmwPkgsMap(obj.Workflow.RMWImplementation);
                end
            end

            if isequal(typesupport,'dynamic')
                %Show screen to Test the RMW Implementation
                out = 'ros.internal.rmwsetup.TestRMWImplementation';
            else
                out = 'ros.internal.rmwsetup.BuildROSMessagePackages';
            end
        end

        function buildRMWButtonCb(obj,~,~)
            %% buildRMWButtonCb - Callback function when user clicks the 
            % Build RMW Artifacts button on the screen

            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.SetBuildStatusTable('off');
            %Disable the screen before starting BusySpinner
            obj.disableScreen();
            %Enable the BusySpinner while Firmware build is taking
            %place
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:PackageBuildProgress').getString();
            obj.BusySpinner.Visible = 'on';
            obj.BusySpinner.show();
            drawnow;
            try
                session = obj.Workflow.getSession;
                pkgLocationToRMWMap = session('RMWLocationToPackagesMap');

                if ~ismember('PkgSelectionMap',session.keys)
                    rmwPkgsMap = session('RMWTypeSupportMap');
                    rmwPkgsToBuild = rmwPkgsMap.keys;
                else
                    pkgSelectionMap = session('PkgSelectionMap');
                    rmwPkgsToBuild = pkgSelectionMap.values;
                end

                rmwPackagePath = pkgLocationToRMWMap.keys;
                folderPath = convertStringsToChars(rmwPackagePath{:});
                folderPath = ros.internal.Parsing.validateFolderPath(rmwPackagePath{:});

                [packageRootDir, rmwDir] = fileparts(folderPath);

                useNinja = true;
                suppressOutput = true;
                if ispc && contains(rmwPkgsToBuild{:},'ecal')
                    % Turning off ninja for building rmw_ecal_* packages
                    useNinja = false;
                end

                %build middleware implementation
                builder = ros.ros2.internal.ColconBuilder(packageRootDir,rmwDir,UseNinja=useNinja, SuppressOutput=suppressOutput);

                originalPathEnv = getenv('PATH');
                resetPath = onCleanup(@()setenv('PATH',originalPathEnv));

                middlewareEnv = ros.internal.MiddlewareEnvironment.getInstance();
                setenv('PATH',[fullfile(middlewareEnv.MiddlewareHome,'bin'), pathsep, originalPathEnv]);

                archKeys = {'win64', 'glnxa64', 'maci64', 'maca64'};
                arch = computer('arch');

                % Architecture-applicable load path environment variable
                envPathMap = ...
                    containers.Map(archKeys, ...
                    {'PATH', ...             % win64
                    'LD_LIBRARY_PATH', ...  % glnxa64
                    'DYLD_LIBRARY_PATH', ...  % maci64
                    'DYLD_LIBRARY_PATH'});  % maca64
                envApplicablePath = envPathMap(arch);
                pathCurrentValue = getenv(envApplicablePath);

                rmwpkgsInlocation = pkgLocationToRMWMap.values;
                if ismember('rmw_connextdds',rmwpkgsInlocation{:})
                    ddsEnv = ros.internal.DDSEnvironment();
                    nddsHomeCurrentVal = getenv('NDDSHOME');
                    if isempty(nddsHomeCurrentVal)
                        setenv('NDDSHOME', ddsEnv.DDSRoot);
                        resetEnv = onCleanup(...
                            @() setenv('NDDSHOME', nddsHomeCurrentVal));
                    end
                    setenv('PATH',[fullfile(getenv('NDDSHOME'),'bin'), pathsep, getenv('PATH')]);
                    setenv(envApplicablePath, [fullfile(getenv('NDDSHOME'),'lib', ddsEnv.DDSArchName), pathsep, pathCurrentValue]);
                elseif ismember('rmw_iceoryx_cpp', rmwpkgsInlocation{:})
                    ddsEnv = ros.internal.IceoryxEnvironment;
                    setenv('iceoryx_posh_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_posh'));
                    cleanPoshDirEnv = onCleanup(...
                        @() unsetenv('iceoryx_posh_DIR'));

                    setenv('iceoryx_utils_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_utils'));
                    cleanUtilsDirEnv = onCleanup(...
                        @() unsetenv('iceoryx_utils_DIR'));

                    setenv('iceoryx_binding_c_DIR', fullfile(ddsEnv.IceoryxRoot,'lib','cmake','iceoryx_binding_c'));
                    cleanBindingDirEnv = onCleanup(...
                        @() unsetenv('iceoryx_binding_c_DIR'));

                    setenv(envApplicablePath, [fullfile(ddsEnv.IceoryxRoot,'lib'), pathsep, pathCurrentValue]);
                else
                    setenv(envApplicablePath, [fullfile(middlewareEnv.MiddlewareHome,'lib'), pathsep, pathCurrentValue]);
                end

                if ~ispc
                    cleanPath = onCleanup(...
                        @() setenv(envApplicablePath, pathCurrentValue));
                end

                config = ' -DCMAKE_BUILD_TYPE=Release';
                optimizationFlagsForWindows = ' -DCMAKE_CXX_FLAGS_RELEASE="/MD /Od /Ob2 /DNDEBUG" ';
                optimizationFlagsForUnix = ' -DCMAKE_CXX_FLAGS_RELEASE=-O0 ';

                customRMWReg = ros.internal.CustomRMWRegistry.getInstance();
                customRMWRegList = customRMWReg.getRMWList();
                if ismember('rmw_ecal_proto_cpp',customRMWRegList)
                    rmwInfo = customRMWReg.getRMWInfo('rmw_ecal_proto_cpp');
                    builder.setUseNinja(false);
                    middlewareHomeBinVal = fullfile(rmwInfo.middlewarePath,'bin');
                    config = [config ' -DProtobuf_PROTOC_EXECUTABLE=' ['"' fullfile(middlewareHomeBinVal,'protoc.exe') '" ']];
                end

                [resetEnvs, resetCustomAmentPrefPath, ...
                    resetCustomPath, resetCustomSitePkgsPath, restCustomLibraryPath] = ros.ros2.internal.setCustomPathsAndMiddlewareEnv; %#ok<ASGLU>

                colconMakeArgsMap = containers.Map();
                if ispc
                    colconMakeArgsMap('win64')   = [' --packages-up-to ', rmwPkgsToBuild{:},' --cmake-args', config,' -DBUILD_TESTING=OFF ', ...
                        optimizationFlagsForWindows];
                else
                    % For glnxa64, maci64, maca64
                    if isunix && ~ismac
                        systemLibs = ['"' fullfile(matlabroot,'sys/os/glnxa64/orig/libstdc++.so.6') '"'];
                        colconMakeArgsMap(computer('arch'))  = [' --packages-up-to ', rmwPkgsToBuild{:},' --cmake-args', config,' -DCMAKE_EXE_LINKER_FLAGS=',systemLibs,' -DBUILD_TESTING=OFF -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DCMAKE_INSTALL_RPATH=\$ORIGIN/../lib ', ...
                            optimizationFlagsForUnix];
                    else
                        colconMakeArgsMap(computer('arch'))  = [' --packages-up-to ', rmwPkgsToBuild{:},' --cmake-args', config,' -DBUILD_TESTING=OFF -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DCMAKE_INSTALL_RPATH="@loader_path/../lib" ', ...
                            optimizationFlagsForUnix];
                    end
                end

                colconMakeArgs = colconMakeArgsMap(computer('arch'));
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
                
                rmwImplInstallDir = fullfile(packageRootDir,'install');
                rmwImplDllPathMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                    { ...
                    fullfile(rmwImplInstallDir,'bin','*.dll') ...
                    fullfile(rmwImplInstallDir,'lib','*.dylib'),...
                    fullfile(rmwImplInstallDir,'lib','*.dylib'),...
                    fullfile(rmwImplInstallDir,'lib','*.so'),...
                    });
                rmwImplDllPath = rmwImplDllPathMap(computer('arch'));

                rmwReg = ros.internal.CustomRMWRegistry.getInstance();
                for iPkg = 1:numel(rmwpkgsInlocation{:})
                    rmwReg.updateRMWEntry(rmwpkgsInlocation{:}{iPkg}, rmwImplInstallDir,folderPath, rmwImplDllPath, middlewareEnv.MiddlewareHome);
                end
                obj.NextButton.Enable = 'on';
                obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionStatic').getString;
            else
                if contains(Exception,'stdout_stderr.log')
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedLogFile',fullfile(Exception)).getString()};
                else
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedStatus',Exception).getString()};
                end
                obj.BuildStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.NextButton.Enable = 'off';
                obj.NextActionText.Text = '';
            end
        end
    end
    
    methods(Access = private)
        
        function SetBuildStatusTable(obj,status)
            % Set the status table widget for build
            if strcmpi(status,'on')
                obj.BuildStatusTable.Visible = 'on';
                obj.BuildStatusTable.Enable = 'on';
            elseif strcmpi(status,'off')
                obj.BuildStatusTable.Visible = 'off';
                obj.BuildStatusTable.Enable = 'off';
            end
        end
    end
end
