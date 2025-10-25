classdef MatlabOnlineDocPageHandler < matlab.internal.doc.ui.DocPageHandler
    methods (Access = protected)
        function success = openBrowserForDocPage(~, url)
            message.publish("/web/doc", string(url));
            success = true;            
        end
    end
end

% Copyright 2021 The MathWorks, Inc.