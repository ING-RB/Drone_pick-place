classdef MatlabOnlineDocPageLauncher < matlab.internal.doc.ui.DocPageLauncher
    methods    
        function obj = MatlabOnlineDocPageLauncher(docPage)
            obj = obj@matlab.internal.doc.ui.DocPageLauncher(docPage);
        end

        function handler = getHandlerForDocPage(obj)
            if obj.DocPage.ContentType.isStandalone || obj.DocPage.ContentType.isMatlabFileHelp
                handler = matlab.internal.doc.ui.CshDocPageHandler;
            elseif matlab.internal.doc.ui.useSystemBrowser
                % If we're using the system browser for doc create a
                % SystemBrowserDocPageHandler. It passes through
                % to matlab.internal.web.SystemBrowserLauncher which 
                % handles all the system browser variants.
                handler = matlab.internal.doc.ui.SystemBrowserDocPageHandler;
            else
                % Create a MatlabOnlineDocPageHandler for now. It publishes
                % to the doc router_endpoint.
                handler = matlab.internal.doc.ui.MatlabOnlineDocPageHandler;
            end
        end

        function handler = getHandlerForHtmlText(~)
            handler = matlab.internal.doc.ui.MatlabOnlineDocPageHandler;
        end
    end
end

% Copyright 2021 The MathWorks, Inc.