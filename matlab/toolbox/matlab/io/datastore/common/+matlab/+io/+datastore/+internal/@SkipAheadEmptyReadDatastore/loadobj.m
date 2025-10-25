function saerds = loadobj(S)
%loadobj   Load-from-struct for SkipAheadEmptyReadDatastore

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.SkipAheadEmptyReadDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > SkipAheadEmptyReadDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    % Construct a brand new datastore on construction to avoid reset().
    saerds = SkipAheadEmptyReadDatastore(arrayDatastore([]), EmptyFcn=S.EmptyFcn, IncludeInfo=S.IncludeInfo);
    saerds.UnderlyingDatastore = S.UnderlyingDatastore;
end
