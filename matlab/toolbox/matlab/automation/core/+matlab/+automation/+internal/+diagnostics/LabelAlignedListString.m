classdef LabelAlignedListString < matlab.automation.internal.diagnostics.CompositeFormattableString
    % This class is undocumented and may change in a future release.
    
    %   Produces a list of values, with labels right-justified and values
    %   left-justified. E.g.,
    %            A 1
    %          ABC 123
    %       ABCDEF 12345
    %   Rows for which the values are empty text are omitted.
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties(Access=private)
        Labels (1,:) string;
    end
    
    methods
        function str = LabelAlignedListString()
            import matlab.automation.internal.diagnostics.FormattableString;
            str = str@matlab.automation.internal.diagnostics.CompositeFormattableString(...
                FormattableString.empty(1,0));
        end
        
        function str = addLabelAndString(str,labelText,otherStr)
            str.Labels(end+1) = string(labelText);
            str.ComposedString(end+1) = otherStr;
        end
        
        function txt = get.Text(str)
            import matlab.automation.internal.diagnostics.TextIndentedString;
            import matlab.internal.display.wrappedLength;
            
            % Retain only non-empty labelled values
            nonEmptyMask = strlength([string.empty(1,0), str.ComposedString.Text]) > 0;
            labels = str.Labels(nonEmptyMask);
            composedStrings = str.ComposedString(nonEmptyMask);
            
            lengths = arrayfun(@(x) round(wrappedLength(x)), labels);
            spacesNeeded = max(lengths) - lengths;
            list = composedStrings;
            for k=1:numel(list)
                list(k) = TextIndentedString(composedStrings(k), ...
                    repmat(' ',1,spacesNeeded(k)) + labels(k) + " ");
            end

            txt = strjoin([string.empty(1,0), list.Text], newline);
        end
    end
end

% LocalWords:  ABCDEF
