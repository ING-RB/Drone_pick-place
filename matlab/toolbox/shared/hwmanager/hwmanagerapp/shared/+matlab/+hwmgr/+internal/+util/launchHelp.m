function launchHelp(helpLink)
% launchHelp - Utility function to view help using a DocLinkData or LinkData structs.

% This function attempts to open the specified help link using MATLAB's
% helpview for DocLinkData objects. If that fails, or if the input is not
% a DocLinkData object, it opens the URL in the system's default web browser.

% Copyright 2024 The MathWorks, Inc.
if isa(helpLink,'matlab.hwmgr.internal.data.DocLinkData')
    try
        % Try to open with helpview first
        helpview(helpLink.ShortName, helpLink.TopicId);
    catch ME
        % helpview failed to open the doc
        % Open URL in browser directly
        web(helpLink.Url, '-browser');
    end
else
    web(helpLink.Url, '-browser');
end
end