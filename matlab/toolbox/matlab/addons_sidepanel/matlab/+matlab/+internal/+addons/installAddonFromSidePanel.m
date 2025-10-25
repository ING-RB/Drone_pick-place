function  installAddonFromSidePanel( ...
    name, version, identifier, addonType, url)
%INSTALLADDONFROMSIDEPANEL Install add-on
%   Temporary function used to install add-on via legacy Java installer.
    matlab.internal.addons.startCommunicator;
    com.mathworks.addons.sidepanel.CommunicatorInstaller.install(name, ...
        version, identifier, addonType, url);
end