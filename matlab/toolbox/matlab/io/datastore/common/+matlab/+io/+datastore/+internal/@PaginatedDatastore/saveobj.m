function S = saveobj(pgds)
%saveobj   Save-to-struct for PaginatedDatastore.

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = pgds.ClassVersion;

    % State properties
    S.UnderlyingDatastore = pgds.UnderlyingDatastore;
end
