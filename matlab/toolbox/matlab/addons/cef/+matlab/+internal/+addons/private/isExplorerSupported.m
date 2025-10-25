function isSupported = isExplorerSupported()
% ISEXPLORERSUPPORTED Private function to determine if Add-On Explorer is supported 
% in the current instance of MATLAB.
% Can be configured to return the required value by setting the value of Setting
% matlab.addons.explorer.isExplorerSupported.ActiveValue
% Example: 
% s = settings; s.matlab.addons.explorer.addSetting("isExplorerSupported");
% s.matlab.addons.explorer.isExplorerSupported.PersonalValue = false
    
% Copyright: 2020-2023 The MathWorks, Inc.
s = settings;

if s.matlab.addons.explorer.hasSetting("isExplorerSupported") && hasActiveValue(s.matlab.addons.explorer.isExplorerSupported)
    isSupported = s.matlab.addons.explorer.isExplorerSupported.ActiveValue;   
else
    % Call API provided by MATLAB Online team
    isSupported = true;
end

end

