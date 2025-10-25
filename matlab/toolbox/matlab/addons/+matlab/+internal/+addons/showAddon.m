function showAddon(baseCode, funcName)
%   SHOWADDON Show add-on with given BASECODE in Add-on Explorer. It
%   optionally scrolls to a function in the detail page if FUNCNAME is
%   provided

%  Copyright 2014-2020 The MathWorks, Inc.             
    idForUsageDataAnalytics = 'tripwire';  % required for Omniture tracking(g1476851)
    if nargin == 2
        matlab.internal.addons.launchers.showExplorer(idForUsageDataAnalytics, "identifier", baseCode, "focused", funcName);
    elseif nargin == 1
        matlab.internal.addons.launchers.showExplorer(idForUsageDataAnalytics, "identifier", baseCode)
    end
end
