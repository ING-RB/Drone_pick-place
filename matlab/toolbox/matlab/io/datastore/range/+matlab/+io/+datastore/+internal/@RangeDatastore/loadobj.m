function rds = loadobj(S)
%

%   Copyright 2021 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.datastore.internal.RangeDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    rds = matlab.io.datastore.internal.RangeDatastore(Start=S.Start, End=S.End, ReadSize=S.ReadSize);

    % Recover the iterator position.
    rds.NumValuesRead = S.NumValuesRead;
end
