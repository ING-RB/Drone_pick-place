function fileType = validateFileType(fileType, functionName)
%

% Copyright 2020-2023 The MathWorks, Inc.

    arguments
        fileType
        functionName = "writestruct";
    end

    % Verify scalar text input.
    classes = ["char" "string"];
    attributes = "scalartext";
    validateattributes(fileType, classes, attributes, functionName, "FileType");

    % Validate content of FileType string.
    if functionName == "writestruct"
        expected = ["auto", "xml", "json"];
    else
        % writedictionary
        expected = ["auto" "json"];
    end
    tf = matches(fileType, expected, IgnoreCase=true);
    if ~tf
        error(generateUnrecognizedFileTypeMessage(fileType, expected));
    end

    % Normalize to lowercase string scalar.
    fileType = string(lower(fileType));
end

function msg = generateUnrecognizedFileTypeMessage(fileType, knownFileTypes)
    msgid = "MATLAB:io:struct_:writestruct:UnrecognizedFileType";
    knownFileTypesList = """" + knownFileTypes + """";
    knownFileTypesList = join(knownFileTypesList, ", ");
    msg = message(msgid, fileType, knownFileTypesList);
end
