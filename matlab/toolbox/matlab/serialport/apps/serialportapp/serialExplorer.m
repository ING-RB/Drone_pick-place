function serialExplorer
% SERIALEXPLORER Opens the Serial Explorer app.

% Copyright 2021-2022 The MathWorks, Inc

% Check whether the application is called from a desktop platform
import matlab.internal.capability.Capability;
Capability.require(Capability.LocalClient);

pluginClass = "matlab.hwmgr.plugins.SerialportPlugin";
appClass = "transportapp.serialport.internal.SerialportApp";

% Launch Serial Explorer in Hardware Manager.
matlab.hwmgr.internal.launchApplet(appClass, pluginClass);
end

