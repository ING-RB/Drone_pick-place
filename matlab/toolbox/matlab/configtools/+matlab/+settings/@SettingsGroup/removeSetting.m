function removeSetting(obj, varargin)
% removeSetting    Remove setting
%
%  removeSetting(PARENTGROUP,NAME) removes the setting specified by NAME from the settings group PARENTGROUP.
%
%  removeSetting returns an error if the user settings file is read-only, or if the specified setting
%  does not exist.
%
%  Examples:
%  Assume the settings tree contains these settings groups and settings:
%
%                             root
%                             /  \     
%                        matlab  mysettings
%                       ......        \
%                                  mainwindow 
%                                          \ 
%                                        BgColor
%                                               
%
%  Remove the setting 'BgColor' from the settings group 'mainwindow' 
%
%      >> s = settings;
%      >> removeSetting(s.mysettings.mainwindow, 'BgColor');
% 
%
%   See also matlab.settings.SettingsGroup, matlab.settings.SettingsGroup/addSetting

%   Copyright 2015-2019 The MathWorks, Inc.

    results = matlab.settings.internal.parseSettingPropertyValues(varargin);
    % parseSettingPropertyValues function parses and validates user-input for optional property-value pairs with inputParser.
    obj.removeSettingHelper(results.Name);
end
