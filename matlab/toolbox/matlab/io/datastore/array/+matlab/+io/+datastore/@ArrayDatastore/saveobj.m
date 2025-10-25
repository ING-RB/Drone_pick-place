function S = saveobj(arrds)
%

%   Copyright 2020 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = arrds.ClassVersion;

    % Public properties
    S.ReadSize = arrds.ReadSize;
    S.OutputType = arrds.OutputType;
    S.IterationDimension = arrds.IterationDimension;
    S.ConcatenationDimension = arrds.ConcatenationDimension;

    % Private properties
    S.Data = arrds.Data;
    S.NumBlocksRead = arrds.NumBlocksRead;
end
