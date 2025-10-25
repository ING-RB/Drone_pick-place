classdef FormattableString < matlab.mixin.Heterogeneous
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Abstract, SetAccess=private)
        Text string;
    end
    
    methods (Abstract)
        str = enrich(str);
        str = wrap(str, width);
    end
    
    methods (Abstract, Access=protected)
        str = applyIndention(str, indentionAmount);
        str = applyBoldHandling(str);
    end

    methods (Sealed)
        function txt = string(str)
            % Convert to a plain string, applying rich formatting if appropriate.

            import matlab.automation.internal.richFormattingSupported;

            if richFormattingSupported
                str = enrich(str);
            end

            txt = str.Text;
        end

        function txt = char(str)
            % Convert to a character vector, applying rich formatting if appropriate.

            txt = char(string(str));
        end

        function c = cellstr(str)
            c = arrayfun(@char, str, 'UniformOutput',false);
        end
        
        function formatted = sprintf(format, varargin)
            import matlab.automation.internal.diagnostics.FormattedString;
            formatted = FormattedString(format, varargin{:});
        end
        
        function replaced = regexprep(str, pattern, replacement)
            import matlab.automation.internal.diagnostics.ReplacedString;
            replaced = ReplacedString(str, pattern, replacement);
        end
        
        function joined = join(str, varargin)
            import matlab.automation.internal.diagnostics.JoinedString;
            joined = JoinedString(str, varargin{:});
        end
        
        function joined = joinNonempty(str, varargin)
            % Join zero or more strings, omitting strings with empty text.
            
            import matlab.automation.internal.diagnostics.JoinedString;
            joined = JoinedString(str, varargin{:});
            joined.KeepEmptyText = false;
        end
        
        function indented = indent(str, varargin)
            import matlab.automation.internal.diagnostics.IndentedString;
            indented = IndentedString(str, varargin{:});
        end
        
        function indented = indentWithArrow(str)
            import matlab.automation.internal.diagnostics.TextIndentedString;
            indented = TextIndentedString(str,"--> ");
        end
        
        function indented = indentIfNonempty(str, varargin)
            % Indent one or more strings, omitting strings with empty text.
            
            import matlab.automation.internal.diagnostics.IndentedString;
            indented = IndentedString(str, varargin{:});
            indented.IndentEmptyText = false;
        end
        
        function withNewline = appendNewlineIfNonempty(str)
            % Add a newline to the end of nonempty text, or do nothing for
            % strings with empty text.
            
            import matlab.automation.internal.diagnostics.NonemptyConcatenatedString;
            withNewline = NonemptyConcatenatedString([str, newline]);
        end
        
        function withNewline = prependNewlineIfNonempty(str)
            % Add a newline to the beginning of nonempty text, or do
            % nothing for strings with empty text.
            
            import matlab.automation.internal.diagnostics.NonemptyConcatenatedString;
            withNewline = NonemptyConcatenatedString([newline, str]);
        end
        
        function applied = applyToFirstNonempty(strs, fcn, default)
            % Apply the supplied function handle to the text of the first
            % nonempty string. If all strings are empty, return the
            % supplied default string.
            
            import matlab.automation.internal.diagnostics.ApplyToFirstNonemptyString;
            applied = ApplyToFirstNonemptyString(strs, fcn, default);
        end
        
        function applied = applyToNonempty(strs, fcn)
            % Apply the supplied function to all strings with nonempty
            % text. The function is invoked with the nonempty text, the
            % index into the array of nonempty strings, and the total
            % number of nonempty strings.
            
            import matlab.automation.internal.diagnostics.ApplyToNonemptyString;
            applied = ApplyToNonemptyString(strs, fcn);
        end
        
        function concatenated = concatenateIfNonempty(str1, str2)
            % Concatenate two strings with nonempty text. If either has
            % empty text, the result is empty text.
            
            import matlab.automation.internal.diagnostics.FormattableString;
            import matlab.automation.internal.diagnostics.NonemptyConcatenatedString;
            
            concatenated = NonemptyConcatenatedString(FormattableString.fromMixedTypes(str1, str2));
        end
        
        function concatenated = plus(str1, str2)
            import matlab.automation.internal.diagnostics.JoinedString;
            concatenated = JoinedString([str1, str2], "");
        end
        
        function singleLine = toSingleLine(str)
            import matlab.automation.internal.diagnostics.SingleLineString;
            singleLine = SingleLineString(str);
        end
    end
    
    methods (Static, Sealed)
        function str = fromCellstr(cellstr)
            import matlab.automation.internal.diagnostics.PlainString;
            
            str = cellfun(@(c){PlainString(c)}, cellstr);
            str = [cell.empty, str];
            str = [PlainString.empty, str{:}];
        end
    end
    
    methods (Static, Sealed, Access=protected)
        function str = getDefaultScalarElement
            import matlab.automation.internal.diagnostics.PlainString;
            str = PlainString;
        end
        
        function converted = convertObject(~, toConvert)
            import matlab.automation.internal.diagnostics.PlainString;
            
            if ischar(toConvert) || (isscalar(toConvert) && isstring(toConvert))
                converted = PlainString(toConvert);
            end
        end
        
        function str = fromMixedTypes(varargin)
            % Convert chars/strings/FormattableStrings to a FormattableString array.
            
            import matlab.automation.internal.diagnostics.FormattableString;
            
            % Replace chars with strings so that they don't get lost in the horzcat operation.
            charMask = cellfun(@ischar, varargin);
            varargin(charMask) = num2cell(string(varargin(charMask)));
            str = [FormattableString.empty(1,0), varargin{:}];
        end
    end
end

% LocalWords:  isstring strs Formattable
