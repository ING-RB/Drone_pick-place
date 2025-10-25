function S = saveobj(blkds)
%saveobj   Save-to-struct for BlockedRepeatedDatastore.

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = blkds.ClassVersion;

    % State properties
    S.UnderlyingDatastore = blkds.UnderlyingDatastore;
end
