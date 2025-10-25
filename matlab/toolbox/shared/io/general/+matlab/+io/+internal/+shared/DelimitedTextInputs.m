classdef DelimitedTextInputs < matlab.io.internal.FunctionInterface
%

% Copyright 2018 The MathWorks, Inc.
    properties (Parameter)

        %CONSECUTIVEDELIMITERSRULE what to do with consecutive delimiters
        % that appear in the file.
        %
        %   Possible values:
        %         split: Splits the consecutive delimiters into multiple
        %                fields.
        %
        %          join: Join the delimiters into one delimiter.
        %
        %         error: Error during import and abort the operation.
        ConsecutiveDelimitersRule = 'split';

        %LEADINGDELIMITERSRULE what to do with delimiters at the beginning
        % of a line.
        %
        %   Possible values:
        %          keep: Keep the delimiter.
        %
        %        ignore: Ignore the delimiter.
        %
        %         error: Error during import and abort the operation.
        LeadingDelimitersRule = 'keep';

        %TRAILINGDELIMITERSRULE what to do with delimiters at the end of a
        % line.
        %
        %   Possible values:
        %          keep: Keep the delimiter.
        %
        %        ignore: Ignore the delimiter.
        %
        %         error: Error during import and abort the operator.
        TrailingDelimitersRule = 'keep';
    end

    properties (Parameter, Dependent)
        %DELIMITER used to parse text into fields.
        % Delimiter can be a character vector or cell array of character
        % vectors (e.g. ',', {' ','\t'}
        Delimiter
    end

    properties (Access = private)
        % This contains interpreted characters, not the escape sequences
        delim_ = {','};
    end

    methods
        function func = set.Delimiter(func,delimiter)
            delimiter = convertStringsToChars(delimiter);
            delimiter = matlab.io.internal.utility.validateAndEscapeCellStrings(delimiter,'Delimiter');
            func.delim_ = unique(delimiter);
        end

        function delimiter = get.Delimiter(func)
        % char array might be row or column, don't bother trying to
        % keep the state fixed as a column, but reorient it on return.
        % This will always produce a row.
            delimiter = matlab.io.internal.utility.unescape(func.delim_(:)');
        end

        function opts = set.ConsecutiveDelimitersRule(opts,rhs)
            opts.ConsecutiveDelimitersRule = validatestring(rhs,{'split','join','error'});
        end

        function opts = set.LeadingDelimitersRule(opts,rhs)
            opts.LeadingDelimitersRule = validatestring(rhs,{'keep','ignore','error'});
        end

        function opts = set.TrailingDelimitersRule(opts,rhs)
            opts.TrailingDelimitersRule = validatestring(rhs,{'keep','ignore','error'});
        end
    end

    methods(Access = {?matlab.io.internal.shared.DelimitedTextInputs,...
            ?matlab.io.internal.functions.DetectImportOptionsText})
        function delim = getUnescapedDelimiter(opts)
            delim = opts.delim_;
        end

        function opts = setUnescapedDelimiter(opts, delim)
            opts.delim_ = delim;
        end
    end
end
