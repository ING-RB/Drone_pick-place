classdef ApplyToNonemptyString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Function (1,1) function_handle = @(text,idx,numNonempty)text;
    end
    
    methods
        function str = ApplyToNonemptyString(otherStrs, fcn)
            str = str@matlab.automation.internal.diagnostics.CompositeFormattableString(otherStrs);
            str.Function = fcn;
        end
        
        function text = get.Text(str)
            composed = str.ComposedText;
            nonempty = composed(strlength(composed) > 0);
            
            numNonempty = numel(nonempty);
            text = strings(1,numNonempty);
            for idx = 1:numNonempty
                text(idx) = str.Function(nonempty(idx), idx, numNonempty);
            end
        end
    end
end

% LocalWords:  Formattable Strs strlength
