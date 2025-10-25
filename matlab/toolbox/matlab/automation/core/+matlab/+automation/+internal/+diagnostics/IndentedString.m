classdef IndentedString < matlab.automation.internal.diagnostics.FormattableStringDecorator
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Indention string = "    ";
    end
    
    properties
        IndentEmptyText (1,1) logical = true;
    end
    
    methods
        function indented = IndentedString(str, indention)
            import matlab.internal.display.wrappedLength;
            
            indented = indented@matlab.automation.internal.diagnostics.FormattableStringDecorator(str);
            if nargin > 1
                indented.Indention = indention;
            end
            
            indented = indented.applyIndention(wrappedLength(indented.Indention));
        end
        
        function txt = get.Text(str)
            txt = str.ComposedText;
            
            if ~str.IndentEmptyText && strlength(txt) == 0
                return;
            end
            
            txt = join(str.Indention + splitlines(txt), newline);
            
        end
    end
end

% LocalWords:  Formattable splitlines strlength
