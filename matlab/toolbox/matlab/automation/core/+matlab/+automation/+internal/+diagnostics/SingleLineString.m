classdef SingleLineString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess=private)
        Text string;
    end

    methods
        function singleLine = SingleLineString(str)
            arguments
                str (1,1) matlab.automation.internal.diagnostics.FormattableString;
            end
            singleLine = singleLine@matlab.automation.internal.diagnostics.CompositeFormattableString(str);
        end

        function txt = get.Text(str)
            import matlab.automation.internal.getOneLineSummary;
            
            txt = getOneLineSummary(str.ComposedText, Inf);
            txt = extractBetween(txt, 2, strlength(txt)-1); %remove quotes
        end
    end
end
