function S = saveobj(nds)
%saveobj   Save-to-struct for NestedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = nds.ClassVersion;

    % Public properties
    S.OuterDatastore    = nds.OuterDatastore;
    S.InnerDatastore    = nds.InnerDatastore;
    S.InnerDatastoreFcn = nds.InnerDatastoreFcn;
    S.IncludeInfo       = nds.IncludeInfo;
end
