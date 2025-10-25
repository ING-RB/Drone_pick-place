function S = saveobj(schds)
%saveobj   Save-to-struct for SchemaDatastore.

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = schds.ClassVersion;

    % Public properties
    S.UnderlyingDatastore = schds.UnderlyingDatastore;
    S.Schema              = schds.Schema;
end
