function addons = installedAddons

% installedAddons Return list of installed add-ons
%
%   ADDONS = matlab.addons.installedAddons returns a list of 
%   currently installed add-ons, specified as a table of strings 
%   with these fields:
% 
%           Name - Name of the add-on
%        Version - Version of the add-on
%        Enabled - Whether the add-on is enabled
%     Identifier - Unique identifier of the add-on
% 
%   Example:  Get list installed add-ons
% 
%   addons = matlab.addons.installedAddons
%
%   addons =
%
%   1x4 table
%
%                      Name                           Version    Enabled                   Identifier
%   _____________________________________________    _________   _______   ______________________________________
%
%   "Simulink"                                       "R2018b"     true                      "SL"
%
%   See also: matlab.addons.disableAddon,
%   matlab.addons.enableAddon,   
%   matlab.addons.isAddonEnabled

% Copyright 2017-2022 The MathWorks Inc.

% ToDo: Delete this if condition after installed Products and Support
% Packages register with Registration Framework
if ~feature('webui')
    addons = getInstalledAddOns();
    return;
end

addons = table(string.empty(0,1),string.empty(0,1),logical.empty(0,1),string.empty(0,1),...
        'VariableNames',{'Name','Version','Enabled','Identifier'}); 

addonsStruct = struct([]);

try
    installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;
    
    for addonIndex = 1:length(installedAddOns)
        addonsStruct(addonIndex).Name = string(installedAddOns(addonIndex).name);
        addonsStruct(addonIndex).Version = string(installedAddOns(addonIndex).version);
        addonsStruct(addonIndex).Enabled = logical(installedAddOns(addonIndex).enabled);
        addonsStruct(addonIndex).Identifier = string(installedAddOns(addonIndex).identifier);
    end
    
    if size(addonsStruct) > 0
        addons = struct2table(addonsStruct);
    end
    
catch ex
    error(ex.identifier, ex.message);
end

end