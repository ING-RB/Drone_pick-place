function nvStruct = parseWriteStructNVPairs(sharedParser, varargin)
%

% Copyright 2020-2023 The MathWorks, Inc.

    import matlab.io.xml.internal.write.*;

    persistent parser
    if isempty(parser)
        % Deep-copy the shared parser and append additional N-V args.
        parser = copy(sharedParser);
        parser.KeepUnmatched = false;

        opts = matlab.io.xml.internal.write.builtin.defaultWriteStructOptions();
        parser.addParameter("StructNodeName", opts.StructNodeName);
        parser.addParameter("AttributeSuffix", opts.AttributeSuffix);
        parser.addParameter("PrettyPrint", opts.PrettyPrint);
        parser.addParameter("Indent", opts.PrettyPrint);
        parser.addParameter("IndentText", opts.IndentText);
        parser.addParameter("Encoding", opts.Encoding);
    end

    parser.parse(varargin{:});
    nvStruct = parser.Results;

    % Avoid repeated warnings for invalid node names.
    warningCleanup = suppressMultipleWarnings(); %#ok<NASGU>

    nvStruct.StructNodeName = validateNodeName(nvStruct.StructNodeName, "StructNodeName");
    nvStruct.AttributeSuffix = validateAttributeSuffix(nvStruct.AttributeSuffix);
    nvStruct.PrettyPrint = validatePrettyPrint(nvStruct.Indent) && validatePrettyPrint(nvStruct.PrettyPrint);
    nvStruct.IndentText = validateIndentText(nvStruct.IndentText);
    nvStruct.Encoding = validateEncoding(nvStruct.Encoding);
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
