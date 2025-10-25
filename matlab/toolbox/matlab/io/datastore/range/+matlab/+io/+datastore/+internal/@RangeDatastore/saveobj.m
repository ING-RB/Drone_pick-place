function S = saveobj(rds)
%

%   Copyright 2021 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", uint64(1));
    S.ClassVersion = rds.ClassVersion;

    % Public properties
    S.Start    = rds.Start;
    S.End      = rds.End;
    S.ReadSize = rds.ReadSize;

    % Private properties
    S.NumValuesRead = rds.NumValuesRead;
end
