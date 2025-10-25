classdef MatlabMobileDocPageLauncher < matlab.internal.doc.ui.DocPageLauncher
    methods    
        function obj = MatlabMobileDocPageLauncher(docPage)
            obj = obj@matlab.internal.doc.ui.DocPageLauncher(docPage);
        end

        function handler = getHandlerForDocPage(obj)
            if obj.DocPage.ContentType.isMatlabFileHelp
                % WebWindow isn't supported. Fallback to the help 
                % command for helpwin content.
                handler = matlab.internal.doc.ui.HelpCommandDocPageHandler;
                handler.Topic = obj.DocPage.Topic;                                
            else
                % WebWindow isn't supported. Create a 
                % SystemBrowserDocPageHandler. It passes through
                % to matlab.internal.web.SystemBrowserLauncher which 
                % handles all the system browser variants.
                handler = matlab.internal.doc.ui.SystemBrowserDocPageHandler;
            end
        end

        function handler = getHandlerForHtmlText(~)
            handler = matlab.internal.doc.ui.MatlabOnlineDocPageHandler;
        end
    end
end

% Copyright 2021-2022 The MathWorks, Inc.
