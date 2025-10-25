function nameIsValid = isValidMatlabFileName(filename, validExtension)
%isValidMatlabFileName check if the filename is valid
%   nameIsValid = isValidMatlabFileName(filename, validExtension) returns
%   whether the file name is valid and it has one of the extension
%   provided.
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2021 The MathWorks, Inc.
    arguments
        filename (1,1) string
        validExtension (1,:) string
    end

    [~, filePartsName, extension] = fileparts(filename);
    [~, wasNameModified] = matlab.lang.makeValidName(filePartsName);
    nameIsValid = (~wasNameModified) && any(strcmpi(extension, validExtension));
end
