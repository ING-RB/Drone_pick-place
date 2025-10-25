function [nvStruct, fileType] = parseWriteDictionaryNVPairs(filename, varargin)
%parseWriteDictionaryNVPairs   Parses N-V pairs shared by all writedictionary file
%   formats.

%   Copyright 2024 The MathWorks, Inc.

    persistent fileTypeParser

    if isempty(fileTypeParser)
        fileTypeParser = inputParser;
        fileTypeParser.FunctionName = "writedictionary";
        fileTypeParser.StructExpand = false;
        fileTypeParser.KeepUnmatched = true;
        fileTypeParser.addParameter("FileType", "auto");
    end

    fileTypeParser.parse(varargin{:});

    % Error out if we cannot detect the FileType from the file extension (when "auto").
    import matlab.io.internal.struct.write.validateFileType
    import matlab.io.internal.struct.write.detectFileType
    fileType = validateFileType(fileTypeParser.Results.FileType, "writedictionary");
    fileType = detectFileType(filename, fileType, "json");

    % Validate different parameters based on FileType.
    switch fileType
      case "json"
        % Reuse writestruct's N-V arg parsing.
        nvStruct = matlab.io.json.internal.write.parseWriteStructNVPairs(fileTypeParser, varargin{:});
    end
end
