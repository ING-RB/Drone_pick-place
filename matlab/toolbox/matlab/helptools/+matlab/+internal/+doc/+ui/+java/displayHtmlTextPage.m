function displayHtmlTextPage(text)
    % Use the appropriate viewer for html text.   
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForHtmlText(text);
    launcher.openDocPage();
end

% Copyright 2021 The MathWorks, Inc.