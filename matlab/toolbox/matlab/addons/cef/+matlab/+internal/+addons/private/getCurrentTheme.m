function themeValue = getCurrentTheme(~) 
% getCurrentTheme: Get current theme setting
    
    % Copyright: 2022 The MathWorks, Inc.
    themeValue = 'Light';
    
    settingsAPI = settings;
    themeSettings = settingsAPI.matlab.appearance;           
    if themeSettings.hasSetting('MATLABTheme')
        themeValue = themeSettings.MATLABTheme.ActiveValue;
    end
end