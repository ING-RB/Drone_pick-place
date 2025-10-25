function openManagerForAddon(addonUIDandVersion, addonNameAndVersion)
%% Expects the following formats
%  addonUIDandVersion: '<uid>,<version>'
%  addonNameAndVersion: '<name> version <version>'

% Copyright 2018-2021 The MathWorks Inc.
    connectingWordForNameAndVersion = [' ' getString(message('matlab_addons:enableDisableManagement:connectionForDisabledAddonRegistrationLinkText')) ' '];
    uidAndVersionList = split(addonUIDandVersion, ',');
    nameAndVersionList = split(addonNameAndVersion, connectingWordForNameAndVersion);
    matlab.internal.addons.launchers.showManager("disabledaddon", "identifier", uidAndVersionList{1}, "version", uidAndVersionList{2}, "name", nameAndVersionList{1}, "showDialog", "confirmEnable")
end
