function arduinoExplorer(varargin)
    % Function to launch the Arduino Explorer app in the MATLAB Support Package
    % for Arduino Hardware.

    %   Copyright 2021-2024 The MathWorks, Inc.

    % Check if called from desktop platform, or the MATLAB Online platforms
    % which hardware is supported
    errorId = 'MATLAB:hwstubs:general:unsupportedPlatform';
    import matlab.internal.capability.Capability;
    assert(Capability.isSupported(Capability.LocalClient) ||...
        matlabshared.remoteconnectivity.internal.RemoteUtilities.isUsingRemoteHW, ...
        errorId, message(errorId).string);

    % Specify the appletClass and pluginClass for launching the
    % arduinoExplorer app
    appletClass = 'arduinoioapplet.ArduinoExplorerApplet';
    pluginClass = 'matlab.hwmgr.plugins.ArduinoPlugin';

    try
        % Check if the support package is installed.
        fullpathToUtility = which('listArduinoLibraries');
        if isempty(fullpathToUtility)
            % Support package not installed
            msg = getString(message('MATLAB:hwstubs:general:spkgNotInstalled', 'MATLAB Arduino', 'ML_ARDUINO'));
            % Extract only the first sentence about the SPKG requirement.
            msg = strsplit(msg,".");
            msg = strcat(msg{1},".");
            msg = "\fontsize{10} "+string(msg);
            opts = struct('WindowStyle','modal','Interpreter','tex','Default','Install');
            response = questdlg(msg,getString(message('MATLAB:hwstubs:general:dialogTitle','Arduino® Hardware')),getString(message('MATLAB:hwstubs:general:installString')),getString(message('MATLAB:hwstubs:general:cancelString')),opts);
            if(strcmpi(response,getString(message('MATLAB:hwstubs:general:installString'))))
                matlab.addons.supportpackage.internal.explorer.showSupportPackages('ML_ARDUINO', 'tripwire');
            end
        else
            % Launch the arduinoExplorer app
            matlab.hwmgr.internal.launchApplet(appletClass, pluginClass);
        end
    catch e
        throwAsCaller(e);
    end
