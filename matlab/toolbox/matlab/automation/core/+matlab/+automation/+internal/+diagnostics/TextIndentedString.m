classdef TextIndentedString < matlab.automation.internal.diagnostics.FormattableStringDecorator
    % This class is undocumented and may change in a future release.
    
    % This class is different than IndentedString in that the indention
    % text is applied only to the first line, and all other lines are
    % padded with spaces. For example given the text
    %     "ABC
    %      DE
    %      FGHI"
    % if the chosen indention text is "--> ", then the result is
    %     "--> ABC
    %          DE
    %          FGHI"
    % or if the chosen intention text is "My Text: ", then the result is
    %    "My Text: ABC
    %              DE
    %              FGHI"
    % which makes TextIndentedString great for creating bullets or labels.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        FirstLineIndentionText (1,1) string;
    end
    
    methods
        function str = TextIndentedString(innerStr,firstLineIndentionText)
            import matlab.internal.display.wrappedLength;
            
            str = str@matlab.automation.internal.diagnostics.FormattableStringDecorator(innerStr);
            str.FirstLineIndentionText = firstLineIndentionText;
            str = str.applyIndention(wrappedLength(firstLineIndentionText));
        end
        
        function txt = get.Text(str)
            spaces = string(repmat(' ',1,strlength(str.FirstLineIndentionText)));
            lines = splitlines(str.ComposedText).';
            txt = join([str.FirstLineIndentionText + lines(1), spaces + lines(2:end)], newline);
        end
    end
end

% LocalWords:  Formattable splitlines FGHI strlength
