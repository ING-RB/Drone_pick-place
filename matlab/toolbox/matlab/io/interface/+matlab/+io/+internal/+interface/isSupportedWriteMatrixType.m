function tf = isSupportedWriteMatrixType(data)
%ISSUPPORTEDWRITEMATRIXTYPE Determines whether the input data is supported
% for writing with WRITEMATRIX.

%   Copyright 2019-2022 The MathWorks, Inc.

dataType = string(class(data));
supportedDataTypes = ["duration", ...
                      "datetime", ...
                      "categorical", ...
                      "string", ...
                      "logical", ...
                      "char"];

tf = (isnumeric(data) || any(dataType == supportedDataTypes)) && ~issparse(data);

end
