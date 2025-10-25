classdef ProxyPreferencesPanel < handle
    %PROXYPREFERENCESPANEL   The preferences panel for MATLAB proxy settings.
    %   This class describes the MATLAB proxy settings pane in the
    %   Preferences window.

    %   Copyright 2020-2023 The MathWorks, Inc.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        % Widgets
        MainGridLayout                 matlab.ui.container.GridLayout
        SystemWebBrowserPanel          matlab.ui.container.Panel
        SystemWebBrowserGridLayout     matlab.ui.container.GridLayout
        CommandAndOptionsGridLayout    matlab.ui.container.GridLayout
        OptionsEditField               matlab.ui.control.EditField
        OptionsEditFieldLabel          matlab.ui.control.Label
        CommandEditField               matlab.ui.control.EditField
        CommandLabel                   matlab.ui.control.Label
        SystemWebBrowserLabel          matlab.ui.control.Label
        UseSystemWebBrowserCheckBox    matlab.ui.control.CheckBox
        InternetConnectionPanel        matlab.ui.container.Panel
        InternetConnectionGridLayout   matlab.ui.container.GridLayout
        UseProxyGridLayout             matlab.ui.container.GridLayout
        UsernameAndPasswordGridLayout  matlab.ui.container.GridLayout
        ProxyPasswordEditField         matlab.ui.control.internal.PasswordField
        ProxyPasswordEditFieldLabel    matlab.ui.control.Label
        ProxyUsernameEditField         matlab.ui.control.EditField
        ProxyUsernameEditFieldLabel    matlab.ui.control.Label
        ProxyHostAndPortGridLayout     matlab.ui.container.GridLayout
        ProxyPortEditFieldLabel        matlab.ui.control.Label
        ProxyHostEditFieldLabel        matlab.ui.control.Label
        ProxyPortEditField             matlab.ui.control.EditField
        ProxyHostEditField             matlab.ui.control.EditField
        UseAuthenticationCheckBox      matlab.ui.control.CheckBox
        TestConnectionGridLayout       matlab.ui.container.GridLayout
        TestConnectionResultLabel      matlab.ui.control.Label
        TestConnectionButton           matlab.ui.control.Button
        UseProxyCheckBox               matlab.ui.control.CheckBox
    end


    properties (Access = private)
        % Other properties
        ProxyConnectionValidationFcn = @() matlab.ui.internal.preferences.preferencePanels.ProxyPreferencesPanel.testProxyConnectionImpl;
        Settings                       matlab.settings.SettingsGroup;
    end

    properties (Access = ?tProxyPreferencesPanel)
        ProxyPasswordToken
    end

    methods (Access = private)

        function s = readProxyPreferencesFromUi(app)
            s = struct();
            s.UseProxy = app.UseProxyCheckBox.Value;
            s.ProxyHost = strtrim(app.ProxyHostEditField.Value);
            s.ProxyPort = strtrim(app.ProxyPortEditField.Value);
            s.UseProxyAuthentication = app.UseAuthenticationCheckBox.Value;
            s.ProxyUsername = app.ProxyUsernameEditField.Value;
        end

        function writeProxyPreferencesToUi(app, s)
            app.UseProxyCheckBox.Value = s.UseProxy;
            app.ProxyHostEditField.Value = s.ProxyHost;
            app.ProxyPortEditField.Value = s.ProxyPort;
            app.UseAuthenticationCheckBox.Value = s.UseProxyAuthentication;
            app.ProxyUsernameEditField.Value = s.ProxyUsername;
            % Can't set the value on the PasswordField, leave it blank

            app.ProxyHostEditField.Enable = s.UseProxy;
            app.ProxyHostEditFieldLabel.Enable = s.UseProxy;

            app.ProxyPortEditField.Enable = s.UseProxy;
            app.ProxyPortEditFieldLabel.Enable = s.UseProxy;

            app.UseAuthenticationCheckBox.Enable = s.UseProxy;

            app.ProxyUsernameEditField.Enable = s.UseProxy && s.UseProxyAuthentication;
            app.ProxyUsernameEditFieldLabel.Enable = s.UseProxy && s.UseProxyAuthentication;

            app.ProxyPasswordEditField.Enable = s.UseProxy && s.UseProxyAuthentication;
            app.ProxyPasswordEditFieldLabel.Enable = s.UseProxy && s.UseProxyAuthentication;
        end

        function s = readBrowserPreferencesFromUi(app)
            s = struct();
            s.SystemBrowserForExternalSites = app.UseSystemWebBrowserCheckBox.Value;
            s.SystemBrowser = app.CommandEditField.Value;
            s.SystemBrowserOptions = app.OptionsEditField.Value;
        end

        function writeBrowserPreferencesToUi(app, s)
            app.UseSystemWebBrowserCheckBox.Value = s.SystemBrowserForExternalSites;
            app.CommandEditField.Value = s.SystemBrowser;
            app.OptionsEditField.Value = s.SystemBrowserOptions;
        end

        function s = readProxyPreferencesFromSettings(app, valueType)
            if nargin < 2
                valueType = "ActiveValue";
            end

            s = struct();
            s.UseProxy = app.readFromSetting("UseProxy", valueType);
            s.ProxyHost = app.readFromSetting("ProxyHost", valueType);
            s.ProxyPort = app.readFromSetting("ProxyPort", valueType);
            s.UseProxyAuthentication = app.readFromSetting("UseProxyAuthentication", valueType);
            s.ProxyUsername = app.readFromSetting("ProxyUsername", valueType);
            s.ProxyPassword = app.readFromSetting("ProxyPassword", valueType);
        end

        function s = writeProxyPreferencesToSettings(app, s, valueType)
            if nargin < 3
                valueType = "PersonalValue";
            end

            app.writeToSetting("UseProxy", s.UseProxy, valueType);
            app.writeToSetting("ProxyHost", s.ProxyHost, valueType);
            app.writeToSetting("ProxyPort", s.ProxyPort, valueType);
            app.writeToSetting("UseProxyAuthentication", s.UseProxyAuthentication, valueType);
            app.writeToSetting("ProxyUsername", s.ProxyUsername, valueType);
            if isfield(s, "ProxyPassword")
                app.writeToSetting("ProxyPassword", s.ProxyPassword, valueType);
            else
                switch (valueType)
                    case "TemporaryValue"
                        valueType = "session";
                    case "PersonalValue"
                        valueType = "user";
                end
                if ~isempty(app.ProxyPasswordToken)
                    matlab.net.internal.writeProxyPasswordSetting( ...
                        app.ProxyPasswordToken, valueType);
                end
            end
        end

        function s = readBrowserPreferencesFromSettings(app, valueType)
            if nargin < 2
                valueType = "ActiveValue";
            end

            s = struct();
            s.SystemBrowserForExternalSites = app.readFromSetting("SystemBrowserForExternalSites", valueType);
            s.SystemBrowser = app.readFromSetting("SystemBrowser", valueType);
            s.SystemBrowserOptions = app.readFromSetting("SystemBrowserOptions", valueType);
        end

        function writeBrowserPreferencesToSettings(app, s, valueType)
            if nargin < 3
                valueType = "PersonalValue";
            end

            app.writeToSetting("SystemBrowserForExternalSites", s.SystemBrowserForExternalSites, valueType);
            app.writeToSetting("SystemBrowser", s.SystemBrowser, valueType);
            app.writeToSetting("SystemBrowserOptions", s.SystemBrowserOptions, valueType);
        end

        function writeToSetting(app, name, value, valueType)
            if app.Settings.(name).hasTemporaryValue()
                app.Settings.(name).clearTemporaryValue();
            end
            if ~all(ismissing(value))
                app.Settings.(name).(valueType) = value;
            elseif app.Settings.(name).("has" + valueType)()
                app.Settings.(name).("clear" + valueType)();
            end
        end

        function value = readFromSetting(app, name, valueType)
            try
                value = app.Settings.(name).(valueType);
            catch
                value = missing;
            end
        end

        function updateProxyPreferencesUiEnablement(app)
            useProxy = app.UseProxyCheckBox.Value;

            app.ProxyHostEditField.Enable = useProxy;
            app.ProxyHostEditFieldLabel.Enable = useProxy;

            app.ProxyPortEditField.Enable = useProxy;
            app.ProxyPortEditFieldLabel.Enable = useProxy;

            app.UseAuthenticationCheckBox.Enable = useProxy;

            useAuth = app.UseAuthenticationCheckBox.Value;

            app.ProxyUsernameEditField.Enable = useProxy && useAuth;
            app.ProxyUsernameEditFieldLabel.Enable = useProxy && useAuth;

            app.ProxyPasswordEditField.Enable = useProxy && useAuth;
            app.ProxyPasswordEditFieldLabel.Enable = useProxy && useAuth;
        end

        function success = testProxyConnection(app)
            app.validatePreferences();

            old_settings = app.readProxyPreferencesFromSettings("TemporaryValue");
            cleanup = onCleanup(@() app.writeProxyPreferencesToSettings(old_settings, "TemporaryValue"));

            app.writeProxyPreferencesToSettings(app.readProxyPreferencesFromUi(), "TemporaryValue");

            success = app.ProxyConnectionValidationFcn();
        end

        function validatePreferences(app)
            s = app.readProxyPreferencesFromUi();
            if ~s.UseProxy
                return;
            end

            if s.ProxyHost == "" && s.ProxyPort == ""
                error(message('MATLAB:network:preferences:invalid_host_and_port'));
            end
            if s.ProxyHost == ""
                error(message('MATLAB:network:preferences:invalid_host'));
            end

            port_num = str2double(s.ProxyPort);
            if string(port_num) ~= s.ProxyPort || round(port_num) ~= port_num || port_num < 0 || port_num > 65535
                error(message('MATLAB:network:preferences:invalid_port'));
            end
        end

        function displayErrorMessage(app, err)
            if startsWith(err.identifier, "MATLAB:network:preferences")
                uialert(app.UIFigure, err.message, string(message('MATLAB:network:preferences:error_title')));
            end
        end

    end

    methods (Access = public)

        function success = commit(app)
            try
                app.validatePreferences();
                app.writeProxyPreferencesToSettings(app.readProxyPreferencesFromUi());
                app.writeBrowserPreferencesToSettings(app.readBrowserPreferencesFromUi());
                success = true;
            catch err
                app.displayErrorMessage(err);
                success = false;
            end
        end

        function setProxyPreferencesValidationFcn(app, validationFcn)
            app.ProxyConnectionValidationFcn = validationFcn;
        end
    end

    methods (Access = public, Static)
        function success = testProxyConnectionImpl()
            try
                mwDotCom = matlab.internal.UrlManager().MATHWORKS_DOT_COM;
                webread(mwDotCom);
                success = true;
            catch
                success = false;
            end
        end

        function tf = shouldShow()
            import matlab.internal.capability.Capability
            tf = Capability.isSupported(Capability.LocalClient);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.Settings = settings().matlab.web;
            app.writeProxyPreferencesToUi(app.readProxyPreferencesFromSettings());
            app.writeBrowserPreferencesToUi(app.readBrowserPreferencesFromSettings());
        end

        % Value changed function: UseProxyCheckBox
        function UseProxyCheckBoxValueChanged(app, ~)
            app.updateProxyPreferencesUiEnablement();
        end

        % Value changed function: UseAuthenticationCheckBox
        function UseAuthenticationCheckBoxValueChanged(app, ~)
            app.updateProxyPreferencesUiEnablement();
        end

        % Button pushed function: TestConnectionButton
        function TestConnectionButtonPushed(app, ~)
            app.TestConnectionResultLabel.Text = "";
            app.TestConnectionButton.Enable = false;
            cleanup = onCleanup(@() set(app.TestConnectionButton, 'Enable', true));
            drawnow();

            try
                success = app.testProxyConnection();
            catch err
                app.displayErrorMessage(err);
                success = false;
            end

            if success
                app.TestConnectionResultLabel.Text = string(message('MATLAB:network:preferences:success'));
            else
                app.TestConnectionResultLabel.Text = string(message('MATLAB:network:preferences:failure'));
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Name = string(message('MATLAB:network:preferences:name'));

            % Create MainGridLayout
            app.MainGridLayout = uigridlayout(app.UIFigure);
            app.MainGridLayout.ColumnWidth = {'1x'};
            app.MainGridLayout.RowHeight = {'fit', 'fit'};

            % Create InternetConnectionPanel
            app.InternetConnectionPanel = uipanel(app.MainGridLayout);
            app.InternetConnectionPanel.Title = string(message('MATLAB:network:preferences:proxy_group_title'));
            app.InternetConnectionPanel.Layout.Row = 1;
            app.InternetConnectionPanel.Layout.Column = 1;

            % Create InternetConnectionGridLayout
            app.InternetConnectionGridLayout = uigridlayout(app.InternetConnectionPanel);
            app.InternetConnectionGridLayout.ColumnWidth = {'1x'};
            app.InternetConnectionGridLayout.RowHeight = {'fit', 'fit', 'fit'};

            % Create UseProxyCheckBox
            app.UseProxyCheckBox = uicheckbox(app.InternetConnectionGridLayout);
            app.UseProxyCheckBox.ValueChangedFcn = @(~, event) app.UseProxyCheckBoxValueChanged(event);
            app.UseProxyCheckBox.Text = string(message('MATLAB:network:preferences:use_proxy_checkbox'));
            app.UseProxyCheckBox.WordWrap = 'on';
            app.UseProxyCheckBox.Layout.Row = 1;
            app.UseProxyCheckBox.Layout.Column = 1;

            % Create TestConnectionGridLayout
            app.TestConnectionGridLayout = uigridlayout(app.InternetConnectionGridLayout);
            app.TestConnectionGridLayout.ColumnWidth = {'fit', '1x'};
            app.TestConnectionGridLayout.RowHeight = {'1x'};
            app.TestConnectionGridLayout.Padding = [0 0 0 0];
            app.TestConnectionGridLayout.Layout.Row = 3;
            app.TestConnectionGridLayout.Layout.Column = 1;

            % Create TestConnectionButton
            app.TestConnectionButton = uibutton(app.TestConnectionGridLayout, 'push');
            app.TestConnectionButton.ButtonPushedFcn = @(~, event) app.TestConnectionButtonPushed(event);
            app.TestConnectionButton.Layout.Row = 1;
            app.TestConnectionButton.Layout.Column = 1;
            app.TestConnectionButton.Text = string(message('MATLAB:network:preferences:test_connection_button'));

            % Create TestConnectionResultLabel
            app.TestConnectionResultLabel = uilabel(app.TestConnectionGridLayout);
            app.TestConnectionResultLabel.Layout.Row = 1;
            app.TestConnectionResultLabel.Layout.Column = 2;
            app.TestConnectionResultLabel.Text = '';

            % Create UseProxyGridLayout
            app.UseProxyGridLayout = uigridlayout(app.InternetConnectionGridLayout);
            app.UseProxyGridLayout.ColumnWidth = {'1x'};
            app.UseProxyGridLayout.RowHeight = {'fit', 'fit', 'fit'};
            app.UseProxyGridLayout.Padding = [18 0 0 0];
            app.UseProxyGridLayout.Layout.Row = 2;
            app.UseProxyGridLayout.Layout.Column = 1;

            % Create UseAuthenticationCheckBox
            app.UseAuthenticationCheckBox = uicheckbox(app.UseProxyGridLayout);
            app.UseAuthenticationCheckBox.ValueChangedFcn = @(~, event) app.UseAuthenticationCheckBoxValueChanged(event);
            app.UseAuthenticationCheckBox.Text = string(message('MATLAB:network:preferences:use_proxy_authentication_checkbox'));
            app.UseAuthenticationCheckBox.WordWrap = 'on';
            app.UseAuthenticationCheckBox.Layout.Row = 2;
            app.UseAuthenticationCheckBox.Layout.Column = 1;

            % Create ProxyHostAndPortGridLayout
            app.ProxyHostAndPortGridLayout = uigridlayout(app.UseProxyGridLayout);
            app.ProxyHostAndPortGridLayout.ColumnWidth = {'fit', '1x', '4x'};
            app.ProxyHostAndPortGridLayout.RowHeight = {'fit', 'fit'};
            app.ProxyHostAndPortGridLayout.Padding = [0 0 0 0];
            app.ProxyHostAndPortGridLayout.Layout.Row = 1;
            app.ProxyHostAndPortGridLayout.Layout.Column = 1;

            % Create ProxyHostEditField
            app.ProxyHostEditField = uieditfield(app.ProxyHostAndPortGridLayout, 'text');
            app.ProxyHostEditField.Layout.Row = 1;
            app.ProxyHostEditField.Layout.Column = [2 3];

            % Create ProxyPortEditField
            app.ProxyPortEditField = uieditfield(app.ProxyHostAndPortGridLayout, 'text');
            app.ProxyPortEditField.Layout.Row = 2;
            app.ProxyPortEditField.Layout.Column = 2;

            % Create ProxyHostEditFieldLabel
            app.ProxyHostEditFieldLabel = uilabel(app.ProxyHostAndPortGridLayout);
            app.ProxyHostEditFieldLabel.Layout.Row = 1;
            app.ProxyHostEditFieldLabel.Layout.Column = 1;
            app.ProxyHostEditFieldLabel.Text = string(message('MATLAB:network:preferences:proxy_host'));

            % Create ProxyPortEditFieldLabel
            app.ProxyPortEditFieldLabel = uilabel(app.ProxyHostAndPortGridLayout);
            app.ProxyPortEditFieldLabel.Layout.Row = 2;
            app.ProxyPortEditFieldLabel.Layout.Column = 1;
            app.ProxyPortEditFieldLabel.Text = string(message('MATLAB:network:preferences:proxy_port'));

            % Create UsernameAndPasswordGridLayout
            app.UsernameAndPasswordGridLayout = uigridlayout(app.UseProxyGridLayout);
            app.UsernameAndPasswordGridLayout.ColumnWidth = {'fit', '1x'};
            app.UsernameAndPasswordGridLayout.RowHeight = {'fit', 22};
            app.UsernameAndPasswordGridLayout.Padding = [18 0 0 0];
            app.UsernameAndPasswordGridLayout.Layout.Row = 3;
            app.UsernameAndPasswordGridLayout.Layout.Column = 1;

            % Create ProxyUsernameEditFieldLabel
            app.ProxyUsernameEditFieldLabel = uilabel(app.UsernameAndPasswordGridLayout);
            app.ProxyUsernameEditFieldLabel.Layout.Row = 1;
            app.ProxyUsernameEditFieldLabel.Layout.Column = 1;
            app.ProxyUsernameEditFieldLabel.Text = string(message('MATLAB:network:preferences:proxy_username'));

            % Create ProxyUsernameEditField
            app.ProxyUsernameEditField = uieditfield(app.UsernameAndPasswordGridLayout, 'text');
            app.ProxyUsernameEditField.Layout.Row = 1;
            app.ProxyUsernameEditField.Layout.Column = 2;

            % Create ProxyPasswordEditFieldLabel
            app.ProxyPasswordEditFieldLabel = uilabel(app.UsernameAndPasswordGridLayout);
            app.ProxyPasswordEditFieldLabel.Layout.Row = 2;
            app.ProxyPasswordEditFieldLabel.Layout.Column = 1;
            app.ProxyPasswordEditFieldLabel.Text = string(message('MATLAB:network:preferences:proxy_password'));

            % Create ProxyPasswordEditField
            app.ProxyPasswordEditField = matlab.ui.control.internal.PasswordField( ...
                "Parent", app.UsernameAndPasswordGridLayout);
            app.ProxyPasswordEditField.PasswordEnteredFcn = @(~, evt) app.handleProxyPasswordEntered(evt);
            app.ProxyPasswordEditField.Layout.Row = 2;
            app.ProxyPasswordEditField.Layout.Column = 2;

            % Create SystemWebBrowserPanel
            app.SystemWebBrowserPanel = uipanel(app.MainGridLayout);
            app.SystemWebBrowserPanel.Title = string(message('MATLAB:network:preferences:system_browser_group'));
            app.SystemWebBrowserPanel.Layout.Row = 2;
            app.SystemWebBrowserPanel.Layout.Column = 1;

            % Create SystemWebBrowserGridLayout
            app.SystemWebBrowserGridLayout = uigridlayout(app.SystemWebBrowserPanel);
            app.SystemWebBrowserGridLayout.ColumnWidth = {'1x'};
            app.SystemWebBrowserGridLayout.RowHeight = {'fit', 'fit', 'fit'};

            % Create UseSystemWebBrowserCheckBox
            app.UseSystemWebBrowserCheckBox = uicheckbox(app.SystemWebBrowserGridLayout);
            app.UseSystemWebBrowserCheckBox.Text = string(message('MATLAB:network:preferences:system_browser_for_external_sites_checkbox'));
            app.UseSystemWebBrowserCheckBox.WordWrap = 'on';
            app.UseSystemWebBrowserCheckBox.Layout.Row = 1;
            app.UseSystemWebBrowserCheckBox.Layout.Column = 1;

            % Create SystemWebBrowserLabel
            app.SystemWebBrowserLabel = uilabel(app.SystemWebBrowserGridLayout);
            app.SystemWebBrowserLabel.WordWrap = 'on';
            app.SystemWebBrowserLabel.Layout.Row = 2;
            app.SystemWebBrowserLabel.Layout.Column = 1;
            app.SystemWebBrowserLabel.Text = string(message('MATLAB:network:preferences:system_browser_description'));

            % Create CommandAndOptionsGridLayout
            app.CommandAndOptionsGridLayout = uigridlayout(app.SystemWebBrowserGridLayout);
            app.CommandAndOptionsGridLayout.ColumnWidth = {'fit', '1x'};
            app.CommandAndOptionsGridLayout.RowHeight = {'fit', 'fit'};
            app.CommandAndOptionsGridLayout.Padding = [0 0 0 0];
            app.CommandAndOptionsGridLayout.Layout.Row = 3;
            app.CommandAndOptionsGridLayout.Layout.Column = 1;

            % Create CommandLabel
            app.CommandLabel = uilabel(app.CommandAndOptionsGridLayout);
            app.CommandLabel.Layout.Row = 1;
            app.CommandLabel.Layout.Column = 1;
            app.CommandLabel.Text = string(message('MATLAB:network:preferences:system_browser_command'));

            % Create CommandEditField
            app.CommandEditField = uieditfield(app.CommandAndOptionsGridLayout, 'text');
            app.CommandEditField.Layout.Row = 1;
            app.CommandEditField.Layout.Column = 2;

            % Create OptionsEditFieldLabel
            app.OptionsEditFieldLabel = uilabel(app.CommandAndOptionsGridLayout);
            app.OptionsEditFieldLabel.Layout.Row = 2;
            app.OptionsEditFieldLabel.Layout.Column = 1;
            app.OptionsEditFieldLabel.Text = string(message('MATLAB:network:preferences:system_browser_options'));

            % Create OptionsEditField
            app.OptionsEditField = uieditfield(app.CommandAndOptionsGridLayout, 'text');
            app.OptionsEditField.Layout.Row = 2;
            app.OptionsEditField.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

        function handleProxyPasswordEntered(app, evt)
            app.ProxyPasswordToken = evt.Token;
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ProxyPreferencesPanel

            % Create UIFigure and components
            app.createComponents();

            % Execute the startup function
            app.startupFcn();

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            if ~isempty(app.ProxyPasswordToken)
                try
                    matlab.net.internal.clearProxyPasswordToken( ...
                        app.ProxyPasswordToken);
                catch
                    % Ignore, we'll leave this password token behind
                end
            end

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
