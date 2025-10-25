classdef ContentType
    enumeration
        % A full doc center page with all navigation elements displayed
        DocCenter
        % Content displayed in a standalone browser, without navigation elements
        Standalone
        % Help content formatted for display in a browser
        MatlabFileHelp
    end
    
    methods
        function standalone = isStandalone(obj)
            standalone = obj == matlab.internal.doc.url.ContentType.Standalone;
        end
        function matlabFileHelp = isMatlabFileHelp(obj)
            matlabFileHelp = obj == matlab.internal.doc.url.ContentType.MatlabFileHelp;
        end
    end
end