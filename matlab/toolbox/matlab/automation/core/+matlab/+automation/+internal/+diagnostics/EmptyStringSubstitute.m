classdef EmptyStringSubstitute < matlab.automation.internal.diagnostics.FormattableStringDecorator
    %
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Class string;
        Size string;
    end
    
    methods
        function str = EmptyStringSubstitute(otherString, valueClass, valueSize)
            str = str@matlab.automation.internal.diagnostics.FormattableStringDecorator(otherString);
            str.Class = valueClass;
            str.Size = valueSize;
        end
        
        function txt = get.Text(str)
            txt = str.ComposedText;
            
            if strlength(txt) == 0
                txt = string(getString(message('MATLAB:automation:DisplayDiagnostic:NoDisplayedOutput', ...
                    str.Class, str.Size)));
            end
        end
    end
end

% LocalWords:  Formattable strlength
