function cdAndShowAddon( addonIdentifier, showNotes )
%CDANDSHOWADDON cd to last working folder and show Add-On detail page in Add-On
% Explorer

%   Copyright 2015-2023 The MathWorks, Inc.

matlab.internal.addons.showAddon(addonIdentifier);
s = settings;
lwf = s.matlab.addons.LastFolderPath.ActiveValue;
if (exist(lwf,'dir') == 7)
    cd(lwf);
end
if (strcmp(showNotes, 'true'))
    connector.ensureServiceOn();
    pageUrl = [connector.getUrl('/ui/install/addons_ui/indexForNotesPanel.html')];
    debugPort = matlab.internal.getOpenPort;
    instWin = matlab.internal.webwindow(pageUrl,debugPort,[600 100 500 300]);
    instWin.Title = 'Setup Notes';
    instWin.show();
end
end
