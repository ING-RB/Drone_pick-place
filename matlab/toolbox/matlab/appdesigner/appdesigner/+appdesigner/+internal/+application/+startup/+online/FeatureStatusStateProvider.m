classdef FeatureStatusStateProvider < appdesigner.internal.application.startup.StartupStateProvider
    %FeatureStatusStateProvider
    %
    % Builds up information for App Designer startup for the currently
    % active and licensed features, e.g. Compiler.
    %
    % These features are the ones enabled / disabled while App Designer
    % runs in MATLAB Online.
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

            % Features always on in Online
            state.FeatureStatus.AutoSaveOnClickAway = true;
            state.FeatureStatus.UniversalSearchSupport = true;
            state.FeatureStatus.ShortcutsDialogSupport = true;

            % Features not supported in Online
            state.FeatureStatus.AppSharing = false;
            state.FeatureStatus.AppCompiling = false;
            state.FeatureStatus.SimulinkAppCompiling = false;
            state.FeatureStatus.AutoCaptureScreenshot = false;
            state.FeatureStatus.CodeComparison = false;
            state.FeatureStatus.EditorUncommentShortcut = false;
            state.FeatureStatus.OpenInFileManager = false;
            state.FeatureStatus.UseBrowserClipboard = true;
        end
    end
end
