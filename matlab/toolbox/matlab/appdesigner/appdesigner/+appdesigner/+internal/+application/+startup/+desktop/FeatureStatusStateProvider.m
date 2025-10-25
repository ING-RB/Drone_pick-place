classdef FeatureStatusStateProvider < appdesigner.internal.application.startup.StartupStateProvider
    %FeatureStatusStateProvider
    %
    % Builds up information for App Designer startup for the currently
    % active and licensed features, e.g. Compiler.
    %
    % These features are the ones enabled / disabled while App Designer
    % runs in the desktop.
    %
    % This provider should be used to help the client determine what
    % functionality should be enabled or disabled.  For example, if there
    % is no Compiler license available then the "Share -> Web App" and
    % "Share -> Desktop App" options are disabled.
    %
    % Stores its state under the 'FeatureStatus' key on the struct that is
    % returned.

    % Copyright 2018-2024 The MathWorks, Inc.

    methods
        function state = getState(obj, startupArguments)
            state.FeatureStatus = struct;

            % Add the compiler information which indicates if this MATLAB
            % has compiler integrated in and if this MATLAB license
            % includes compiler functionality.
            if appdesigner.internal.license.LicenseChecker.isProductAvailable("Compiler")
                state.FeatureStatus.AppCompiling = true;

                % Simulink apps require MATLAB Compiler & Simulink Compiler licenses for deployment workflows
                if appdesigner.internal.license.LicenseChecker.isProductAvailable("simulink_compiler")
                    state.FeatureStatus.SimulinkAppCompiling = true;
                end
            end

            % Determined by editor's settings
            s = settings;
            state.FeatureStatus.AutoSaveOnClickAway = s.matlab.appdesigner.AutoSaveOnClickAway.ActiveValue;

            % Features always supported in desktop
            state.FeatureStatus.AppSharing = true;
            state.FeatureStatus.AutoCaptureScreenshot = true;
            state.FeatureStatus.CodeComparison = true;
            state.FeatureStatus.EditorUncommentShortcut = true;
            state.FeatureStatus.OpenInFileManager = (ispc || ismac);
            state.FeatureStatus.UseBrowserClipboard = false;

            % Features supported only in JSD
            state.FeatureStatus.ShortcutsDialogSupport = feature('webui') == 1;
            state.FeatureStatus.UniversalSearchSupport = feature('webui') == 1;
        end
    end
end
