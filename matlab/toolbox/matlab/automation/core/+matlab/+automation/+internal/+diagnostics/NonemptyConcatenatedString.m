classdef NonemptyConcatenatedString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    methods
        function concatenated = NonemptyConcatenatedString(strs)
            concatenated = concatenated@matlab.automation.internal.diagnostics.CompositeFormattableString(strs);
        end
        
        function txt = get.Text(str)
            composed = str.ComposedText;
            
            if any(strlength(composed) == 0)
                txt = "";
                return;
            end
            
            txt = join(composed, "");
        end
    end
end

% LocalWords: Formattable strs strlength
