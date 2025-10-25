function baseUrl = get()
% GETBASEURL Returns base URL to be used for Add-on Explorer

% Copyright 2020 The MathWorks, Inc.

s = settings;
if s.matlab.addons.hasGroup("explorer") && s.matlab.addons.explorer.hasSetting("preferredEndPoint")
    baseUrl = s.matlab.addons.explorer.preferredEndPoint.PersonalValue;
else
    baseUrl = getWSEndPointForAddOnExplorer();
end

end

