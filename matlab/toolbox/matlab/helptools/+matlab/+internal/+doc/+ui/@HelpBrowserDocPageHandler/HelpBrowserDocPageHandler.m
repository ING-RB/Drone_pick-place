classdef HelpBrowserDocPageHandler < matlab.internal.doc.ui.DocPageHandler
    methods (Access = protected)
        function success = openBrowserForDocPage(~, url)
            com.mathworks.mlservices.MLHelpServices.displayDocPage(string(url));
            success = true;
        end
    end

    methods (Access = {?matlab.internal.doc.ui.DocPageLauncher, ?matlab.internal.doc.ui.DocPageHandler})
        function success = showHtmlText(~, text) 
            com.mathworks.mlservices.MLHelpServices.displayHtmlText(string(text));
            success = true;
        end
    end
end

% Copyright 2021 The MathWorks, Inc.
