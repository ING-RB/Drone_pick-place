function pgds = loadobj(S)
%loadobj   Load-from-struct for PaginatedDatastore

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.PaginatedDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > PaginatedDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    % Use a different datastore on construction to avoid reset().
    pgds = PaginatedDatastore(arrayDatastore([]), ReadSize=1);
    pgds.UnderlyingDatastore = S.UnderlyingDatastore;
end
