classdef ReplacedString < matlab.automation.internal.diagnostics.FormattableStringDecorator
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Pattern string;
        Replacement string;
    end
    
    methods
        function replaced = ReplacedString(str, pattern, replacement)
            replaced = replaced@matlab.automation.internal.diagnostics.FormattableStringDecorator(str);
            replaced.Pattern = pattern;
            replaced.Replacement = replacement;
        end
        
        function txt = get.Text(str)
            txt = regexprep(str.ComposedText, str.Pattern, str.Replacement);
        end
    end
end

% LocalWords:  Formattable
