function updateAddonFromSidePanel( ...
    name, version, identifier, addonType, updateType, url)
%UPDATEADDONFROMSIDEPANEL Update add-on
%   Temporary function used to update add-on via legacy Java installer.
    matlab.internal.addons.startCommunicator;
    com.mathworks.addons.sidepanel.CommunicatorInstaller.update(name, ...
        version, identifier, addonType, updateType, url);
end