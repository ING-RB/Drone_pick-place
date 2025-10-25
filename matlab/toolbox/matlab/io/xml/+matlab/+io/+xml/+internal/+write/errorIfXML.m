function fileType = errorIfXML(filename, supportedFileTypes, varargin)
%

%   Copyright 2020-2023 The MathWorks, Inc.

    filename = convertStringsToChars(filename);
    
    if isempty(filename) || ~ischar(filename)
        error(message('MATLAB:virtualfileio:path:cellWithEmptyStr','FILENAME'));
    end

    [~, ~, extension] = fileparts(filename);
    [fileType, supplied, ~] = matlab.internal.datatypes.parseArgs({'FileType'}, {'text'}, varargin{:});

    if supplied.FileType
        if lower(string(fileType)) == "auto"
            error(message('MATLAB:io:common:filetype:FiletypeNotDetected', supportedFileTypes));
        elseif lower(string(fileType)) == "xml"
            error(message('MATLAB:table:write:SupportedFileTypes', fileType, supportedFileTypes));
        end
    else
        if lower(string(extension)) == ".xml"
            error(message('MATLAB:io:common:filetype:FiletypeNotDetected', supportedFileTypes));
        end
    end

end
