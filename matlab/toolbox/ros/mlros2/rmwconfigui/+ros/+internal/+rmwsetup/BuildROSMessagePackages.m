classdef BuildROSMessagePackages < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % BuildCustomRMWPackage - Screen implementation to enable users to build the
    % RMW Implementation for custom middleware.
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        % ScreenInstructions - Instructions on the screen
        ScreenInstructions

        % BuildMsgsButton - Button to build the ROS message packages for custom RMW
        % implementations
        BuildMsgsButton

        % Build Status Table to show the status of build
        BuildStatusTable

        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton

        % Spinner widget
        BusySpinner

        % NextActionText - Text to show the next action.
        NextActionText
    end

    properties (Access = private)
        % RMW Implementation package build directory
        RMWBuildDir
    end
    
    methods
        function obj = BuildROSMessagePackages(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:BuildMessagesScreenTitle').getString;
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:BuildMessagesScreenInstructions').getString;
            obj.ScreenInstructions.Position = [20 250 430 130];
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
            obj.BuildMsgsButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            obj.BuildMsgsButton.Text = message('ros:mlros2:rmwsetup:BuildMessagesButton').getString;
            obj.BuildMsgsButton.ButtonPushedFcn = @obj.buildMsgsButtonCallback;
            obj.BuildMsgsButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.BuildMsgsButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;

            obj.setScreenProperty();

            % Maintain the selected RMW package directory location in the
            % session.
            session = obj.Workflow.getSession;
            if isKey(session, 'RMWLocationToPackagesMap')
                pkgLocation = session('RMWLocationToPackagesMap').keys;
                obj.RMWBuildDir = pkgLocation{:};
            end

            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            obj.NextActionText = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.NextActionText.Position = [30 10 410 30];
            obj.NextActionText.Text = '';
        end
        
        function setScreenProperty(obj)
            obj.BuildMsgsButton.Position = [20 270 160 25];
            obj.BuildStatusTable.ColumnWidth = [20 430];
            obj.BuildStatusTable.Position = [20 50 430 180];

            obj.ConfigurationInstructions.Text = '';
            % Set the Help Text
            obj.HelpText.AboutSelection = message('ros:mlros2:rmwsetup:BuildMessagesScreenAboutSelection').getString;
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:BuildMessagesScreenWhatToConsider').getString;

            obj.NextButton.Enable = 'off';
            obj.NextActionText.Visible='off';
        end %End of setScreenProperty method
        
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
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
        end
        
        
        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.BuildCustomRMWPackage';
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:Screen_Loading').getString;
            obj.BusySpinner.show();

            %Show screen to Test the RMW Implementation
            out = 'ros.internal.rmwsetup.TestRMWImplementation';
        end

        function buildMsgsButtonCallback(obj,~,~)
            %% buildMsgsButtonCallback - Callback function when user clicks the 
            % Build Message Artifacts button on the screen

            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';
            obj.SetBuildStatusTable('off');
            obj.setScreenProperty();
            %Disable the screen before starting BusySpinner
            obj.disableScreen();
            %Enable the BusySpinner while Firmware build is taking
            %place
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:BuildMessagesScreenSpinnerOne').getString;
            obj.BusySpinner.show();
            drawnow;

            try
                rmwReg = ros.internal.CustomRMWRegistry.getInstance();
                rmwInfo = rmwReg.getRMWInfo(obj.Workflow.RMWImplementation);

                folderPath = convertStringsToChars(rmwInfo.srcPath);
                folderPath = ros.internal.Parsing.validateFolderPath(folderPath);

                [packageRootDir, rmwpackageName] = fileparts(folderPath);

                %build middleware implementation
                builder = ros.ros2.internal.ColconBuilder(packageRootDir,rmwpackageName);
                srcDir = fullfile(ros.ros2.internal.getAmentPrefixPath,'share');

                % {'action_tutorials_interfaces', 'example_interfaces','move_base_msgs', 'test_msgs', 'tf2_msgs'} 
                % msgPkgDirs = {'action_msgs', 'actionlib_msgs',...
                %                'builtin_interfaces', 'composition_interfaces', 'diagnostic_msgs', ...
                %                'geometry_msgs', 'lifecycle_msgs', ...
                %                'logging_demo', 'map_msgs', 'nav_msgs', ...
                %                'pendulum_msgs', 'rcl_interfaces', 'rosgraph_msgs', 'sensor_msgs', ...
                %                'shape_msgs', 'statistics_msgs', 'std_msgs', 'std_srvs', ...
                %                'stereo_msgs', 'trajectory_msgs', ...
                %                'unique_identifier_msgs','visualization_msgs'};

                % All custom messages which will be copied to user 
                % provided RMW implementation package location.

                stdMsgDirs = ros.internal.custommsgs.getPkgDirs(fullfile(ros.ros2.internal.getAmentPrefixPath,'share'));
                msgReg = ros.internal.CustomMessageRegistry.getInstance('ros2');
                customMsgList = msgReg.getMessageList;
                msgPkgDirsFullPath = {};
                for iDir = 1:numel(stdMsgDirs)
                    msgPkgDirsFullPath{iDir} = fullfile(srcDir, stdMsgDirs{iDir}); %#ok<AGROW>
                end

                for iDir = 1:numel(customMsgList)
                    msgInfo = msgReg.getMessageInfo(customMsgList{iDir});
                    msgPath = fullfile(msgInfo.installDir,'share');
                    customMsgDirs = ros.internal.custommsgs.getPkgDirs(msgPath);
                    for iCustomDir=1:numel(customMsgDirs)
                        if ~ismember(customMsgDirs{iCustomDir},stdMsgDirs)
                            msgPkgDirsFullPath = [msgPkgDirsFullPath fullfile(msgPath,customMsgDirs{iCustomDir})]; %#ok<AGROW>
                        end
                    end
                end

                msgPkgDirsFullPath = unique(msgPkgDirsFullPath);
                for i=1:numel(msgPkgDirsFullPath)
                    [~,msgPkgDir] = fileparts(msgPkgDirsFullPath{i});
                    msgDir = fullfile(msgPkgDirsFullPath{i},'msg');
                    srvDir = fullfile(msgPkgDirsFullPath{i},'srv');
                    actionDir = fullfile(msgPkgDirsFullPath{i},'action');
                    msgFiles = dir(fullfile(msgDir,'*.msg'));
                    srvFiles = dir(fullfile(srvDir,'*.srv'));
                    srvMsgFiles = dir(fullfile(srvDir,'*.msg'));
                    actionFiles = dir(fullfile(actionDir,'*.action'));

                    if isfolder(msgDir) && ~isempty(msgFiles)
                        builder.copyFiles({fullfile(msgDir,'*.msg')}, ...
                            fullfile(builder.RootDir,msgPkgDir,'msg'));
                    end
                    if isfolder(srvDir)
                        if ~isempty(srvMsgFiles)
                            builder.copyFiles({fullfile(srvDir,'*.msg')}, ...
                                fullfile(builder.RootDir,msgPkgDir,'srv'));
                        end
                        if ~isempty(srvFiles)
                            builder.copyFiles({fullfile(srvDir,'*.srv')}, ...
                                fullfile(builder.RootDir,msgPkgDir,'srv'));
                        end
                    end
                    if isfolder(actionDir) && ~isempty(actionFiles)
                        builder.copyFiles({fullfile(actionDir,'*.action')}, ...
                            fullfile(builder.RootDir,msgPkgDir,'action'));
                    end
                end

                obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:BuildMessagesScreenSpinnerTwo').getString;
                if isequal(obj.Workflow.RMWImplementation, 'rmw_ecal_proto_cpp')
                    ros2genmsg(builder.RootDir, UseNinja=false, SuppressOutput=true);
                else
                    ros2genmsg(builder.RootDir, SuppressOutput=true);
                end
                builResultPath = fullfile(builder.RootDir,'matlab_msg_gen',computer('arch'),'BuildResult.mat');
                if isfile(builResultPath)
                    load(builResultPath, 'buildResultMap');
                end
                result = buildResultMap('BuildResult');
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
                obj.BuildStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                obj.BuildStatusTable.Steps = { message('ros:mlros2:rmwsetup:BuildRMWPackageSuccess',fullfile(result)).getString() };
                obj.NextButton.Enable = 'on';
                obj.NextActionText.Visible = 'on';
                obj.NextActionText.Text = message('ros:mlros2:rmwsetup:RMWValidationNextActionStatic').getString;
            else
                obj.BuildStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                if contains(Exception,'stdout_stderr.log')
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedLogFile',fullfile(Exception)).getString()};
                else
                    obj.BuildStatusTable.Steps = {message('ros:mlros2:rmwsetup:BuildRMWPackageFailedStatus',Exception).getString()};
                end
                obj.NextButton.Enable = 'off';
                obj.NextActionText.Text = '';
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
    end
end
