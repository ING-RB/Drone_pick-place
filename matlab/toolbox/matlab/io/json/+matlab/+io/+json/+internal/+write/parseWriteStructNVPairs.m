function nvStruct = parseWriteStructNVPairs(sharedParser, varargin)
%

% Copyright 2020-2023 The MathWorks, Inc.

    persistent parser
    if isempty(parser)
        % Deep-copy the shared parser and append additional N-V args.
        parser = copy(sharedParser);
        parser.KeepUnmatched = false;

        opts = matlab.io.json.internal.write.defaultWriteStructOptions();
        parser.addParameter("PrettyPrint", opts.PrettyPrint);
        parser.addParameter("Indent", opts.PrettyPrint);
        parser.addParameter("IndentText", opts.IndentText);
        parser.addParameter("Encoding", opts.Encoding);
        parser.addParameter("PreserveInfAndNaN", opts.PreserveInfAndNaN);
    end

    parser.parse(varargin{:});
    nvStruct = parser.Results;

    nvStruct.PrettyPrint = validatePrettyPrint(nvStruct.PrettyPrint) && validatePrettyPrint(nvStruct.Indent);
    nvStruct.IndentText = validateIndentText(nvStruct.IndentText);
    nvStruct.Encoding = validateEncoding(nvStruct.Encoding);
    nvStruct.PreserveInfAndNaN = validatePreserveInfAndNaN(nvStruct.PreserveInfAndNaN);
end

function prettyPrint = validatePrettyPrint(prettyPrint)
    prettyPrint = matlab.internal.datatypes.validateLogical(prettyPrint, "PrettyPrint");
end

function indentText = validateIndentText(indentText)
    indentText = convertCharsToStrings(indentText);
    validateattributes(indentText, "string", "scalar", "writestruct", "IndentText");
end

function encoding = validateEncoding(encoding)
    encoding = convertCharsToStrings(encoding);
    validateattributes(encoding, "string", "scalar", "writestruct", "Encoding");
end

function preserveInfAndNaN = validatePreserveInfAndNaN(preserveInfAndNaN)
    preserveInfAndNaN = matlab.internal.datatypes.validateLogical(preserveInfAndNaN, "PreserveInfAndNaN");
end
