function writematrix(A, filename, varargin)

import matlab.internal.datatypes.isScalarText
import matlab.io.internal.interface.isSupportedWriteMatrixType
import matlab.io.internal.interface.suggestWriteFunctionCorrection
import matlab.io.internal.interface.validators.validateWriteFunctionArgumentOrder

if nargin < 2
    matrixname = inputname(1);
    if isempty(matrixname)
        matrixname = "matrix";
    end
    filename = matrixname + ".txt";
else
    for i = 1:2:numel(varargin)
        n = strlength(varargin{i});
        if n > 5 && strncmpi(varargin{i},"WriteVariableNames",n)
            error(message("MATLAB:table:write:WriteVariableNamesNotSupported","WRITEMATRIX"));
        end
        if n > 5 && strncmpi(varargin{i},"WriteRowNames",n)
            error(message("MATLAB:table:write:WriteRowNamesNotSupported","WRITEMATRIX"));
        end
    end
end

% writematrix supports writing scalar chars and strings, so we cannot
% rely only on the fact that the first argument provided is scalar text
% in order to suggest an argument reordering. We also have to be sure
% that the second argument is not scalar text and is a matrix type that is
% supported for writing.
if ~isScalarText(filename) && isSupportedWriteMatrixType(filename) && isScalarText(A)
    validateWriteFunctionArgumentOrder(A, filename, "writematrix", "matrix", @isSupportedWriteMatrixType);
end

if ~isSupportedWriteMatrixType(A)
    suggestWriteFunctionCorrection(A, "writematrix");
end

% Error if odd number of arguments.
if nargin > 2 && mod(nargin, 2) ~= 0
    error(message("MATLAB:table:write:NoFileNameWithParams"));
end

try
    % writematrix does not support writing to XML files.
    supportedFileTypes = """text"", ""spreadsheet""";
    fileType = matlab.io.xml.internal.write.errorIfXML(filename, supportedFileTypes, varargin{:});

    if ischar(A);A = string(A);end
    T = table(A);
    writetable(T,filename,varargin{:},"WriteVariableNames",false);
catch ME
    if ME.identifier == "MATLAB:table:write:UnrecognizedFileType"
        error(message("MATLAB:table:write:SupportedFileTypes", fileType, supportedFileTypes));
    else
        throw(ME);
    end
end

end

%   Copyright 2018-2024 The MathWorks, Inc.
