classdef CommandHyperlinkedString < matlab.automation.internal.diagnostics.LeafFormattableString
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        HyperlinkableString;
    end
    
    methods
        function str = CommandHyperlinkedString(hyperlinkableString)
            arguments
                hyperlinkableString (1,1) matlab.automation.internal.diagnostics.CommandHyperlinkableString;
            end
            
            str.HyperlinkableString = hyperlinkableString;
        end
        
        function txt = get.Text(str)
            if str.HyperlinkableString.BoldHandlingRequired
                templateTxt = "</strong><a href=""matlab:%s"" style=""font-weight:bold"">%s</a><strong>";
            else
                templateTxt = "<a href=""matlab:%s"">%s</a>";
            end
            txt = sprintf(templateTxt, ...
                str.HyperlinkableString.CommandToExecute, ...
                str.HyperlinkableString.LinkText);
        end
    end
end

% LocalWords:  Formattable Hyperlinkable hyperlinkable strlength
