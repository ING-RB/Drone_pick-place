function fileType = detectFileType(filename, fileType, knownFileTypes)
%

% Copyright 2020-2023 The MathWorks, Inc.

    arguments
        filename
        fileType
        knownFileTypes = ["xml" "json"];
    end

    % Only the "auto" FileType needs special handling.
    if fileType ~= "auto"
        return;
    end

    % Error if the FileType is "auto", but there is no file extension to use.
    [~, ~, fileExtension] = fileparts(filename);
    if isempty(fileExtension) || strlength(fileExtension) == 0
        error(generateUnrecognizedFileExtensionMessage(filename, knownFileTypes));
    end

    % A file extension is present. Use it to find the FileType.
    matchedFileTypeList = strcmpi("." + knownFileTypes, fileExtension);
    matchedFileTypeIndex = find(matchedFileTypeList);
    if ~isempty(matchedFileTypeIndex)
        % File extension case-insensitively matches a known FileType.
        fileType = knownFileTypes(matchedFileTypeIndex);
    else
        error(generateUnrecognizedFileExtensionMessage(filename, knownFileTypes));
    end
end

function msg = generateUnrecognizedFileExtensionMessage(filename, knownFileTypes)
    msgid = "MATLAB:io:xml:writestruct:FileTypeAutoUnrecognizedFileExtension";
    knownFileTypesList = """" + knownFileTypes + """";
    knownFileTypesList = join(knownFileTypesList, ", ");
    msg = message(msgid, filename, knownFileTypesList);
end
