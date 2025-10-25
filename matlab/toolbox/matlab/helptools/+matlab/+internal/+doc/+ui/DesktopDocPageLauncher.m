classdef DesktopDocPageLauncher < matlab.internal.doc.ui.DocPageLauncher
    methods    
        function obj = DesktopDocPageLauncher(docPage)
            obj = obj@matlab.internal.doc.ui.DocPageLauncher(docPage);
        end

        function handler = getHandlerForDocPage(obj)
            if isdeployed
                handler = matlab.internal.doc.ui.SystemBrowserDocPageHandler;
            elseif obj.DocPage.ContentType.isStandalone || obj.DocPage.ContentType.isMatlabFileHelp
                handler = matlab.internal.doc.ui.CshDocPageHandler;
            elseif matlab.internal.doc.ui.useSystemBrowser
                % If we're using the system browser for doc create a
                % SystemBrowserDocPageHandler. It passes through
                % to matlab.internal.web.SystemBrowserLauncher which 
                % handles all the system browser variants.
                handler = matlab.internal.doc.ui.SystemBrowserDocPageHandler;
            else
                handler = matlab.internal.doc.ui.HelpBrowserDocPageHandler;
            end
        end

        function handler = getHandlerForHtmlText(~)
            handler = matlab.internal.doc.ui.HelpBrowserDocPageHandler;
        end
    end
end

% Copyright 2021 The MathWorks, Inc.