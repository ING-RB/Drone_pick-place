function raspberryPiResourceMonitor(varargin)
% RASPBERRYPIRESOURCEMONITOR Opens the Raspberry Pi Resource Monitor App of the
% Raspberry Pi Support Package

%   Copyright 2020-2021 The MathWorks, Inc.

try
    fullpathToUtility = which('raspi.internal.getRaspiRoot');
    % Check if the support package is installed
    if isempty(fullpathToUtility)
        % Support package not installed
        msg = getString(message('MATLAB:hwstubs:general:spkgNotInstalledSimplified', 'MATLAB Raspberry Pi'));
        response = questdlg(msg,'Install MATLAB Support Package for Raspberry Pi','Install','Cancel','Install');
        if(strcmpi(response,'Install'))
            matlab.addons.supportpackage.internal.explorer.showSupportPackages('RASPPIIO', 'tripwire');
        end
    else
        % Launch the app if support package is installed
        raspi.resourcemonitor.raspberryPiResourceMonitor();
    end
catch e
    throwAsCaller(e);
end
