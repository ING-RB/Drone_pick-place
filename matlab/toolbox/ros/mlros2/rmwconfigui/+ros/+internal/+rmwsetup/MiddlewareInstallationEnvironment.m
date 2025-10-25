classdef MiddlewareInstallationEnvironment < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % MiddlewareInstallationEnvironment - Screen provides the instructions
    % to set the Middleware installation location and also environment
    % variables specific to the middleware.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})

        %ScreenInstructions - Instructions on the screen
        ScreenInstructions

        % MiddlewareInstallationEditText - Text box area to show install location that has
        % to be validated.
        MiddlewareInstallationEditText

        % MiddlewareInstallationBrowser - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        MiddlewareInstallationBrowser

        % EnvVariablesLabel - Environment Variables Label Text
        EnvVariablesLabel

        % EnvSettingsTable - Table for middleware environment settings
        EnvSettingsTable

        % AddButton - Button to add environment variable to the table
        AddButton

        % RemoveButton - Button to remove environment variable from the table
        RemoveButton
    end

    properties (Access = private)
        % Spinner widget
        BusySpinner

        % MiddlewareEnvironment - object containing middleware Installation preferences
        MiddlewareEnvironment

        % EnvVariablesMap - Map of user specified Environment variables
        EnvVariablesMap
    end

    methods

        function obj = MiddlewareInstallationEnvironment(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})

            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:MiddlewareInstallationEnvScreen').getString;
            obj.Title.Position = [20 7 550 25];

            obj.NextButton.Enable = 'off';

            % Set Description Properties
            obj.ScreenInstructions = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.ScreenInstructions.Position = [20 330 420 50];
            obj.ScreenInstructions.Text = message('ros:mlros2:rmwsetup:MiddlewareInstallationEnvScreenInstructions').getString;
            obj.ConfigurationInstructions.Visible = 'off';

            %Set MiddlewareInstallationEditText Properties
            obj.MiddlewareInstallationEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.MiddlewareInstallationEditText.ValueChangedFcn = @obj.editCallbackFcn;
            obj.MiddlewareInstallationEditText.Position = [20 290 330 20];
            obj.MiddlewareInstallationEditText.TextAlignment = 'left';

            % Set MiddlewareInstallationBrowser button Properties
            obj.MiddlewareInstallationBrowser = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.MiddlewareInstallationBrowser.Text = message('ros:mlros2:rmwsetup:BrowseButton').getString;
            obj.MiddlewareInstallationBrowser.Position = [370 288 70 24];
            obj.MiddlewareInstallationBrowser.Color = matlab.hwmgr.internal.hwsetup.util.Color.HELPBLUE;
            obj.MiddlewareInstallationBrowser.ButtonPushedFcn = @obj.middlewareInstallationBrowserFcn;

            % Set the Label text
            obj.EnvVariablesLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.EnvVariablesLabel.Text = message('ros:mlros2:rmwsetup:EnvironmentVariablesLabel').getString;
            obj.EnvVariablesLabel.Position = [20 250 170 20];
            obj.EnvVariablesLabel.FontWeight = 'bold';

            obj.EnvSettingsTable = matlab.hwmgr.internal.hwsetup.Table.getInstance(obj.ContentPanel);
            obj.EnvSettingsTable.Position = [20 50 420 180];
            obj.EnvSettingsTable.Data = {};
            obj.EnvSettingsTable.Tag = 'EnivronmentVariablesTable';
            % ColumnWidth
            % Data type: cell array of either 'auto' or a pixel
            obj.EnvSettingsTable.ColumnWidth = {'auto','auto'};
            % ColumnName
            % Data type: cell array
            obj.EnvSettingsTable.ColumnName = {'Variable','Value'};

            % ColumnEditable
            % Data type: logical
            obj.EnvSettingsTable.ColumnEditable = true;
            obj.EnvSettingsTable.CellSelectionFcn = @obj.enableRemoveButton;
            obj.EnvSettingsTable.CellEditFcn = @obj.cellEditCb;
            % Set a callback

            obj.AddButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.AddButton.Text = message('ros:mlros2:rmwsetup:AddEnvButton').getString;
            obj.AddButton.Position = [300 10 60 24];
            % Set callback when finish button is pushed
            obj.AddButton.ButtonPushedFcn = @obj.addEnvironment;

            obj.RemoveButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.RemoveButton.Text = message('ros:mlros2:rmwsetup:RemoveEnvButton').getString;
            obj.RemoveButton.Position = [380 10 60 24];
            obj.RemoveButton.Enable = 'off';
            obj.RemoveButton.ButtonPushedFcn = @obj.removeEnvironment;

            % Create a handle to MiddlewareEnvironment object
            obj.MiddlewareEnvironment = ros.internal.MiddlewareEnvironment.getInstance();
            middlewareRootMap = obj.MiddlewareEnvironment.MiddlewareRoot;
            if ~isempty(middlewareRootMap) && isKey(middlewareRootMap,obj.MiddlewareEnvironment.MiddlewareHome) ...
                    && ~isempty(middlewareRootMap(obj.MiddlewareEnvironment.MiddlewareHome))
                getCurrentScreenValues(obj);
            end

            obj.EnvVariablesMap = containers.Map();

            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';

            % Set the Help Text
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = message('ros:mlros2:rmwsetup:MiddlewareInstallationEnvScreenWhatToConsider').getString;

        end

        function reinit(obj)
            % Disable BusySpinner
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();
            obj.ConfigurationImage.ImageFile = '';
            obj.RemoveButton.Enable = 'off';
            drawnow;
        end

        function out = getPreviousScreenID(obj)
            session = obj.Workflow.getSession;
            rmwPkgsMap = session('RMWTypeSupportMap');
            typesupports = rmwPkgsMap.values;
            if ismember('static',typesupports)
                if ~ismember('PkgSelectionMap',session.keys)
                    out = 'ros.internal.rmwsetup.ValidateROSIDLTypeSupport';
                else
                    out = 'ros.internal.rmwsetup.ChooseRMWImplementation';
                end
            else
                if ~ismember('PkgSelectionMap',session.keys)
                    out = 'ros.internal.rmwsetup.ValidateRMWImplementation';
                else
                    out = 'ros.internal.rmwsetup.ChooseRMWImplementation';
                end
            end
        end

        function out = getNextScreenID(obj)
            %Show Busy Spinner while the Next screen loads
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:MiddlewareInstallationEnvScreenSpinnerText').getString;
            obj.BusySpinner.show();

            session = obj.Workflow.getSession;
            pkgLocationToRMWMap = session('RMWLocationToPackagesMap');
             rmwpkgsInlocation = pkgLocationToRMWMap.values;
            if ismember('rmw_connextdds',rmwpkgsInlocation{:})
                if ispc
                    rtiInstallArchName = 'x64Win64VS2017';
                else
                    scriptsDir = fullfile(obj.MiddlewareInstallationEditText.Text, 'resource','scripts');
                    if isfolder(scriptsDir)
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
                    end
                end
                ddsEnv = ros.internal.DDSEnvironment();
                ddsEnv.DDSHome = obj.MiddlewareInstallationEditText.Text;
                if ~isempty(rtiInstallArchName)
                    ddsEnv.checkAndCreatePref(rtiInstallArchName);
                end
            elseif ismember('rmw_iceoryx_cpp', rmwpkgsInlocation{:})
                iceoryxEnvironment = ros.internal.IceoryxEnvironment();
                iceoryxEnvironment.IceoryxHome = obj.MiddlewareInstallationEditText.Text;
                iceoryxEnvironment.checkAndCreatePref();
            end

            obj.MiddlewareEnvironment.MiddlewareHome = obj.MiddlewareInstallationEditText.Text;
            obj.MiddlewareEnvironment.updateMiddlewareInstallationEntry(obj.MiddlewareInstallationEditText.Text, obj.EnvVariablesMap);

            %Show screen to Build the RMW Implementation
            out = 'ros.internal.rmwsetup.BuildCustomRMWPackage';
        end
    end

    methods(Access = 'private')
        function editCallbackFcn(obj,~,~)
            if ~isempty(obj.MiddlewareInstallationEditText.Text)
                obj.NextButton.Enable = 'on';
            end

            if ~isequal(obj.MiddlewareInstallationEditText.Text, obj.MiddlewareEnvironment.MiddlewareHome)
                if ismember(obj.MiddlewareInstallationEditText.Text, obj.MiddlewareEnvironment.MiddlewareMap.keys)
                    obj.EnvSettingsTable.Data(:,1)= obj.MiddlewareEnvironment.MiddlewareMap(obj.MiddlewareInstallationEditText.Text).keys();
                    obj.EnvSettingsTable.Data(:,2)= obj.MiddlewareEnvironment.MiddlewareMap(obj.MiddlewareInstallationEditText.Text).values();
                end
            end
            drawnow;
        end

        function middlewareInstallationBrowserFcn(obj, ~, ~)
            % middlewareInstallationBrowserFcn - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.MiddlewareInstallationEditText.Text
            dir = uigetdir(obj.MiddlewareInstallationEditText.Text, message('ros:mlros2:rmwsetup:MiddlewareInstallationEnvScreenBrowse').getString);

            % App loses focus when user cancels out of uigetfile. Set focus back to app
            uiFigHandle = findobjinternal(0,'Type','Figure','Name',getString(message('ros:mlros2:rmwsetup:MainWindowTitle')));
            if ~isempty(uiFigHandle)
                focus(uiFigHandle);
            end

            if dir % If the user cancels the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (MiddlewareInstallationEditText.Text).
                obj.MiddlewareInstallationEditText.Text = dir;
            end
        end

        function getCurrentScreenValues(obj)
            obj.MiddlewareInstallationEditText.Text = obj.MiddlewareEnvironment.MiddlewareHome;
            if ~isempty(obj.MiddlewareEnvironment.MiddlewareMap(obj.MiddlewareEnvironment.MiddlewareHome))
                obj.EnvSettingsTable.Data(:,1)= obj.MiddlewareEnvironment.MiddlewareMap(obj.MiddlewareEnvironment.MiddlewareHome).keys();
                obj.EnvSettingsTable.Data(:,2)= obj.MiddlewareEnvironment.MiddlewareMap(obj.MiddlewareEnvironment.MiddlewareHome).values();
            end
        end

        function addEnvironment(obj, ~, ~)
            obj.EnvSettingsTable.Data(end+1,:)={'',''};
        end

        function removeEnvironment(obj, ~, ~)
            if ~isempty(obj.EnvSettingsTable.Selection)
                indexSelected = obj.EnvSettingsTable.Selection(1);
                if ismember(obj.EnvSettingsTable.Data{indexSelected,1}, obj.EnvVariablesMap.keys())
                    remove(obj.EnvVariablesMap,obj.EnvSettingsTable.Data{indexSelected,1});
                end
                obj.EnvSettingsTable.Data(indexSelected,:)=[];
            end
            obj.RemoveButton.Enable = 'off';
        end

        function enableRemoveButton(obj,~,~)
            if ~isempty(obj.EnvSettingsTable.Selection)
                obj.RemoveButton.Enable = 'on';
            else
                obj.RemoveButton.Enable = 'off';
            end
        end

        function cellEditCb(obj,~,src)
            if ~isempty(obj.EnvSettingsTable.Selection) && ismember('NewData',fields(src)) && ~isequal(src.NewData, src.PreviousData)
                obj.EnvVariablesMap(obj.EnvSettingsTable.Data{obj.EnvSettingsTable.Selection(1),1}) = ...
                    obj.EnvSettingsTable.Data{obj.EnvSettingsTable.Selection(1),2};
            end
        end
    end
end