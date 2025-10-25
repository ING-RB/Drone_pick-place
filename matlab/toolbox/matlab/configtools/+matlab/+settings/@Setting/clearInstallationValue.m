% CLEARINSTALLATIONVALUE    Clear the installation value for a setting 
%
% CLEARINSTALLATIONVALUE(S) clears the installation value for the specified setting. 
% If the installation value is not set or not writeable, CLEARINSTALLATIONVALUE
% returns an error.
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
%    >> S = settings;
%
%    Then, clear the installation value for the FontSize setting
%    >> clearInstallationValue(S.mytoolbox.FontSize);
%
%   See also settings, clearTemporaryValue, clearPersonalValue, hasInstallationValue

%   Copyright 2021 The MathWorks, Inc.
