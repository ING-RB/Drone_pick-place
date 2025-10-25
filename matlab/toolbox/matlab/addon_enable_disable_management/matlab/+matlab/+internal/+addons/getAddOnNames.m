function [addOnNames] = getAddOnNames()
% Tab-Completion function to get add-on names
% Get names of all the add-ons installed

% Copyright 2019 The MathWorks Inc.
allInstalledAddOns = matlab.addons.installedAddons;
addOnNames = allInstalledAddOns.Name;
end