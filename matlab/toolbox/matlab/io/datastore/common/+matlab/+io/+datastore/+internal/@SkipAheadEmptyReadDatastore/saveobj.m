function S = saveobj(saerds)
%saveobj   Save-to-struct for SkipAheadEmptyReadDatastore.

%   Copyright 2022 The MathWorks, Inc.

% Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = saerds.ClassVersion;

    % State properties
    S.UnderlyingDatastore = saerds.UnderlyingDatastore;
    S.EmptyFcn = saerds.EmptyFcn;
    S.IncludeInfo = saerds.IncludeInfo;
end
