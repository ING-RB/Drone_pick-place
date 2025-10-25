classdef ApplyToFirstNonemptyString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Function (1,1) function_handle = @(text)text;
        Default (1,1) string;
    end
    
    methods
        function str = ApplyToFirstNonemptyString(otherStrs, fcn, default)
            str = str@matlab.automation.internal.diagnostics.CompositeFormattableString(otherStrs);
            str.Function = fcn;
            str.Default = default;
        end
        
        function text = get.Text(str)
            for composed = str.ComposedString
                thisText = composed.Text;
                if strlength(thisText) > 0
                    text = str.Function(thisText);
                    return;
                end
            end
            
            text = str.Default;
        end
    end
end

% LocalWords:  Formattable Strs strlength
