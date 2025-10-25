classdef AppDebugUtilities < handle
    % APPDEBUGUTILITIES hide App Designer internal folders from call stacks
    % so user can see trimmed call stacks on debugging UI by default
    %
    % called by createAppDesignEnviroment.m, hide AD folders from call stacks by default
    % called by appdesigner_debug.m, uhide AD folders for debugging purpose
    %
    % >> appdesigner.internal.debug.AppDebugUtilities.hideInternalFoldersFromCallstack()
    % hide AD Folders at one time
    % >> appdesigner.internal.debug.AppDebugUtilities.unhideInternalFoldersFromCallstack()
    % unhide AD folder and set global setting to override default
    % after unhideInternalFoldersFromCallstack() get called,
    % hideInternalFoldersFromCallstack() would not hide folders until resetToDefault() called.
    %
    % Provide command line to unhide App Designer folders for Mathworks stuff internal usage
    % 1) show untrimmed call stack during debugging state
    % >> appdesigner.internal.debug.AppDebugUtilities.unhideInternalFoldersFromCallstack();
    % 2) set to default to show trimmed call stack during debugging state
    % after appdesigner.internal.debug.AppDebugUtilities.unhideInternalFoldersFromCallstack is called
    % >> appdesigner.internal.debug.AppDebugUtilities.resetToDefault();
    %
    % Also use matlab.lang.internal.getMaskedFoldersFromStack() to check all MATLAB hided folders

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant)
        % Hide the following App Designer related internal folders:
        % appdesigner.internal
        % appdesservices.internal
        % viewmodel.internal
        % matlab.ui.internal
        % matlab.ui.control.internal
        % matlab.ui.container.internal
        %
        % Please alwasy hide folder as part '+internal' to ensure only internal API are hided
        %
        % Todo: g2466154 refactor code to hide folders based on package instead folders
        % in order to eliminate multiple folders for one package e.g. appdesigner.internal
        PathToPrune = [
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'appdesigner', 'appdesigner', '+appdesigner', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'appdesigner', 'appdesigner', 'interface', '+appdesigner', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'appdesigner', 'appdesigner', 'runtime','+appdesigner', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'appdesigner', 'app_artifact_generator', '+appdesigner', '+internal', '+artifactgenerator'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'shared', 'appdes', 'services', '+appdesservices', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'uicomponents', 'uicontrol', '+matlab', '+ui', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'uicomponents', 'uicomponents', '+matlab', '+ui', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'uicomponents', 'uicomponents', '+matlab', '+ui', '+control', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'matlab', 'uicomponents', 'uicomponents', '+matlab', '+ui', '+container', '+internal'}, filesep)))...
            string(fullfile(matlabroot, strjoin({'toolbox', 'shared', 'viewmodel', 'viewmodel', '+viewmodel', '+internal'}, filesep)))...
            string(appdesigner.internal.cacheservice.TempdirFileWriter().getCacheRoot())];
            
    end

    methods(Static)
        function result = hideInternalFoldersFromCallstack()
            % API to hide AD internal Folders from call stacks

            import appdesigner.internal.debug.AppDebugUtilities;

            if ~AppDebugUtilities.hideEnabled && ~AppDebugUtilities.unhideOverride
                matlab.lang.internal.maskFoldersFromStack(AppDebugUtilities.PathToPrune);
                AppDebugUtilities.hideEnabled(true);
            end

            result = AppDebugUtilities.hideEnabled;
        end

        function result = unhideInternalFoldersFromCallstack()
            % API to hide AD internal Folders from call stacks and set global setting unhideOverride
            % to prevent folder are hided again
            import appdesigner.internal.debug.AppDebugUtilities;

            AppDebugUtilities.unhideOverride(true);

            if AppDebugUtilities.hideEnabled
                matlab.lang.internal.unmaskFoldersFromStack(AppDebugUtilities.PathToPrune);
                AppDebugUtilities.hideEnabled(false);
            end

            result = AppDebugUtilities.hideEnabled;
        end

        function result = resetToDefault()
            % API to reset back after unhideInternalFoldersFromCallstack() to hide AD folders by default
            % and reset global setting unhideOverride back to be default value (false)

            import appdesigner.internal.debug.AppDebugUtilities

            AppDebugUtilities.unhideOverride(false);

            AppDebugUtilities.hideInternalFoldersFromCallstack();

            result = AppDebugUtilities.hideEnabled;
        end

        function tf = unhideOverride(val)
            % unhide global flag for internal usage to prevent hiding AD folder by default
            % hideInternalFoldersFromCallstack is called multiple locations in order to unhide AD folders
            % need set global flag to override hiding folder behavior

            persistent value;

            if nargin
                value = val;
            elseif isempty(value)
                value = false;
            end

            tf = value;
        end

        function tf = hideEnabled(val)
            % hiding AD folders STATUS:
            % true - AD folders were hided
            % false - AD folders were unhided

            persistent value;

            if nargin
                value = val;
            elseif isempty(value)
                value = false;
            end

            tf = value;
        end
    end
end
