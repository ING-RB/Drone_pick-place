function preferences(varargin)
    %PREFERENCES Bring up MATLAB user settable settings dialog.
    %   PREFERENCES opens up general MATLAB settings.  
    % 
    %   PREFERENCES COMPONENT displays general MATLAB settings with the
    %   specified component name selected.
    %
    %   Examples:
    %      preferences
    %         displays MATLAB user settable settings dialog
    %
    %      preferences('Editor/Debugger')
    %         displays Editor user settable settings
    %
    
    %   Copyright 1984-2024 The MathWorks, Inc.
    narginchk(0,1);
    if nargin > 0
        % preferences('ComponentName')
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    if isWebUIModeOn()
        launchWebUIPreferences(varargin{:});
    else
        launchLegacyPreferences(varargin{:});
    end
end

function webUIMode = isWebUIModeOn()
    import matlab.internal.capability.Capability;
    webUIMode = feature('webui') || ~Capability.isSupported(Capability.LocalClient);
end

function launchWebUIPreferences(varargin)
    % WebUI Requirements
    import matlab.internal.capability.Capability;
    Capability.require(Capability.InteractiveCommandLine);
    Capability.require(Capability.WebWindow);
    Capability.require(Capability.Debugging)

    if ~desktop('-inuse') && Capability.isSupported(Capability.LocalClient)
        error(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
    end

    if nargin < 1
        preferencePanelName = '';
    else
        preferencePanelName = varargin{1};
    end

    message.publish('/JavaScript/Preferences/CommandLineChannel', preferencePanelName);
end

function launchLegacyPreferences(varargin)
    % if no swing, error
    import matlab.internal.capability.Capability;
    Capability.require(Capability.Swing);
    error(javachk('swing', mfilename));

    com.mathworks.mlservices.MLPrefsDialogServices.showPrefsDialog(varargin{:}); %#ok<*JAPIMATHWORKS>
end