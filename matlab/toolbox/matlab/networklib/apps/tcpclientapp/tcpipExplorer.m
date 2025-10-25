function tcpipExplorer
% TCPIPEXPLORER Opens the TCP/IP Explorer app.

% Copyright 2021-2022 The MathWorks, Inc

% Check whether the application is called from a desktop platform
import matlab.internal.capability.Capability;
Capability.require(Capability.LocalClient);

pluginClass = "matlab.hwmgr.plugins.TcpclientPlugin";
appClass = "transportapp.tcpclient.internal.TcpclientApp";

% Launch TCP/IP Explorer app in Hardware Manager.
matlab.hwmgr.internal.launchApplet(appClass, pluginClass);
end