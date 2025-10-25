% HASINSTALLATIONVALUE    Determine whether the setting has a installation value set
%
%    HASINSTALLATIONVALUE(S) returns 1 (true) if S has a installation value set.  
%    Otherwise, HASINSTALLATIONVALUE returns 0 (false).
%
%  Example
%    Assume the settings tree contains these SettingsGroup and Setting objects:
%
%                             root
%                             /  \     
%                       matlab   mytoolbox
%                       /         /    \
%                    ...    FontSize  MainWindow   
%
%    Use the settings function to access the root SettingsGroup object.
%    >> s = settings;
%
%    Then, check whether the FontSize setting has a installation value
%    >> hasInstallationValue(s.mytoolbox.FontSize)
%
%       ans =
%            0
%
%   See also settings
 
%   Copyright 2021 The MathWorks, Inc.

