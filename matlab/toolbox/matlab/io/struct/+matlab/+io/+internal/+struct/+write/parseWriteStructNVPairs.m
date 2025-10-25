function [nvStruct, fileType] = parseWriteStructNVPairs(filename, varargin)
%parseWriteStructNVPairs   Parses N-V pairs shared by all writestruct file
%   formats.

%   Copyright 2023 The MathWorks, Inc.

    persistent fileTypeParser

    if isempty(fileTypeParser)
        fileTypeParser = inputParser;
        fileTypeParser.FunctionName = "writestruct";
        fileTypeParser.StructExpand = false;
        fileTypeParser.KeepUnmatched = true;
        fileTypeParser.addParameter("FileType", "auto");
    end

    fileTypeParser.parse(varargin{:});

    % Error out if we cannot detect the FileType from the file extension (when "auto").
    import matlab.io.internal.struct.write.validateFileType
    import matlab.io.internal.struct.write.detectFileType
    fileType = validateFileType(fileTypeParser.Results.FileType);
    fileType = detectFileType(filename, fileType);

    % Validate different parameters based on FileType.
    switch fileType
      case "json"
        nvStruct = matlab.io.json.internal.write.parseWriteStructNVPairs(fileTypeParser, varargin{:});
      case "xml"
        nvStruct = matlab.io.xml.internal.write.parseWriteStructNVPairs(fileTypeParser, varargin{:});
    end
end
