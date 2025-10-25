function blkds = loadobj(S)
%loadobj   Load-from-struct for BlockedRepeatedDatastore

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.BlockedRepeatedDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > BlockedRepeatedDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    % Use a different datastore on construction to avoid reset().
    blkds = BlockedRepeatedDatastore(arrayDatastore([]), BlockSize=Inf, SizeFcn=@(~) 1);
    blkds.UnderlyingDatastore = S.UnderlyingDatastore;
end
