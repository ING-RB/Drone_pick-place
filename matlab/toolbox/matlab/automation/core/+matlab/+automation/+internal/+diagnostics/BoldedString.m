classdef BoldedString < matlab.automation.internal.diagnostics.LeafFormattableString
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=private)
        BoldableString (1,1) matlab.automation.internal.diagnostics.BoldableString = ...
            matlab.automation.internal.diagnostics.BoldableString("");
    end
    
    methods
        function str = BoldedString(boldableString)
            str.BoldableString = boldableString;
        end
        
        function txt = get.Text(str)
            txt = str.BoldableString.Text;
            txt = sprintf("<strong>%s</strong>", txt);
            
            % To handle the empty Text case and to handle the cases where
            % other FormattableStrings which implement applyBoldHandling
            % leave a leading "</strong>" or trailing "<strong>":
            txt = replace(txt,"<strong></strong>","");
        end
    end
end

% LocalWords:  Formattable  Boldable boldable
