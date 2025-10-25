classdef LogicalVarOptsInputs < matlab.io.internal.FunctionInterface

    properties (Parameter)
        %TRUESYMBOLS
        %   A cell array of character vectors containing text to match to the
        %   logical value true.
        %
        %   See also matlab.io.VariableImportOptions
        TrueSymbols = {'true','t','1'};

        %FALSESYMBOLS
        %   A cell array of character vectors containing text to match to the
        %   logical value false.
        %
        %   See also matlab.io.VariableImportOptions
        FalseSymbols = {'false','f','0'};

        %CASESENSITIVE
        %   A logical value indicating whether or not text will be matched as case
        %   sensitive values.
        %
        %   See also matlab.io.VariableImportOptions
        CaseSensitive = false;
    end

    methods
        function opts = set.TrueSymbols(opts,rhs)
            rhs = matlab.io.internal.validators.validateCellStringInput(rhs,'TrueSymbols');
            opts.TrueSymbols = matlab.io.internal.utility.validateAndEscapeCellStrings(rhs,'TrueSymbols');
        end

        function opts = set.FalseSymbols(opts,rhs)
            rhs = matlab.io.internal.validators.validateCellStringInput(rhs,'FalseSymbols');
            opts.FalseSymbols = matlab.io.internal.utility.validateAndEscapeCellStrings(rhs,'FalseSymbols');
        end

        function opts = set.CaseSensitive(opts,rhs)
            if ~isscalar(rhs) || (~isnumeric(rhs) && ~islogical(rhs))
                error(message('MATLAB:textio:textio:ExpectedScalarLogical'));
            end
            opts.CaseSensitive = logical(rhs);
        end
    end

    methods (Access = protected)
        function val = setType(obj,val)
        obj.validateFixedType(obj.Name,'logical',val);
        end

        function val = getType(~,~)
        val = 'logical';
        end

        function val = setFillValue(~,val)
        if ~(isnumeric(val) || islogical(val)) || ~isscalar(val)
            error(message('MATLAB:textio:io:FillValueType','logical'));
        end
        val = logical(val);
        end

        function val = getFillValue(~,val)
        if isempty(val)
            val = false;
        end
        end
    end
end

%   Copyright 2018-2024 The MathWorks, Inc.
