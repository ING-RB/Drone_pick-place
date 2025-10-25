function writecell(C, filename, varargin)

import matlab.io.internal.interface.suggestWriteFunctionCorrection
import matlab.io.internal.interface.validators.validateSupportedWriteCellType
import matlab.io.internal.interface.validators.validateWriteFunctionArgumentOrder

validateSupportedWriteCellType(C);

if nargin < 2
    cellname = inputname(1);
    if isempty(cellname)
        cellname = "cell";
    end
    filename = cellname + ".txt";
else
    for i = 1:2:numel(varargin)
        n = strlength(varargin{i});
        if n > 5 && strncmpi(varargin{i},"WriteVariableNames",n)
            error(message("MATLAB:table:write:WriteVariableNamesNotSupported","WRITECELL"));
        end
        if n > 5 && strncmpi(varargin{i},"WriteRowNames",n)
            error(message("MATLAB:table:write:WriteRowNamesNotSupported","WRITECELL"));
        end
    end
end

validateWriteFunctionArgumentOrder(C, filename, "writecell", "cell", @iscell);

if ~iscell(C)
    suggestWriteFunctionCorrection(C, "writecell");
end

% Error if odd number of arguments.
if nargin > 2 && mod(nargin, 2) ~= 0
    error(message("MATLAB:table:write:NoFileNameWithParams"));
end

try
    % writecell does not support writing to XML files.
    supportedFileTypes = """text"", ""spreadsheet""";
    fileType = matlab.io.xml.internal.write.errorIfXML(filename, supportedFileTypes, varargin{:});

    T = table(C);
    writetable(T,filename,"WriteVariableNames", false, "WriteRowNames", false, varargin{:});
catch ME
    if ME.identifier == "MATLAB:table:write:UnrecognizedFileType"
        error(message("MATLAB:table:write:SupportedFileTypes", fileType, supportedFileTypes));
    else
        throw(ME);
    end
end

end

%   Copyright 2018-2024 The MathWorks, Inc.
