classdef EnvironmentStateProvider < appdesigner.internal.application.startup.StartupStateProvider
% ENVIRONMENTSTATEPROVIDER Builds up information for App Designer startup for the
% current working directory and which app or tutorial to open on startup.  This
% provider should be used to determine the environment in which App Designer
% is started and if an existing app or tutorial should be opened.
%
% Stores its state under the 'Environment' key on the struct that is returned.

% Copyright 2018-2024 The MathWorks, Inc.

    methods
        function state = getState(~, startupArguments)
            state.Environment = struct();
            currentWorkingDirectory = pwd;

            % Add a trailing file separator if necessary
            if ~strcmp(currentWorkingDirectory(end), filesep)
                state.Environment.CurrentWorkingDirectory = [currentWorkingDirectory, filesep];
            else
                state.Environment.CurrentWorkingDirectory = currentWorkingDirectory;
            end

            if isfield(startupArguments, 'FileName')
                state.Environment.OpenApp = startupArguments.FileName;
            end

            if isfield(startupArguments, 'Tutorial')
                state.Environment.OpenTutorial = startupArguments.Tutorial;
            end

            if isfield(startupArguments, 'NewApp') && ~isempty(startupArguments.NewApp)
                state.Environment.NewApp = startupArguments.NewApp;
            end

            % Setting the WindowStrategy field to the same name as the
            % BrowserControllerFactory ('CEF', 'Chrome', 'MATLAB Online',
            % 'None') so that the view can create the corresponding
            % WindowStrategy.
            appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();
            state.Environment.WindowStrategy = char(appDesignEnvironment.BrowserControllerFactory);

            serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();
            state.Environment.ViewModelManagerType = char(serviceProvider.ViewModelManagerFactory);

            % IsWebUI will be true for JSD and false if Java desktop.
            state.Environment.IsWebUI = appdesservices.internal.util.MATLABChecker.isJSD();
            state.Environment.IsPlainTextEnabled = logical(matlab.internal.feature('AppDesignerPlainTextFileFormat'));

            s = settings;
            % g3454235: Pass current theme to apply during startup
            if s.matlab.appearance.hasSetting('MATLABTheme')
                state.Environment.MATLABTheme = lower(s.matlab.appearance.MATLABTheme.ActiveValue);
            else
                state.Environment.MATLABTheme = 'light';
            end

            % g3235705
            state.Environment.NameLengthMax = namelengthmax;

            if isfield(startupArguments, 'ShowAppDetails') && startupArguments.ShowAppDetails
                state.Environment.PostAppLoadActions = {'ShowAppDetails'};
            end

            % Add GraphicsTheme setting to the state if it exists
            if (s.matlab.hasGroup('appearance') && s.matlab.appearance.hasGroup('figure'))
                figureSettings = s.matlab.appearance.figure;
                if figureSettings.hasSetting('GraphicsTheme')
                    state.Environment.GraphicsTheme = figureSettings.GraphicsTheme.ActiveValue;
                end
            end
        end
    end
end
