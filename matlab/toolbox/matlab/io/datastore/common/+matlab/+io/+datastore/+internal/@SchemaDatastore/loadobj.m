function schds = loadobj(S)
%loadobj   Load-from-struct for SchemaDatastore

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.SchemaDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > SchemaDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    % Use a different datastore on construction to avoid reset().
    schds = SchemaDatastore(arrayDatastore([]), S.Schema);
    schds.UnderlyingDatastore = S.UnderlyingDatastore;
end
