classdef SystemBrowserDocPageHandler < matlab.internal.doc.ui.DocPageHandler
    methods (Access = protected)
        function success = openBrowserForDocPage(~, url)
            % Pass-through to SystemBrowserLauncher.
            launcher = matlab.internal.web.SystemBrowserLauncher;
            success = openSystemBrowser(launcher, string(url));
        end
    end        
end

% Copyright 2021 The MathWorks, Inc.