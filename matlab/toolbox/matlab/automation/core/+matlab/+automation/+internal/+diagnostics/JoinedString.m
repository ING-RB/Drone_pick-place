classdef JoinedString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Delimiter string;
    end
    
    properties
        KeepEmptyText (1,1) logical = true;
    end
    
    methods
        function joined = JoinedString(str, delim)
            joined = joined@matlab.automation.internal.diagnostics.CompositeFormattableString(str);
            joined.Delimiter = delim;
        end
        
        function txt = get.Text(str)
            composedText = str.ComposedText;
            
            if ~str.KeepEmptyText
                composedText = composedText(strlength(composedText) > 0);
            end
            
            txt = strjoin(composedText, str.Delimiter);
        end
    end
end

% LocalWords:  Formattable delim strlength strjoin
