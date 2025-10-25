% HASSETTING   Determine whether setting exists in settings group
%  hasSetting(PARENTGROUP, NAME) returns 1 (true) if the specified settings 
%  group PARENTGROUP contains the setting NAME. Otherwise, HASSETTING 
%  returns 0. 
%
%  Examples:
%  Assume the settings tree contains these settings groups
%
%                            root
%                            /   \    
%                       matlab mytoolbox
%                                /    \
%                            FontSize  ...
%                                      
%
%  Determine whether 'mytoolbox' contains the setting 'FontSize'.
%
%    >> s = settings;
%    >> hasSetting(s.mytoolbox, 'FontSize')
%
%       ans =
%            1
%
%
%  See also matlab.settings.SettingsGroup, matlab.settings.SettingsGroup/addSetting, matlab.settings.SettingsGroup/removeSetting

%  Copyright 2015-2019 The MathWorks, Inc.
