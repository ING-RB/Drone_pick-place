classdef (Abstract, HandleCompatible) DocPageHandler  
    methods (Sealed, Access = {?matlab.internal.doc.ui.DocPageLauncher, ?matlab.internal.doc.ui.DocPageHandler})
        function success = openBrowser(obj, url)
            success = openBrowserForDocPage(obj, url);
        end
    end                
    
    methods (Abstract, Access = protected)
        success = openBrowserForDocPage(obj, url)
    end        

    methods (Access = {?matlab.internal.doc.ui.DocPageLauncher, ?matlab.internal.doc.ui.DocPageHandler})
        function success = showHtmlText(obj, text) 
            % default implementation is a no-op
            success = true;
        end
    end
end