function out = openmlappinstall(filename)
%OPENMLAPPINSTALL   Install MATLAB App.  Helper function
%   for OPEN.
%
%   See OPEN.

%   Copyright 2012-2024 The MathWorks, Inc.

    import matlab.internal.capability.Capability
    validateattributes(filename, {'char','string'}, {'nonempty'})
    isCPPMLAPPINSTALL = getenv('MW_CPP_MLAPPINSTALL') == '1';
    if nargout, out = []; end
    if matlab.internal.feature('webui') & isCPPMLAPPINSTALL
        connector.ensureServiceOn;
        messageContent = struct('artifactType', 'COMMUNITY_ADDONS', ...
            'workflowType', 'COMMUNITY_ADDONS_INSTALL', ...
            'entryPoint', 'openmlappinstall', ...
            'metaDataUrl', '', ...
            'message', 'Request to install the ML App', ...
            'matlabroot', 'Request to install the ML App', ...
            'version', '', ...
            'destination', '', ...
            'mlappinstallfile', filename);
        message.publish('/addons/start', messageContent);
    else
        installResult = com.mathworks.appmanagement.actions.AppInstaller.install(java.io.File(filename));
        if installResult.getSucceeded()
            msgbox(string(message("mpm:install:InstallationCompleteInfo")));
        else
            errordlg(installResult.getResultMessage());
        end
    end
end
