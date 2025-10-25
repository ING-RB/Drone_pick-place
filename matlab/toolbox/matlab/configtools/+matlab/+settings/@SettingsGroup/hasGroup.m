% HASGROUP    Determine whether settings group exists
%  hasGroup(PARENTGROUP, NAME) returns 1 (true) if the specified settings
%  group PARENTGROUP contains the settings group NAME. Otherwise, HASGROUP
%  returns 0.
%
%  Examples:
%
%  Assume the settings tree contains these settings groups
%
%                             root
%                            /    \    
%                       matlab    mytoolbox
%                                  /     \
%                           mainwindow    ...
%                             /    \
%                      FontSize    ...
%
%  Determine whether 'mytoolbox' contains the settings group 'mainwindow'.
%
%    >> s = settings;
%    >> hasGroup(s.mytoolbox, 'mainwindow')
%
%       ans =
%            1
%
%
%  See also matlab.settings.SettingsGroup, matlab.settings.SettingsGroup/addGroup, matlab.settings.SettingsGroup/removeGroup

%  Copyright 2015-2019 The MathWorks, Inc.
