% HASACTIVEVALUE    Determine whether the setting has an active value set
%
%    HASACTIVEVALUE(S) returns 1 (true) if S has an active value set.  
%    Otherwise, HASACTIVEVALUE returns 0 (false).
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
%    Then, check whether the FontSize setting has an active value
%    >> hasActiveValue(S.mytoolbox.FontSize)
%
%       ans =
%            1
%
%   See also settings
 
%   Copyright 2023 The MathWorks, Inc.
